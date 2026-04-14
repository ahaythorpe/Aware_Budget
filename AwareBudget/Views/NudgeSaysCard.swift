import SwiftUI

struct NudgeSaysCard: View {
    let message: String
    let citation: String
    var showCoin: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if showCoin {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .padding(.top, 1)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("NUDGE SAYS")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "#2E7D32"))
                Text(message)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color(hex: "#1B5E20"))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                Text(citation)
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color(hex: "#E8F5E9"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#4CAF50").opacity(0.3), lineWidth: 0.5)
        )
    }
}
