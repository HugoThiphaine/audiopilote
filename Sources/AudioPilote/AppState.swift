import Combine
import CoreAudio
import Foundation

/// État observable central de l'app.
/// Fusionne l'ordre de priorité persistant (UID) avec l'état live des
/// périphériques (online/offline) et applique la bascule automatique.
/// Toutes les mutations se font sur le main thread (l'UI et le listener
/// CoreAudio, qui hop sur le main, sont les seuls appelants).
final class AppState: ObservableObject {

    @Published var inputRows: [DeviceRow] = []
    @Published var outputRows: [DeviceRow] = []
    @Published var ignoredInput: [DeviceRow] = []
    @Published var ignoredOutput: [DeviceRow] = []
    @Published var autoModeInput: AutoSwitchMode
    @Published var autoModeOutput: AutoSwitchMode
    @Published var loginEnabled: Bool
    @Published var selectedMode: AudioMode = .output {
        didSet {
            refreshVolume()
            updateMeter()
        }
    }
    @Published var volume: Float = 0
    @Published var volumeSupported: Bool = false
    @Published var inputLevel: Float = 0
    @Published var meteredUID: String?

    private let manager = AudioDeviceManager()
    private let store = PreferencesStore()
    private let loginItem = LoginItemManager()
    private let meter = AudioLevelMeter()
    private var popoverVisible = false
    /// Périphérique que l'app considère actif (managé) par mode, pour le repli.
    private var activeUID: [AudioMode: String] = [:]

    init() {
        autoModeInput = store.autoMode(for: .input)
        autoModeOutput = store.autoMode(for: .output)
        loginEnabled = loginItem.isEnabled
        refresh()
        manager.startListening { [weak self] in self?.handleChange() }
        applyAutoSwitch()
    }

    func rows(for mode: AudioMode) -> [DeviceRow] {
        mode == .input ? inputRows : outputRows
    }

    func ignoredRows(for mode: AudioMode) -> [DeviceRow] {
        mode == .input ? ignoredInput : ignoredOutput
    }

    // MARK: - Synchronisation de l'état

    /// Recalcule les listes à partir de l'ordre persistant + des devices live.
    func refresh() {
        for mode in AudioMode.allCases {
            let live = manager.devices(for: mode)
            let liveByUID = Dictionary(live.map { ($0.uid, $0) }, uniquingKeysWith: { a, _ in a })
            live.forEach { store.rememberName($0.name, for: $0.uid) }

            var order = store.priority(for: mode)
            for device in live where !order.contains(device.uid) { order.append(device.uid) }
            // En ligne : on garde. Hors-ligne : seulement si on a un nom propre
            // (ni vide, ni l'UID brut, ni un agrégat), pour éviter le bruit.
            order = order.filter { uid in
                if liveByUID[uid] != nil { return true }
                return AppState.isPresentableOffline(store.rememberedName(for: uid), uid: uid)
            }
            store.savePriority(order, for: mode)

            let ignored = store.ignoredUIDs(for: mode)
            let defaultID = manager.defaultDeviceID(for: mode)
            let allRows = order.map { uid -> DeviceRow in
                let device = liveByUID[uid]
                let isDefault = device?.objectID != nil && device?.objectID == defaultID
                return DeviceRow(uid: uid,
                                 name: device?.name ?? store.rememberedName(for: uid) ?? uid,
                                 isOnline: device != nil,
                                 isDefault: isDefault,
                                 objectID: device?.objectID,
                                 mode: mode)
            }
            let main = allRows.filter { !ignored.contains($0.uid) }
            let ign = allRows.filter { ignored.contains($0.uid) }
            if mode == .input { inputRows = main; ignoredInput = ign }
            else { outputRows = main; ignoredOutput = ign }
        }
        if let uid = meteredUID, inputRows.first(where: { $0.uid == uid })?.isOnline != true {
            meteredUID = nil
        }
        refreshVolume()
    }

