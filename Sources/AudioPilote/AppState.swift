import Combine
import CoreAudio
import Foundation

/// État observable central de l'app.
/// Fusionne l'ordre de priorité persistant (UID) avec l'état live des
/// périphériques (online/offline), applique l'auto-switch de façon idempotente.
/// Toutes les mutations se font sur le main thread (l'UI et le listener
/// CoreAudio, qui hop sur le main, sont les seuls appelants).
final class AppState: ObservableObject {

    @Published var inputRows: [DeviceRow] = []
    @Published var outputRows: [DeviceRow] = []
    @Published var autoSwitchInput: Bool
    @Published var autoSwitchOutput: Bool
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

    init() {
        autoSwitchInput = store.autoSwitchEnabled(for: .input)
        autoSwitchOutput = store.autoSwitchEnabled(for: .output)
        loginEnabled = loginItem.isEnabled
        refresh()
        manager.startListening { [weak self] in self?.handleChange() }
        applyAutoSwitch()
    }

    func rows(for mode: AudioMode) -> [DeviceRow] {
        mode == .input ? inputRows : outputRows
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

            let defaultID = manager.defaultDeviceID(for: mode)
            let rows = order.map { uid -> DeviceRow in
                let device = liveByUID[uid]
                let isDefault = device?.objectID != nil && device?.objectID == defaultID
                return DeviceRow(uid: uid,
                                 name: device?.name ?? store.rememberedName(for: uid) ?? uid,
                                 isOnline: device != nil,
                                 isDefault: isDefault,
                                 objectID: device?.objectID,
                                 mode: mode)
            }
            if mode == .input { inputRows = rows } else { outputRows = rows }
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

    /// Bascule manuelle au clic.
    /// - auto-switch OFF : définit ce périphérique comme défaut immédiatement.
    /// - auto-switch ON : le promeut en tête de priorité, sinon l'auto-switch
    ///   reviendrait aussitôt sur le périphérique le plus prioritaire et
    ///   annulerait la sélection. Une fois en tête, l'auto-switch l'adopte.
    func makeDefault(_ row: DeviceRow) {
        guard let id = row.objectID else { return }
        if isAutoSwitch(row.mode) {
            promoteToTop(uid: row.uid, mode: row.mode)
            applyAutoSwitch(mode: row.mode)
        } else {
            manager.setDefault(id, for: row.mode)
        }
        refresh()
    }

    /// Remonte un périphérique en tête de la liste de priorité d'un mode.
    private func promoteToTop(uid: String, mode: AudioMode) {
        var rows = self.rows(for: mode)
        guard let index = rows.firstIndex(where: { $0.uid == uid }) else { return }
        let row = rows.remove(at: index)
        rows.insert(row, at: 0)
        if mode == .input { inputRows = rows } else { outputRows = rows }
        store.savePriority(rows.map { $0.uid }, for: mode)
    }

    /// Réordonne (= change la priorité) et persiste.
    func reorder(mode: AudioMode, from: IndexSet, to: Int) {
        var rows = self.rows(for: mode)
        rows.move(fromOffsets: from, toOffset: to)
        if mode == .input { inputRows = rows } else { outputRows = rows }
        store.savePriority(rows.map { $0.uid }, for: mode)
        applyAutoSwitch(mode: mode)
    }

    func isAutoSwitch(_ mode: AudioMode) -> Bool {
        mode == .input ? autoSwitchInput : autoSwitchOutput
    }

    func setAutoSwitch(_ enabled: Bool, for mode: AudioMode) {
        if mode == .input { autoSwitchInput = enabled } else { autoSwitchOutput = enabled }
        store.setAutoSwitchEnabled(enabled, for: mode)
        applyAutoSwitch(mode: mode)
    }

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

    /// Démarre/arrête le test de niveau d'une entrée (déclenché par le bouton).
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

    // MARK: - Auto-switch (idempotent)

    /// Force, pour chaque mode concerné, le périphérique disponible le plus haut
    /// dans la liste de priorité. N'écrit que si le défaut courant diffère de la
    /// cible : évite la boucle de feedback avec le listener.
    private func applyAutoSwitch(mode: AudioMode? = nil) {
        let modes = mode.map { [$0] } ?? AudioMode.allCases
        var changed = false
        for m in modes where isAutoSwitch(m) {
            guard let target = rows(for: m).first(where: { $0.isOnline })?.objectID else { continue }
            if manager.defaultDeviceID(for: m) != target {
                manager.setDefault(target, for: m)
                changed = true
            }
        }
        if changed { refresh() }
    }
}
