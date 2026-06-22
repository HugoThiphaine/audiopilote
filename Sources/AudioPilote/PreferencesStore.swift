import Foundation

/// Persistance des préférences dans UserDefaults.
/// - ordre de priorité par mode : tableau d'UID (clé stable, pas l'AudioObjectID)
/// - noms mémorisés : pour afficher un périphérique hors-ligne avec son nom
/// - état de l'auto-switch
final class PreferencesStore {

    private let defaults = UserDefaults.standard

    private func priorityKey(_ mode: AudioMode) -> String { "priority.\(mode.rawValue)" }
    private let namesKey = "device.names"

    // MARK: - Ordre de priorité

    func priority(for mode: AudioMode) -> [String] {
        defaults.stringArray(forKey: priorityKey(mode)) ?? []
    }

    func savePriority(_ uids: [String], for mode: AudioMode) {
        defaults.set(uids, forKey: priorityKey(mode))
    }

    // MARK: - Noms mémorisés

    private var names: [String: String] {
        get { defaults.dictionary(forKey: namesKey) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: namesKey) }
    }

    func rememberName(_ name: String, for uid: String) {
        var current = names
        guard current[uid] != name else { return }
        current[uid] = name
        names = current
    }

    func rememberedName(for uid: String) -> String? { names[uid] }

    // MARK: - Mode de bascule auto (par mode audio)

    func autoMode(for mode: AudioMode) -> AutoSwitchMode {
        if let raw = defaults.string(forKey: "autoMode.\(mode.rawValue)"),
           let value = AutoSwitchMode(rawValue: raw) {
            return value
        }
        // Migration de l'ancien réglage booléen (true = forcer le plus prioritaire).
        if defaults.bool(forKey: "autoSwitch.\(mode.rawValue)") { return .forceTop }
        return .off
    }

    func setAutoMode(_ value: AutoSwitchMode, for mode: AudioMode) {
        defaults.set(value.rawValue, forKey: "autoMode.\(mode.rawValue)")
    }

    // MARK: - Périphériques ignorés (par mode)

    func ignoredUIDs(for mode: AudioMode) -> Set<String> {
        Set(defaults.stringArray(forKey: "ignored.\(mode.rawValue)") ?? [])
    }

    func setIgnoredUIDs(_ uids: Set<String>, for mode: AudioMode) {
        defaults.set(Array(uids), forKey: "ignored.\(mode.rawValue)")
    }
}
