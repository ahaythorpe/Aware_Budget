import SwiftUI

/// Native SwiftUI shimmer — a narrow diagonal highlight stripe that slides
/// across the modified view on a loop. Applied on top of gold surfaces to
/// give the metallic foil a "catching the light" feel without a package.
///
/// Usage: `.shimmerOverlay()` — applies to anything. Performance-friendly
/// (one `TimelineView`, no recomputation per frame of the underlying view).
struct ShinyGoldModifier: ViewModifier {
    var duration: Double = 2.6
    var intensity: Double = 0.35

    func body(content: Content) -> some View {
        content.overlay(
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
        )
        .mask(content)
    }
}

extension View {
    /// Applies a looping diagonal white highlight on top — for gold surfaces.
    func shimmerOverlay(duration: Double = 2.6, intensity: Double = 0.35) -> some View {
        modifier(ShinyGoldModifier(duration: duration, intensity: intensity))
    }
}
