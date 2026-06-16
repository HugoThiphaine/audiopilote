import SwiftUI

/// Cellule d'un périphérique : pastille (clic = définir par défaut), nom,
/// (entrée) bouton mètre, bouton « remonter en tête ».
/// Grisé si hors-ligne, pastille accentuée + coche si c'est le défaut courant.
struct DeviceRowView: View {
    let row: DeviceRow
    var isMetered: Bool = false
    var level: Float = 0
    var onToggleMeter: (() -> Void)? = nil
    var onActivate: (() -> Void)? = nil
    var onMoveToTop: (() -> Void)? = nil

    @State private var isHovering = false

    private var showMeterButton: Bool {
        row.mode == .input && row.isOnline && onToggleMeter != nil
    }

    var body: some View {
        HStack(spacing: 10) {
            if let onActivate {
                Button(action: onActivate) { pastille }
                    .buttonStyle(.plain)
                    .help(L("row.setdefault"))
            } else {
                pastille
            }

            Text(row.name)
                .font(.system(size: 13))
                .fontWeight(row.isDefault ? .semibold : .regular)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)

            if isMetered {
                InputMeterView(level: level)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer(minLength: 4)
            }

            if showMeterButton {
                Button(action: { onToggleMeter?() }) {
                    Image(systemName: isMetered ? "waveform.circle.fill" : "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(isMetered ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(isMetered ? L("meter.stop") : L("meter.start"))
            }

            Button(action: { onMoveToTop?() }) {
                Image(systemName: "arrow.up.to.line")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L("row.movetotop"))
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
            .animation(.easeInOut(duration: 0.12), value: isHovering)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(row.isDefault ? Color.accentColor.opacity(0.14) : Color.clear)
        )
        .opacity(row.isOnline ? 1 : 0.45)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    private var pastille: some View {
        ZStack {
            Circle()
                .fill(row.isDefault ? Color.accentColor : Color.secondary.opacity(0.18))
                .frame(width: 26, height: 26)
            Image(systemName: row.isDefault ? "checkmark" : symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(row.isDefault ? .white : .secondary)
        }
    }

    private var symbol: String {
        row.mode == .input ? "mic" : "speaker.wave.2"
    }
}
