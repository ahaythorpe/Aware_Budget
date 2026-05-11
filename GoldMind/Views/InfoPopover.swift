import SwiftUI

/// Tiny gold "?" button that reveals a short explanation in a popover.
/// Used on dense Home + Settings labels where "what does this mean?"
/// friction would otherwise send users to Education. Pattern B from the
/// fold-up plan.
///
/// Usage:
///   HStack {
///     Text("Patterns identified")
///     InfoPopover("Patterns are the 16 biases tracked from your spending.")
///   }
struct InfoPopover: View {
    let text: String
    var title: String? = nil
    @State private var open = false

    init(_ text: String, title: String? = nil) {
        self.text = text
        self.title = title
    }

    var body: some View {
        Button { open = true } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DS.goldBase.opacity(0.7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("More info"))
        .popover(isPresented: $open, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                if let title {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(DS.goldBase)
                }
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: 280, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        Text("Patterns identified")
        InfoPopover("Patterns are the 16 biases tracked from your spending. Each tagged log moves the count.")
    }
    .padding()
}
