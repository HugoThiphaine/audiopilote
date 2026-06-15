import AppKit
import ServiceManagement

/// Lancement au login via SMAppService (macOS 13+).
/// Sensible au chemin et à la signature : après un rebuild, la CDHash change
/// et l'item peut être invalidé. L'UI doit refléter `status` réel et permettre
/// de réactiver.
final class LoginItemManager {

    var status: SMAppService.Status { SMAppService.mainApp.status }

    var isEnabled: Bool { status == .enabled }

    /// Active ou désactive l'item. Ouvre les Réglages Système si le système
    /// exige une approbation manuelle.
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("AudioPilote: erreur login item : \(error.localizedDescription)")
        }

        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
