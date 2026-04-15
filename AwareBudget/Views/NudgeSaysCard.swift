import SwiftUI

struct NudgeSaysCard: View {
    enum Surface { case paleGreen, gold, whiteShimmer }

    let message: String
    let citation: String?
    var showCoin: Bool = true
    var surface: Surface = .paleGreen

    init(message: String, citation: String? = nil, showCoin: Bool = true, surface: Surface = .paleGreen) {
        self.message = message
        self.citation = citation
        self.showCoin = showCoin
        self.surface = surface
    }

    private var backgroundColor: Color {
        switch surface {
        case .paleGreen:    return DS.paleGreen
        case .gold:         return DS.goldSurfaceBg
        case .whiteShimmer: return DS.cardBg
        }
    }

    private var borderColor: Color {
        switch surface {
        case .paleGreen:    return DS.deepGreen
        case .gold:         return DS.goldSurfaceStroke
        case .whiteShimmer: return .clear
        }
    }

    private var useShimmerBorder: Bool { surface == .whiteShimmer }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if showCoin {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("NUDGE")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(DS.accent)

                Text(message)
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                if let citation, !citation.isEmpty {
                    Text(citation)
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(DS.textTertiary)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay {
            if !useShimmerBorder {
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .modifier(OptionalShimmerBorder(enabled: useShimmerBorder, radius: DS.cardRadius))
        .modifier(OptionalShadow(enabled: useShimmerBorder))
    }
}

private struct OptionalShadow: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled { content.premiumCardShadow() } else { content }
    }
}

private struct OptionalShimmerBorder: ViewModifier {
    let enabled: Bool
    let radius: CGFloat
    func body(content: Content) -> some View {
        if enabled {
            content.shimmeringGoldBorder(cornerRadius: radius)
        } else {
            content
        }
    }
}