    /// Un périphérique hors-ligne est présentable s'il a un vrai nom mémorisé
    /// (ni vide, ni l'UID brut, ni un agrégat système temporaire).
    private static func isPresentableOffline(_ name: String?, uid: String) -> Bool {
        guard let name, !name.isEmpty, name != uid else { return false }
        if name.hasPrefix("CADefaultDeviceAggregate") { return false }
        return true
    }

    private func handleChange() {
        refresh()
        applyAutoSwitch()
        updateMeter()
    }

    // MARK: - Actions UI

    /// Bascule manuelle au clic sur la pastille.
    /// - forceTop : promeut en tête (sinon l'auto reviendrait sur le top).
    /// - off / fallback : définit ce périphérique comme défaut et actif.
    func makeDefault(_ row: DeviceRow) {
        guard let id = row.objectID else { return }
        switch autoMode(for: row.mode) {
        case .forceTop:
            promoteToTop(uid: row.uid, mode: row.mode)
            applyAutoSwitch(mode: row.mode)
        case .off, .fallback:
            manager.setDefault(id, for: row.mode)
            activeUID[row.mode] = row.uid
        }
        refresh()
    }

    /// Remonte un périphérique en tête de la priorité (bouton « remonter »).
    func moveToTop(_ row: DeviceRow) {
        promoteToTop(uid: row.uid, mode: row.mode)
        applyAutoSwitch(mode: row.mode)
        refresh()
    }

    /// Remonte un UID en tête de la liste active et persiste (ignorés conservés).
    private func promoteToTop(uid: String, mode: AudioMode) {
        var rows = self.rows(for: mode)
        guard let index = rows.firstIndex(where: { $0.uid == uid }) else { return }
        let row = rows.remove(at: index)
        rows.insert(row, at: 0)
        if mode == .input { inputRows = rows } else { outputRows = rows }
        persistOrder(mainRows: rows, mode: mode)
    }

    /// Réordonne (= change la priorité) et persiste.
    func reorder(mode: AudioMode, from: IndexSet, to: Int) {
        var rows = self.rows(for: mode)
        rows.move(fromOffsets: from, toOffset: to)
        if mode == .input { inputRows = rows } else { outputRows = rows }
        persistOrder(mainRows: rows, mode: mode)
        applyAutoSwitch(mode: mode)
    }

    /// Sauvegarde l'ordre = UID actifs puis UID ignorés (pour ne pas les perdre).
    private func persistOrder(mainRows: [DeviceRow], mode: AudioMode) {
        let mainUIDs = mainRows.map { $0.uid }
        let ignoredUIDs = ignoredRows(for: mode).map { $0.uid }.filter { !mainUIDs.contains($0) }
        store.savePriority(mainUIDs + ignoredUIDs, for: mode)
    }

    // MARK: - Mode de bascule auto

    func autoMode(for mode: AudioMode) -> AutoSwitchMode {
        mode == .input ? autoModeInput : autoModeOutput
    }

    func setAutoMode(_ value: AutoSwitchMode, for mode: AudioMode) {
        if mode == .input { autoModeInput = value } else { autoModeOutput = value }
        store.setAutoMode(value, for: mode)
        activeUID[mode] = nil   // repart de l'état courant (pas de vol immédiat en repli)
        applyAutoSwitch(mode: mode)
    }

    // MARK: - Ignorer / restaurer

    func ignore(_ row: DeviceRow) {
        var set = store.ignoredUIDs(for: row.mode)
        set.insert(row.uid)
        store.setIgnoredUIDs(set, for: row.mode)
        if activeUID[row.mode] == row.uid { activeUID[row.mode] = nil }
        refresh()
        applyAutoSwitch(mode: row.mode)
    }

