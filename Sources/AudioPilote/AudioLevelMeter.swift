import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation

/// Mesure le niveau d'entrée en temps réel via AVAudioEngine.
/// Ne tourne que lorsqu'on le démarre (popover ouvert + onglet Entrée), pour
/// rester léger : aucun coût quand il est arrêté.
final class AudioLevelMeter {

    private let engine = AVAudioEngine()
    private var running = false
    private var displayTimer: Timer?
    private var targetLevel: Float = 0   // dernier niveau mesuré (maj sur le main)
    private var shownLevel: Float = 0    // niveau lissé affiché
    private var onLevel: ((Float) -> Void)?

    /// Démarre la mesure du périphérique donné, si la permission micro est ok.
    func start(deviceID: AudioObjectID, onLevel: @escaping (Float) -> Void) {
        guard !running else { return }
        self.onLevel = onLevel
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            begin(deviceID: deviceID)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.begin(deviceID: deviceID) }
            }
        default:
            break   // refusé ou restreint : pas de mètre
        }
    }

    func stop() {
        guard running else { return }
        displayTimer?.invalidate()
        displayTimer = nil
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        running = false
        targetLevel = 0
        shownLevel = 0
        onLevel = nil
    }

    private func begin(deviceID: AudioObjectID) {
        guard !running else { return }
        // Cible le périphérique demandé sur l'unité d'entrée (AUHAL).
        if deviceID != 0, let unit = engine.inputNode.audioUnit {
            var dev = deviceID
            AudioUnitSetProperty(unit,
                                 kAudioOutputUnitProperty_CurrentDevice,
                                 kAudioUnitScope_Global,
                                 0,
                                 &dev,
                                 UInt32(MemoryLayout<AudioDeviceID>.size))
        }
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }   // pas d'entrée valide
        input.installTap(onBus: 0, bufferSize: 512, format: format) { [weak self] buffer, _ in
            let level = AudioLevelMeter.level(from: buffer)
            DispatchQueue.main.async { self?.targetLevel = level }
        }
        do {
            try engine.start()
            running = true
            startDisplayTimer()
        } catch {
            NSLog("AudioPilote: démarrage du mètre impossible : \(error.localizedDescription)")
        }
    }

    /// Affichage ~60 fps : attaque immédiate, relâche douce, pour un mouvement
    /// fluide indépendant de la cadence des buffers audio.
    private func startDisplayTimer() {
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.targetLevel >= self.shownLevel {
                self.shownLevel = self.targetLevel
            } else {
                self.shownLevel += (self.targetLevel - self.shownLevel) * 0.2
            }
            self.onLevel?(self.shownLevel)
        }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
    }

    /// Niveau normalisé 0..1 à partir du RMS converti en dB (-60 dB .. 0 dB).
    private static func level(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { return 0 }
        let frames = Int(buffer.frameLength)
        let samples = channels[0]
        var sum: Float = 0
        for i in 0..<frames {
            let s = samples[i]
            sum += s * s
        }
        let rms = sqrt(sum / Float(frames))
        let db = 20 * log10(max(rms, 1e-7))
        return max(0, min(1, (db + 60) / 60))
    }
}
