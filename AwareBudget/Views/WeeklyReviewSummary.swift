import SwiftUI

/// Sunday weekly review summary screen (PRD v1.2).
/// Prepended to the regular check-in flow once per ISO week.
/// Shows: week's top biases · week spend · alignment trend ·
/// Nudge commentary. User taps "Begin 4 questions →" to proceed.
struct WeeklyReviewSummary: View {
    let topBiases: [HomeViewModel.DailyPattern]
    let weekSpend: Double
    let eventCount: Int
    let streak: Int
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                statsGrid
                biasesList
                nudgeSays
                ctaButton
            }
            .padding(22)
        }
        .background(DS.bg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Your week in patterns")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(DS.textPrimary)

            Text(weekRangeLabel())
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 10) {
            statCard(value: "$\(Int(weekSpend))", label: "SPENT", tint: DS.goldText)
            statCard(value: "\(eventCount)", label: "EVENTS", tint: DS.accent)
            statCard(value: "\(streak)", label: "STREAK", tint: DS.deepGreen)
        }
    }

    private func statCard(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var biasesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TOP PATTERNS THIS WEEK")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.accent)

            if topBiases.isEmpty {
                Text("No patterns tracked yet this week")
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(DS.textTertiary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(topBiases.prefix(3)) { p in
                        HStack(spacing: 12) {
                            Text(p.emoji).font(.system(size: 20))
                            Text(p.biasName)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(DS.textPrimary)
                            Spacer()
                            Text(p.stage.rawValue)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(DS.deepGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(DS.paleGreen, in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var nudgeSays: some View {
        NudgeSaysCard(
            message: nudgeCommentary,
            citation: "Reviewed by the BFAS framework"
        )
    }

    private var nudgeCommentary: String {
        if topBiases.isEmpty {
            return "A quiet week. Next week is where the real pattern shows up."
        } else if let top = topBiases.first {
            return "\(top.biasName) showed up most this week. 4 questions coming up to check in on that."
        } else {
            return "Here's your week. 4 questions coming up."
        }
    }

    private var ctaButton: some View {
        Button(action: onContinue) {
            Text("Begin 4 questions →")
        }
        .goldButtonStyle()
        .padding(.top, 4)
    }

    private func weekRangeLabel() -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let now = Date()
        guard let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let sunday = cal.date(byAdding: .day, value: 6, to: monday) else {
            return ""
        }
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return "Week of \(f.string(from: monday)) – \(f.string(from: sunday))"
    }
}
