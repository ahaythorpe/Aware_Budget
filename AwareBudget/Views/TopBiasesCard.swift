import SwiftUI

/// Home screen Top 4 biases tracker.
/// Handbook §7.3. Reads from HomeViewModel.dailyPatterns (top-N by score).
/// User never sees raw scores — only name, trend, stage pill.
struct TopBiasesCard: View {
    let patterns: [HomeViewModel.DailyPattern]
    let totalSeen: Int
    var onTap: ((String) -> Void)? = nil
    var onInfoTap: (() -> Void)? = nil

    private var topFour: [HomeViewModel.DailyPattern] {
        Array(patterns.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if topFour.isEmpty {
                Text("Complete your first check-in to start tracking")
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(DS.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(topFour) { pattern in
                        Button { onTap?(pattern.biasName) } label: {
                            row(pattern)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("YOUR TOP BIASES")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.nuggetGold)
                .shimmerOverlay(duration: 3.0, intensity: 0.45)
            if onInfoTap != nil {
                Button { onInfoTap?() } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.goldBase)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text("\(totalSeen)/16")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(DS.textTertiary)
        }
    }

    private func row(_ p: HomeViewModel.DailyPattern) -> some View {
        HStack(spacing: 12) {
            Text(p.emoji)
                .font(.system(size: 20))
                .frame(width: 26)
            Text(p.biasName)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
            Spacer()
            trendLabel(for: p)
            stagePill(p.stage)
        }
    }

    @ViewBuilder
    private func trendLabel(for p: HomeViewModel.DailyPattern) -> some View {
        // Derived from mastery stage + score — not exposed as raw number.
        // aware/improving ↘, active/emerging ↗, noticed/unseen –
        switch p.stage {
        case .aware:
            Image(systemName: "arrow.down.right")
                .font(.system(.caption2, weight: .bold))
                .foregroundStyle(DS.positive)
        case .active, .emerging:
            Image(systemName: "arrow.up.right")
                .font(.system(.caption2, weight: .bold))
                .foregroundStyle(DS.warning)
        case .noticed, .unseen, .improving:
            Image(systemName: "minus")
                .font(.system(.caption2, weight: .bold))
                .foregroundStyle(DS.textTertiary)
        }
    }

    private func stagePill(_ stage: MasteryStage) -> some View {
        let (bg, fg): (Color, Color) = {
            switch stage {
            case .unseen:    return (DS.textTertiary.opacity(0.15), DS.textSecondary)
            case .noticed:   return (DS.stageNoticed.opacity(0.18), DS.stageNoticed)
            case .emerging:  return (DS.stageEmerging.opacity(0.18), DS.stageEmerging)
            case .active:    return (DS.stageActive.opacity(0.18), DS.stageActive)
            case .aware:     return (DS.positive.opacity(0.18), DS.positive)
            case .improving: return (DS.positive.opacity(0.12), DS.positive)
            }
        }()
        return Text(stage.rawValue)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg, in: Capsule())
    }
}
