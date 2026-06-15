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

    // MARK: - Auto-switch (par mode)

    func autoSwitchEnabled(for mode: AudioMode) -> Bool {
        defaults.bool(forKey: "autoSwitch.\(mode.rawValue)")
    }

    func setAutoSwitchEnabled(_ enabled: Bool, for mode: AudioMode) {
        defaults.set(enabled, forKey: "autoSwitch.\(mode.rawValue)")
    }
}
