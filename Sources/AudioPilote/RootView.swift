import SwiftUI

/// Contenu du popover : en-tête, sélecteur Entrée/Sortie, contrôle de volume,
/// liste réordonnable, section des ignorés, pied (mode auto + lancement login).
struct RootView: View {
    @EnvironmentObject var state: AppState
    @State private var ignoredExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            header
            modePicker
            controls
            DeviceListView(mode: state.selectedMode)
                .frame(minHeight: 180, maxHeight: 360)
            ignoredSection
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
            .help(L("help.contact"))
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help(L("quit"))
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var modePicker: some View {
        Picker("", selection: $state.selectedMode) {
            Label(L("tab.input"), systemImage: "mic").tag(AudioMode.input)
            Label(L("tab.output"), systemImage: "speaker.wave.2").tag(AudioMode.output)
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
                .help(state.volumeSupported ? L("volume") : L("volume.unsupported"))
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

    @ViewBuilder
    private var ignoredSection: some View {
        let rows = state.ignoredRows(for: state.selectedMode)
        if !rows.isEmpty {
            DisclosureGroup(isExpanded: $ignoredExpanded) {
                ForEach(rows) { row in
                    HStack(spacing: 8) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(row.name)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button { state.unignore(row) } label: {
                            Image(systemName: "arrow.uturn.backward").font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help(L("row.restore"))
                    }
                    .padding(.vertical, 2)
                }
            } label: {
                Text(String(format: L("ignored.count"), rows.count))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: autoIcon).foregroundColor(autoIconColor)
                Text(autoLabel).font(.system(size: 12))
                Spacer()
                Picker("", selection: Binding(get: { state.autoMode(for: state.selectedMode) },
                                              set: { state.setAutoMode($0, for: state.selectedMode) })) {
                    Text(L("auto.off")).tag(AutoSwitchMode.off)
                    Text(L("auto.fallback")).tag(AutoSwitchMode.fallback)
                    Text(L("auto.forcetop")).tag(AutoSwitchMode.forceTop)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
            }

            Toggle(isOn: Binding(get: { state.loginEnabled }, set: { state.setLogin($0) })) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                    Text(L("login.toggle")).font(.system(size: 12))
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
        }
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

    private var isDevBuild: Bool {
        !Bundle.main.bundlePath.contains("/Applications/")
    }

    private var autoLabel: String {
        let mode = state.selectedMode == .input ? L("mode.input") : L("mode.output")
        return String(format: L("auto.label"), mode)
    }

    private var autoIcon: String {
        switch state.autoMode(for: state.selectedMode) {
        case .off: return "exclamationmark.triangle.fill"
        case .fallback: return "arrow.uturn.down.circle.fill"
        case .forceTop: return "checkmark.circle.fill"
        }
    }

    private var autoIconColor: Color {
        switch state.autoMode(for: state.selectedMode) {
        case .off: return .orange
        case .fallback: return .blue
        case .forceTop: return .green
        }
    }
}
