import SwiftUI

enum DS {
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 14
    static let hPadding: CGFloat = 16
    static let sectionGap: CGFloat = 20

    // Brand palette (PRD v1.1)
    static let bg         = Color(red: 0xF7/255.0, green: 0xF4/255.0, blue: 0xEF/255.0) // #F7F4EF
    static let deepPurple = Color(red: 0x2D/255.0, green: 0x1B/255.0, blue: 0x69/255.0) // #2D1B69
    static let accent     = Color(red: 0x7F/255.0, green: 0x77/255.0, blue: 0xDD/255.0) // #7F77DD
    static let coral      = Color(red: 0xFF/255.0, green: 0x7A/255.0, blue: 0x6B/255.0) // warm coral
    static let teal       = Color(red: 0x00/255.0, green: 0x60/255.0, blue: 0x64/255.0) // #006064
}

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
