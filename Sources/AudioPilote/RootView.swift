import SwiftUI

/// Contenu du popover : en-tête, sélecteur Entrée/Sortie, liste, pied avec les
/// deux toggles (auto-switch + lancement au login).
struct RootView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            modePicker
            Divider()
            DeviceListView(mode: state.selectedMode)
                .frame(minHeight: 180, maxHeight: 360)
            Divider()
            footer
        }
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.accentColor)
            Text("AudioPilote").font(.headline)
            Spacer()
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
