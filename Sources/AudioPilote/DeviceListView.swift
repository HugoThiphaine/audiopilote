import SwiftUI

/// Liste réordonnable des périphériques d'un mode.
/// Glisser une ligne = changer sa priorité. Cliquer une ligne en ligne = la
/// définir par défaut.
struct DeviceListView: View {
    @EnvironmentObject var state: AppState
    let mode: AudioMode

    var body: some View {
        List {
            ForEach(state.rows(for: mode)) { row in
                DeviceRowView(row: row)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if row.isOnline { state.makeDefault(row) }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            .onMove { indices, newOffset in
                state.reorder(mode: mode, from: indices, to: newOffset)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .id(mode)
    }
}
