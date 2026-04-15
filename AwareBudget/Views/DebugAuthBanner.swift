import SwiftUI

#if DEBUG
struct DebugAuthBanner: View {
    @State private var status = DebugAuthStatus.shared

    private var isOK: Bool {
        status.status.contains("signed")
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isOK ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isOK ? DS.positive : DS.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("DEBUG AUTH")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(DS.textTertiary)
                Text(status.status)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }
}
#endif
