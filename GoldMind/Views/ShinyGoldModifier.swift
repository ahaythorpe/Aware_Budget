import SwiftUI

/// Native SwiftUI shimmer — a narrow diagonal highlight stripe that slides
/// across the modified view on a loop. Applied on top of gold surfaces to
/// give the metallic foil a "catching the light" feel without a package.
///
/// Respects iOS **Reduce Motion** accessibility setting — when enabled, the
/// animation halts at a fixed phase so the surface still looks "dimensional"
/// without any movement. Required for App Store accessibility compliance.
///
/// Usage: `.shimmerOverlay()` — applies to anything. Tester feedback flagged
/// over-use; reserve for the single primary CTA per screen.
struct ShinyGoldModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var duration: Double = 2.6
    var intensity: Double = 0.35

    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if reduceMotion {
                    GeometryReader { geo in
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0), location: 0.0),
                                .init(color: .white.opacity(0), location: 0.40),
                                .init(color: .white.opacity(intensity * 0.6), location: 0.50),
                                .init(color: .white.opacity(0), location: 0.60),
                                .init(color: .white.opacity(0), location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width)
                        .blendMode(.screen)
                    }
                    .allowsHitTesting(false)
                } else {
                    TimelineView(.animation) { ctx in
                        let t = ctx.date.timeIntervalSinceReferenceDate
                        let phase = (t.truncatingRemainder(dividingBy: duration)) / duration
                        GeometryReader { geo in
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0), location: 0.0),
                                    .init(color: .white.opacity(0), location: 0.40),
                                    .init(color: .white.opacity(intensity), location: 0.50),
                                    .init(color: .white.opacity(0), location: 0.60),
                                    .init(color: .white.opacity(0), location: 1.0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geo.size.width * 2)
                            .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                            .blendMode(.screen)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
        )
        .mask(content)
    }
}

extension View {
    /// Applies a looping diagonal white highlight on top — for gold surfaces.
    /// Halts animation if iOS Reduce Motion is enabled.
    func shimmerOverlay(duration: Double = 2.6, intensity: Double = 0.35) -> some View {
        modifier(ShinyGoldModifier(duration: duration, intensity: intensity))
    }
}
