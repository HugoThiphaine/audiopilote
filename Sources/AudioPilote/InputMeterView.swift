import SwiftUI

/// Barre de niveau d'entrée en temps réel (VU-mètre simplifié).
struct InputMeterView: View {
    let level: Float   // 0..1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                Capsule()
                    .fill(color)
                    .frame(width: max(2, geo.size.width * CGFloat(min(1, max(0, level)))))
            }
        }
        .frame(height: 6)
        .animation(.linear(duration: 0.05), value: level)
    }

    private var color: Color {
        switch level {
        case ..<0.6: return .green
        case ..<0.85: return .yellow
        default: return .red
        }
    }
}
