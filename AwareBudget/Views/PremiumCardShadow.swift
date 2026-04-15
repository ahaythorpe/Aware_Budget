import SwiftUI

/// Consistent soft shadow for all primary white cards on the app.
/// Handbook §3.5 F7 — one shadow, applied everywhere, never ad-hoc.
///
/// Use `.premiumCardShadow()` on any view that sits on `DS.bg` and
/// carries real content (greeting, calendar, Top Biases, Nudge Says,
/// comparison cards, bias rows, etc).
extension View {
    func premiumCardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
