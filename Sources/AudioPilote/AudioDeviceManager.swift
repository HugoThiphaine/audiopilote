import CoreAudio
import Foundation

/// Couche CoreAudio (HAL) pure, sans dépendance UI.
/// Énumère les périphériques, lit/écrit le défaut, écoute les changements.
final class AudioDeviceManager {

    private let systemObject = AudioObjectID(kAudioObjectSystemObject)
    private let listenerQueue = DispatchQueue(label: "fr.thiphaine.audiopilote.coreaudio")
    private var listeners: [(AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []

    // MARK: - Helper d'adresse

    private func address(_ selector: AudioObjectPropertySelector,
                         _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal)
        -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector,
                                   mScope: scope,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    // MARK: - Énumération

    private func allDeviceIDs() -> [AudioObjectID] {
        var addr = address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(systemObject, &addr, 0, nil, &size) == noErr,
              size > 0 else { return [] }
        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var ids = [AudioObjectID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(systemObject, &addr, 0, nil, &size, &ids) == noErr
        else { return [] }
        return ids
    }

    /// Nombre de canaux du périphérique dans le scope donné (0 = pas concerné).
    private func channelCount(_ device: AudioObjectID, scope: AudioObjectPropertyScope) -> Int {
        var addr = address(kAudioDevicePropertyStreamConfiguration, scope)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &addr, 0, nil, &size) == noErr,
              size > 0 else { return 0 }
        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { buffer.deallocate() }
        guard AudioObjectGetPropertyData(device, &addr, 0, nil, &size, buffer) == noErr
        else { return 0 }
        let list = UnsafeMutableAudioBufferListPointer(
            buffer.assumingMemoryBound(to: AudioBufferList.self))
        return list.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    /// Lecture d'une propriété CFString (nom, UID). La HAL renvoie un objet
    /// retenu (+1) ; le `CFString?` Swift le relâche en sortie de scope, donc
    /// le compte est équilibré.
    private func stringProperty(_ device: AudioObjectID,
                                _ selector: AudioObjectPropertySelector) -> String? {
        var addr = address(selector)
        var size = UInt32(MemoryLayout<CFString?>.size)
        var value: CFString?
        let status = withUnsafeMutablePointer(to: &value) {
            AudioObjectGetPropertyData(device, &addr, 0, nil, &size, $0)
        }
        guard status == noErr, let string = value else { return nil }
        return string as String
    }

    func name(of device: AudioObjectID) -> String? {
        stringProperty(device, kAudioObjectPropertyName)
    }

    func uid(of device: AudioObjectID) -> String? {
        stringProperty(device, kAudioDevicePropertyDeviceUID)
    }

    /// Périphériques live du mode demandé (filtrés par nombre de canaux > 0).
    func devices(for mode: AudioMode) -> [AudioDevice] {
        allDeviceIDs().compactMap { id -> AudioDevice? in
            guard channelCount(id, scope: mode.scope) > 0 else { return nil }
            guard let uid = uid(of: id) else { return nil }
            return AudioDevice(uid: uid, name: name(of: id) ?? uid, objectID: id)
        }
    }

    // MARK: - Périphérique par défaut

    func defaultDeviceID(for mode: AudioMode) -> AudioObjectID {
        var addr = address(mode.defaultSelector)
        var device = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(systemObject, &addr, 0, nil, &size, &device)
        return device
    }

    @discardableResult
    func setDefault(_ device: AudioObjectID, for mode: AudioMode) -> Bool {
        var addr = address(mode.defaultSelector)
        var value = device
        let size = UInt32(MemoryLayout<AudioObjectID>.size)
        return AudioObjectSetPropertyData(systemObject, &addr, 0, nil, size, &value) == noErr
    }

    // MARK: - Écoute des changements

    func startListening(onChange: @escaping () -> Void) {
        let selectors: [AudioObjectPropertySelector] = [
            kAudioHardwarePropertyDevices,
            kAudioHardwarePropertyDefaultInputDevice,
            kAudioHardwarePropertyDefaultOutputDevice
        ]
        for selector in selectors {
            var addr = address(selector)
            let block: AudioObjectPropertyListenerBlock = { _, _ in
                DispatchQueue.main.async { onChange() }
            }
            if AudioObjectAddPropertyListenerBlock(systemObject, &addr, listenerQueue, block) == noErr {
                listeners.append((addr, block))
            }
        }
    }

    func stopListening() {
        for (address, block) in listeners {
            var addr = address
            AudioObjectRemovePropertyListenerBlock(systemObject, &addr, listenerQueue, block)
        }
        listeners.removeAll()
    }
}
