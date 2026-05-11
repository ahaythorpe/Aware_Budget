import SwiftUI

/// Gold border for white cards.
///
/// **Static by default (2026-05-10).** Tester feedback: animated
/// shimmer borders looping on every card competed with content and made
/// the UI feel busy. Now renders as a single fixed gold stroke. Use
/// `.animatedShimmerBorder()` explicitly if you want the old looping
/// animation back (reserved for one primary card per screen).
///
/// Both variants respect iOS **Reduce Motion**.
struct ShimmeringGoldBorder: ViewModifier {
    var cornerRadius: CGFloat = 20
    var lineWidth: CGFloat = 1.75

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(DS.goldBase.opacity(0.5), lineWidth: lineWidth)
        )
    }
}

/// Animated variant — looping bright highlight slides around the border.
/// Reserve for ONE primary card per screen. Halts on Reduce Motion.
struct AnimatedShimmeringGoldBorder: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var cornerRadius: CGFloat = 20
    var duration: Double = 3.2
    var lineWidth: CGFloat = 1.75

    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if reduceMotion {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(DS.goldBase.opacity(0.6), lineWidth: lineWidth)
                } else {
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
                }
            }
        )
    }
}

extension View {
    /// Static gold border for white cards. (Default behaviour as of
    /// 2026-05-10 — was previously animated; see ShimmeringGoldBorder.swift
    /// header for context.)
    func shimmeringGoldBorder(cornerRadius: CGFloat = 20, lineWidth: CGFloat = 1.75) -> some View {
        modifier(ShimmeringGoldBorder(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }

    /// Looping animated gold border. Use sparingly — one primary card
    /// per screen at most. Halts on Reduce Motion.
    func animatedShimmerBorder(cornerRadius: CGFloat = 20, lineWidth: CGFloat = 1.75) -> some View {
        modifier(AnimatedShimmeringGoldBorder(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}
