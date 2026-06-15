import AppKit

// Chemin de debug : `AudioPilote --list` valide l'énumération CoreAudio sans
// lancer l'interface (utile pour tester la couche HAL en ligne de commande).
if CommandLine.arguments.contains("--list") {
    let manager = AudioDeviceManager()
    for mode in AudioMode.allCases {
        let defaultID = manager.defaultDeviceID(for: mode)
        let vol = manager.volume(of: defaultID, mode: mode).map { String(format: "%.0f%%", $0 * 100) } ?? "n/a"
        print("== \(mode.rawValue.uppercased()) (défaut: \(defaultID), volume: \(vol)) ==")
        for device in manager.devices(for: mode) {
            let marker = device.objectID == defaultID ? "★" : " "
            print("  \(marker) [\(device.objectID ?? 0)] \(device.name)  —  uid=\(device.uid)")
        }
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
