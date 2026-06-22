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
                DeviceRowView(row: row,
                              isMetered: state.meteredUID == row.uid,
                              level: state.inputLevel,
                              onToggleMeter: (mode == .input && row.isOnline)
                                  ? { state.toggleMeter(row) } : nil,
                              onActivate: row.isOnline ? { state.makeDefault(row) } : nil,
                              onMoveToTop: { state.moveToTop(row) },
                              onIgnore: { state.ignore(row) })
                    .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
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
