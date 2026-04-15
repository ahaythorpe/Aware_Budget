import SwiftUI

// MARK: - Color hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Design tokens

typealias DesignSystem = DS

enum DS {
    // Locked sizing tokens (handbook §3.5 F-rules)
    static let cardRadius: CGFloat = 20          // primary cards (greeting, Top Biases, Nudge)
    static let smallCardRadius: CGFloat = 14     // secondary cards (bias rows, stat cards)
    static let buttonRadius: CGFloat = 14
    static let hPadding: CGFloat = 16
    static let sectionGap: CGFloat = 20

    // Button heights (F3)
    static let buttonHeight: CGFloat = 44
    static let primaryButtonHeight: CGFloat = 52

    // Locked animation durations (F6)
    static let animEase: Double = 0.2
    static let animSpring: Double = 0.35
    static let animProgress: Double = 1.2

    // Money green palette
    static let primary    = Color(hex: "2E7D32")   // hero cards, nav
    static let accent     = Color(hex: "4CAF50")   // labels, ring, buttons
    static let lightGreen = Color(hex: "81C784")   // card backs, tints
    static let paleGreen  = Color(hex: "E8F5E9")   // pills, tab active bg
    static let bg         = Color(hex: "FAFAF8")   // app background
    static let altBg      = Color(hex: "F5F7F5")   // alternate background
    static let cardBg     = Color.white             // card background
    static let darkGreen  = Color(hex: "1A5C38")   // dark green text/buttons
    static let deepGreen  = Color(hex: "1B5E20")   // deepest green
    static let mintBg     = Color(hex: "C8E6C9")   // mint card backs
    static let mintLight  = Color(hex: "A5D6A7")   // lighter mint

    // Text
    static let textPrimary   = Color(hex: "1A2E1A")
    static let textSecondary = Color(hex: "6B7A6B")
    static let textTertiary  = Color(hex: "A0B0A0")

    // Text on dark (metallic green bg) — handbook §1.3
    static let onDarkPrimary   = Color.white
    static let onDarkSecondary = Color.white.opacity(0.75)
    static let onDarkTertiary  = Color.white.opacity(0.55)

    // Card surface overlays on dark green bg
    static let frostedCardBg     = Color.white.opacity(0.08)
    static let frostedCardStroke = Color.white.opacity(0.15)
    static let goldSurfaceBg     = Color(hex: "FFF8E1")   // key-feature cards on dark bg
    static let goldSurfaceStroke = Color(hex: "C59430").opacity(0.3)

    // Semantic
    static let positive = Color(hex: "4CAF50")
    static let warning  = Color(hex: "FF7043")
    static let danger   = Color(hex: "FF6B6B")

    // Gold on-element foregrounds
    static let goldForeground = Color(hex: "1B3A00")  // text on gold buttons
    static let goldTint       = Color(hex: "3A2000")   // progress tint on gold

    // Stage badge colours
    static let stageActive   = Color(hex: "C62828")
    static let stageEmerging = Color(hex: "E65100")
    static let stageNoticed  = Color(hex: "42A5F5")

    // Hero gradient (dark green cards)
    // Shinier metallic green — peak shifted off-center so it doesn't bleach white text
    static let heroGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "0F4E15"), location: 0.0),
            .init(color: Color(hex: "1B5E20"), location: 0.18),
            .init(color: Color(hex: "2E7D32"), location: 0.35),
            .init(color: Color(hex: "66BB6A"), location: 0.55),
            .init(color: Color(hex: "81C784"), location: 0.75),
            .init(color: Color(hex: "A5E8AC"), location: 0.88),
            .init(color: Color(hex: "0F4E15"), location: 1.0),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Gold
    static let goldBase = Color(hex: "C59430")
    static let goldText = Color(hex: "E8B84B")

    // MARK: - Nugget Gold gradient (metallic shiny)

    // Matches "Gold Gradient buttons.png" reference — symmetric bronze edges,
    // sharp diagonal specular stripe.
    static let nuggetGold = LinearGradient(
        stops: [
            .init(color: Color(hex: "5C3A0A"), location: 0.0),
            .init(color: Color(hex: "8B6010"), location: 0.14),
            .init(color: Color(hex: "B07820"), location: 0.28),
            .init(color: Color(hex: "E0C050"), location: 0.40),
            .init(color: Color(hex: "FFF0A0"), location: 0.47),
            .init(color: Color(hex: "FFFDF0"), location: 0.5),
            .init(color: Color(hex: "FFF0A0"), location: 0.53),
            .init(color: Color(hex: "E0C050"), location: 0.60),
            .init(color: Color(hex: "B07820"), location: 0.72),
            .init(color: Color(hex: "8B6010"), location: 0.86),
            .init(color: Color(hex: "5C3A0A"), location: 1.0),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Gold Button modifier

struct GoldButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, weight: .bold))
            .foregroundStyle(DS.goldForeground)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(DS.nuggetGold)
                    .shimmerOverlay()
                    .clipShape(Capsule())
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color(hex: "FFF8D0").opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: Color(hex: "5C3A0A").opacity(0.25), radius: 1, x: 0, y: 1)
            .shadow(color: Color(hex: "5C3A0A").opacity(0.20), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Gold Ring modifier

struct GoldRingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "FFF0A0"), location: 0.0),
                                .init(color: Color(hex: "C59430"), location: 0.4),
                                .init(color: Color(hex: "8B6010"), location: 0.7),
                                .init(color: Color(hex: "E8B84B"), location: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
            )
    }
}

// MARK: - View extensions

extension View {
    func goldButtonStyle() -> some View {
        modifier(GoldButtonStyle())
    }
    func goldRing() -> some View {
        modifier(GoldRingModifier())
    }
}

// MARK: - Nudge avatar (green circle hides black bg in PNG)

struct NudgeAvatar: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: size + 4, height: size + 4)
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
}

// MARK: - Card container

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(DS.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
    }
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = DS.primary
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tint, in: RoundedRectangle(cornerRadius: DS.buttonRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DS.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DS.buttonRadius, style: .continuous)
                    .fill(DS.paleGreen)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: "4CAF50"))
                .textCase(.uppercase)
                .tracking(1.5)
            Spacer()
            if let trailing, let trailingAction {
                Button(trailing, action: trailingAction)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.accent)
            }
        }
    }
}
