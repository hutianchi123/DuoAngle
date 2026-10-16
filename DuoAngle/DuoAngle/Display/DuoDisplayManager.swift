import SwiftUI

/// Delegates fold-aware placement to the system's arrangement layout.
/// The secondary surface is intentionally empty: the app has one readout.
enum DuoDisplayManager {
    static func present<Content: View>(@ViewBuilder primary: () -> Content) -> some View {
        ArrangementView {
            primary()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } secondary: {
            Color.clear
        }
        .arrangementViewStyle(.overlay)
    }
}
