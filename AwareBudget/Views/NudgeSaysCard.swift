import SwiftUI

struct NudgeSaysCard: View {
    let message: String
    let citation: String?
    var showCoin: Bool = true

    init(message: String, citation: String? = nil, showCoin: Bool = true) {
        self.message = message
        self.citation = citation
        self.showCoin = showCoin
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if showCoin {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("NUDGE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(DS.accent)

                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                if let citation, !citation.isEmpty {
                    Text(citation)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(DS.textTertiary)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.paleGreen, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }
}
