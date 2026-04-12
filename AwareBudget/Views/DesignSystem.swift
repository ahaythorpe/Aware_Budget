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
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 14
    static let hPadding: CGFloat = 16
    static let sectionGap: CGFloat = 20

    // Brand palette (PRD v1.1)
    static let bg         = Color(hex: "F7F4EF")
    static let deepPurple = Color(hex: "2D1B69")
    static let accent     = Color(hex: "7F77DD")
    static let coral      = Color(hex: "FF7A6B")
    static let teal       = Color(hex: "006064")

    // MARK: - Nugget Gold System

    static let nuggetGold = LinearGradient(
        stops: [
            .init(color: Color(hex: "FFF0A0"), location: 0.0),
            .init(color: Color(hex: "E8B84B"), location: 0.25),
            .init(color: Color(hex: "C59430"), location: 0.5),
            .init(color: Color(hex: "8B6010"), location: 0.75),
            .init(color: Color(hex: "D4A843"), location: 1.0),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldText = Color(hex: "E8B84B")
}

// MARK: - Gold Button modifier

struct GoldButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color(hex: "3A2000"))
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 999)
                    .fill(LinearGradient(
                        stops: [
                            .init(color: Color(hex: "FFF0A0"), location: 0.0),
                            .init(color: Color(hex: "E8B84B"), location: 0.3),
                            .init(color: Color(hex: "C59430"), location: 0.6),
                            .init(color: Color(hex: "8B6010"), location: 0.85),
                            .init(color: Color(hex: "D4A843"), location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color(hex: "FFF0A0").opacity(0.4), lineWidth: 0.5)
            )
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
        modifier(GoldButton())
    }
    func goldRing() -> some View {
        modifier(GoldRingModifier())
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
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
    }
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = .blue
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
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DS.buttonRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
            if let trailing, let trailingAction {
                Button(trailing, action: trailingAction)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
            }
        }
    }
}
