import SwiftUI

/// Cellule d'un périphérique : pastille + nom + poignée de réordonnancement.
/// Grisé si hors-ligne, pastille accentuée + coche si c'est le défaut courant.
struct DeviceRowView: View {
    let row: DeviceRow

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(row.isDefault ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: 26, height: 26)
                Image(systemName: row.isDefault ? "checkmark" : symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(row.isDefault ? .white : .secondary)
            }

            Text(row.name)
                .font(.system(size: 13))
                .fontWeight(row.isDefault ? .semibold : .regular)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 3)
        .opacity(row.isOnline ? 1 : 0.45)
        .help(row.isOnline ? "Cliquer pour définir par défaut" : "Hors-ligne")
    }

    private var symbol: String {
        row.mode == .input ? "mic" : "speaker.wave.2"
    }
}