    func unignore(_ row: DeviceRow) {
        var set = store.ignoredUIDs(for: row.mode)
        set.remove(row.uid)
        store.setIgnoredUIDs(set, for: row.mode)
        refresh()
        applyAutoSwitch(mode: row.mode)
    }

    // MARK: - Login

    func setLogin(_ enabled: Bool) {
        loginItem.setEnabled(enabled)
        loginEnabled = loginItem.isEnabled
    }

    func refreshLoginStatus() {
        loginEnabled = loginItem.isEnabled
    }

    // MARK: - Volume

    private func refreshVolume() {
        let device = manager.defaultDeviceID(for: selectedMode)
        if let level = manager.volume(of: device, mode: selectedMode) {
            volume = level
            volumeSupported = true
        } else {
            volume = 0
            volumeSupported = false
        }
    }

    func setVolume(_ value: Float) {
        let device = manager.defaultDeviceID(for: selectedMode)
        if manager.setVolume(value, of: device, mode: selectedMode) {
            volume = value
        }
    }

    // MARK: - VU-mètre d'entrée

    func setPopoverVisible(_ visible: Bool) {
        popoverVisible = visible
        if !visible { meteredUID = nil }
        updateMeter()
    }

    func toggleMeter(_ row: DeviceRow) {
        meteredUID = (meteredUID == row.uid) ? nil : row.uid
        updateMeter()
    }

    private func updateMeter() {
        meter.stop()
        inputLevel = 0
        guard popoverVisible,
              selectedMode == .input,
              let uid = meteredUID,
              let row = inputRows.first(where: { $0.uid == uid }),
              row.isOnline,
              let deviceID = row.objectID else {
            return
        }
        meter.start(deviceID: deviceID) { [weak self] level in self?.inputLevel = level }
    }

    // MARK: - Bascule automatique

    /// Applique la bascule pour les modes concernés selon leur AutoSwitchMode.
    /// `forceTop` impose en continu le plus prioritaire ; `fallback` ne bascule
    /// que si l'actif a disparu, sans voler le focus à un device qui (re)connecte.
    private func applyAutoSwitch(mode: AudioMode? = nil) {
        let modes = mode.map { [$0] } ?? AudioMode.allCases
        var changed = false
        for m in modes {
            let auto = autoMode(for: m)
            guard auto != .off else { continue }
            let rows = self.rows(for: m)
            guard let topOnline = rows.first(where: { $0.isOnline }),
                  let topID = topOnline.objectID else { continue }
            let sysDefault = manager.defaultDeviceID(for: m)

            switch auto {
            case .off:
                break
            case .forceTop:
                if sysDefault != topID {
                    manager.setDefault(topID, for: m)
                    changed = true
                }
                activeUID[m] = topOnline.uid
            case .fallback:
                let activeOnline = activeUID[m].flatMap { uid in
                    rows.first(where: { $0.uid == uid && $0.isOnline })
                }
                if let activeOnline {
                    // L'actif est toujours là : on respecte, on adopte un éventuel
                    // changement manuel vers un autre périphérique en ligne.
                    if let sysRow = rows.first(where: { $0.objectID == sysDefault && $0.isOnline }),
                       sysRow.uid != activeOnline.uid {
                        activeUID[m] = sysRow.uid
                    }
                } else if activeUID[m] == nil {
                    // Première fois : adopter le défaut courant s'il est des nôtres,
                    // sinon se poser sur le plus prioritaire disponible.
                    if let sysRow = rows.first(where: { $0.objectID == sysDefault && $0.isOnline }) {
                        activeUID[m] = sysRow.uid
                    } else {
                        manager.setDefault(topID, for: m)
                        activeUID[m] = topOnline.uid
                        changed = true
                    }
                } else {
                    // L'actif s'est déconnecté : repli sur le plus prioritaire dispo.
                    manager.setDefault(topID, for: m)
                    activeUID[m] = topOnline.uid
                    changed = true
                }
            }
        }
        if changed { refresh() }
    }
}
