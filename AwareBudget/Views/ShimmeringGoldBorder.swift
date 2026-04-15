import SwiftUI

/// Animated gold shimmer stroke. A narrow bright highlight slides around a
/// rounded rectangle's border, giving a foil / jewelry feel on white cards.
///
/// Applied via `.shimmeringGoldBorder(cornerRadius:)`. Lightweight —
/// single TimelineView, no per-frame recomputation of the underlying view.
struct ShimmeringGoldBorder: ViewModifier {
    var cornerRadius: CGFloat = 20
    var duration: Double = 3.2
    var lineWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content.overlay(
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let phase = (t.truncatingRemainder(dividingBy: duration)) / duration
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: DS.goldBase.opacity(0.35), location: 0.0),
                                .init(color: DS.goldBase.opacity(0.35), location: max(0, phase - 0.15)),
                                .init(color: Color(hex: "FFF8D0"), location: phase),
                                .init(color: DS.goldBase.opacity(0.35), location: min(1, phase + 0.15)),
                                .init(color: DS.goldBase.opacity(0.35), location: 1.0),
                            ],
                            center: .center
                        ),
                        lineWidth: lineWidth
                    )
            }
        )
    }
}

extension View {
    /// Animated gold shimmer border — use on key white cards.
    func shimmeringGoldBorder(cornerRadius: CGFloat = 20, lineWidth: CGFloat = 1) -> some View {
        modifier(ShimmeringGoldBorder(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}
