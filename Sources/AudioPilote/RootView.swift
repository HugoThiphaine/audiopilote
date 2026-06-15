import SwiftUI

/// Contenu du popover : en-tête, sélecteur Entrée/Sortie, liste, pied avec les
/// deux toggles (auto-switch + lancement au login).
struct RootView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            modePicker
            controls
            DeviceListView(mode: state.selectedMode)
                .frame(minHeight: 180, maxHeight: 360)
            footer
        }
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.accentColor)
            Text("AudioPilote").font(.headline)
            if isDevBuild {
                Text("dev")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.orange.opacity(0.25)))
                    .foregroundColor(.orange)
            }
            Spacer()
            Link(destination: URL(string: "https://hugo-thiphaine.fr")!) {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Aide et contact : hugo-thiphaine.fr")
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Quitter AudioPilote")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var modePicker: some View {
        Picker("", selection: $state.selectedMode) {
            Label("Entrée", systemImage: "mic").tag(AudioMode.input)
            Label("Sortie", systemImage: "speaker.wave.2").tag(AudioMode.output)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Image(systemName: state.selectedMode == .input ? "mic.fill" : "speaker.wave.2.fill")
                .foregroundColor(.secondary)
                .frame(width: 16)
            Slider(value: Binding(get: { state.volume }, set: { state.setVolume($0) }), in: 0...1)
                .disabled(!state.volumeSupported)
                .help(state.volumeSupported ? "Volume" : "Volume non réglable pour ce périphérique")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 2)
        .padding(.bottom, 8)
    }

    private var isDevBuild: Bool {
        !Bundle.main.bundlePath.contains("/Applications/")
    }

    private var autoSwitchLabel: String {
        let mode = state.selectedMode == .input ? "entrée" : "sortie"
        return state.isAutoSwitch(state.selectedMode)
            ? "Changement auto activé (\(mode))"
            : "Changement auto désactivé (\(mode))"
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(get: { state.isAutoSwitch(state.selectedMode) },
                                 set: { state.setAutoSwitch($0, for: state.selectedMode) })) {
                HStack(spacing: 6) {
                    Image(systemName: state.isAutoSwitch(state.selectedMode)
                          ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(state.isAutoSwitch(state.selectedMode) ? .green : .orange)
                    Text(autoSwitchLabel)
                        .font(.system(size: 12))
                }
            }

            Toggle(isOn: Binding(get: { state.loginEnabled },
                                 set: { state.setLogin($0) })) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                    Text("Lancer au démarrage").font(.system(size: 12))
                }
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
