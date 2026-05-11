import SwiftUI

struct NudgeCardView: View {
    let message: NudgeMessage
    var onAction: ((NudgeAction) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Green left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(DS.accent)
                .frame(width: 3)

            // Nudge avatar
            NudgeAvatar(size: 44)

            // Content
            VStack(alignment: .leading, spacing: 10) {
                Text(message.body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(DS.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if case .withAction(_, let label, let action) = message {
                    Button {
                        onAction?(action)
                    } label: {
                        Text(label)
                            .font(.system(size: 13, weight: .bold))
                            .goldButtonStyle()
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)

            // Dismiss X
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DS.textTertiary)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .stroke(DS.paleGreen, lineWidth: 0.5)
        )
        .padding(.horizontal, DS.hPadding)
        .offset(y: appeared ? 0 : 80)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Dismiss persistence (24h)

enum NudgeDismissStore {
    private static let key = "nudge_dismissed_at"

    static func dismiss() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key)
    }

    static var isDismissed: Bool {
        let ts = UserDefaults.standard.double(forKey: key)
        guard ts > 0 else { return false }
        let dismissed = Date(timeIntervalSince1970: ts)
        return Date().timeIntervalSince(dismissed) < 24 * 60 * 60
    }
}

// MARK: - Dedup persistence (never same message twice in a row)

enum NudgeDedup {
    private static let key = "nudge_last_message"

    static func isDuplicate(_ message: NudgeMessage) -> Bool {
        let stored = UserDefaults.standard.string(forKey: key)
        return stored == message.body
    }

    static func record(_ message: NudgeMessage) {
        UserDefaults.standard.set(message.body, forKey: key)
    }
}

#Preview {
    VStack {
        Spacer()
        NudgeCardView(
            message: .withAction(
                "You were gone 3 days. Nudge noticed. No lecture. Your streak starts fresh today.",
                actionLabel: "Check in now",
                action: .startCheckIn
            )
        )
    }
    .background(DS.bg)
}
