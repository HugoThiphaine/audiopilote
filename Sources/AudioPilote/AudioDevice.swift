import CoreAudio

/// Entrée ou sortie. Porte les constantes CoreAudio qui dépendent du mode.
enum AudioMode: String, Codable, CaseIterable {
    case input
    case output

    /// Scope HAL pour compter les canaux et filtrer les périphériques.
    var scope: AudioObjectPropertyScope {
        self == .input ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput
    }

    /// Sélecteur du périphérique par défaut système pour ce mode.
    var defaultSelector: AudioObjectPropertySelector {
        self == .input ? kAudioHardwarePropertyDefaultInputDevice
                       : kAudioHardwarePropertyDefaultOutputDevice
    }
}

/// Comportement de la bascule automatique, indépendant pour chaque mode.
enum AutoSwitchMode: String, Codable, CaseIterable {
    case off        // ne rien faire automatiquement
    case fallback   // basculer seulement si l'actif se déconnecte (sans voler le focus)
    case forceTop   // imposer en continu le plus prioritaire disponible
}

/// Périphérique audio tel que retourné par CoreAudio à un instant T.
/// `uid` est la clé stable de persistance ; `objectID` est volatile (recalculé
/// à chaque énumération, change après un rebranchement).
struct AudioDevice: Identifiable, Equatable {
    let uid: String
    var name: String
    var objectID: AudioObjectID?

    var id: String { uid }
    var isOnline: Bool { objectID != nil }
}

/// Ligne affichée dans l'UI : fusion de l'ordre persistant et de l'état live.
struct DeviceRow: Identifiable, Equatable {
    let uid: String
    let name: String
    let isOnline: Bool
    let isDefault: Bool
    let objectID: AudioObjectID?
    let mode: AudioMode

    var id: String { uid }
}
