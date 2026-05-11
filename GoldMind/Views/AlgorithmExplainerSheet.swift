import SwiftUI

/// Plain-English explanation of how the bias suggestion + ranking algorithm
/// works. Opened from the info button on the Most Triggered Pattern card
/// (and anywhere else the user might ask "how did you decide this?").
struct AlgorithmExplainerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                stepsCard
                scoringCard
                awarenessCard
                selfAuditCard
                citationCard
                cta
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(DS.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            // Hydrate local stats from Supabase so the self-audit
            // panel reflects the durable cross-device state.
            await MappingConfirmationStats.refreshFromRemote()
        }
    }

    // MARK: - Self-audit (low-confirmation mappings)

    /// Surfaces mappings the user's own data is rejecting. Builds trust:
    /// the algorithm is being graded by the user, not just running blind.
    /// Hidden when there are no flagged mappings yet (waiting for ≥20
    /// reviews per mapping before flagging).
    private var selfAuditCard: some View {
        let flagged = MappingConfirmationStats.lowConfirmationMappings()
        return Group {
            if flagged.isEmpty {
                sectionCard(title: "ALGORITHM AUDITS ITSELF") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Every YES / Not sure / Different feeds a per-mapping confirmation rate.")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("If a mapping (e.g. \"Ego Depletion on Coffee+Impulse\") drops below 30% confirmation after 20+ reviews, it gets flagged here for retirement. Right now, no mappings have crossed the threshold.")
                            .font(.system(.footnote, weight: .regular))
                            .foregroundStyle(DS.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                sectionCard(title: "MAPPINGS YOUR DATA IS REJECTING") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("These (purchase × bias) mappings are being confirmed less than 30% of the time across your reviews. Flagged for retirement.")
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(flagged.prefix(5), id: \.key.storageKey) { row in
                            flaggedRow(category: row.key.category, status: row.key.status, bias: row.key.bias, stats: row.stats)
                        }
                    }
                }
            }

            let flaggedQuestions = MappingConfirmationStats.lowConfirmationQuestions()
            if !flaggedQuestions.isEmpty {
                sectionCard(title: "QUESTIONS UNDERPERFORMING") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("These specific bias×category questions are confirmed less than 30% of the time. The question wording may need refining.")
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(flaggedQuestions.prefix(5), id: \.questionKey) { row in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.warning)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(row.questionKey.replacingOccurrences(of: "_", with: " × "))
                                        .font(.system(.subheadline, weight: .bold))
                                        .foregroundStyle(DS.textPrimary)
                                    Text("\(Int(row.stats.confirmationRate * 100))% confirmed · \(row.stats.sampleSize) reviews")
                                        .font(.system(.caption, weight: .semibold))
                                        .foregroundStyle(DS.textSecondary)
                                    Text("Q: \"\(BiasQuestionMatrix.question(for: row.questionKey.components(separatedBy: "_").first ?? "", category: row.questionKey.components(separatedBy: "_").last ?? ""))\"")
                                        .font(.system(.caption2, weight: .medium))
                                        .foregroundStyle(DS.textTertiary)
                                        .italic()
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.cardRadius)
                                    .stroke(DS.warning.opacity(0.3), lineWidth: 0.75)
                            )
                        }
                    }
                }
            }
        }
    }

    private func flaggedRow(category: String, status: String, bias: String, stats: MappingConfirmationStats.Stats) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(DS.warning)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(bias) on \(category) + \(status)")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                Text("\(Int(stats.confirmationRate * 100))% confirmed · \(stats.sampleSize) reviews")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
        }
        .padding(10)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.warning.opacity(0.3), lineWidth: 0.75)
        )
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 44))
                .foregroundStyle(DS.goldBase)

            Text("How Nudge decides")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: DS.deepGreen.opacity(0.7), radius: 3, x: 0, y: 1)

            Text("A plain-English walk-through of the bias suggestion and ranking.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: DS.deepGreen.opacity(0.6), radius: 2, x: 0, y: 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(DS.heroGradient)
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 1)
        )
    }

    // MARK: - Steps

    private var stepsCard: some View {
        sectionCard(title: "STEP BY STEP") {
            VStack(alignment: .leading, spacing: 14) {
                step(1, "You pick a category (e.g. Coffee), a range, and a reason (Planned / Surprise / Impulse).")
                step(2, "Nudge suggests a bias based on your combination. For example: Coffee + Impulse → Status Quo Bias (habitual choice).")
                step(3, "The event is saved with that suggested tag. Every save nudges that bias up in your ranking.")
                step(4, "Your BFAS baseline (the 16 questions on first open) seeds each bias with 0–10. Your actual spending overrides that over time.")
            }
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(DS.nuggetGold).frame(width: 26, height: 26)
                Text("\(n)")
                    .font(.system(.footnote, weight: .heavy))
                    .foregroundStyle(DS.goldForeground)
            }
            Text(text)
                .font(.system(.subheadline, weight: .regular))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    // MARK: - Scoring

    private var scoringCard: some View {
        sectionCard(title: "HOW THE SCORE MOVES") {
            VStack(alignment: .leading, spacing: 10) {
                scoreRow("⬆ \"Yes, that's me\" (you identified it)", "+5 gold standard")
                scoreRow("⬇ \"No, different reason\" (active denial)", "−2")
                scoreRow("• \"Not sure\" (no signal)", "0")
                scoreRow("⬆ Each passive event tag", "+1 weak signal")
                scoreRow("⬆ BFAS baseline at signup", "0–10 one-time seed")
                Divider().background(DS.accent.opacity(0.15))
                Text("Active YES outweighs passive observation 5:1. Why: Stone et al. 1991, Robinson & Clore 2002. When you identify a pattern in real time, you're 3–5× more accurate than any algorithm watching from the outside. Beck 1976: the act of self-labelling is itself part of the change.")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Higher score = pattern is active in your life. Lower score = you're already aware and overriding it.")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func scoreRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, weight: .heavy))
                .foregroundStyle(DS.goldBase)
        }
    }

    // MARK: - Awareness reduces score

    private var awarenessCard: some View {
        sectionCard(title: "AWARENESS REDUCES THE SCORE") {
            VStack(alignment: .leading, spacing: 10) {
                Text("The more you recognise a pattern yourself, the lower it ranks.")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Identify the driver, override the decision. Mastery moves Unseen → Noticed → Emerging → Active → Aware as you flag patterns in check-ins.")
                    .font(.system(.footnote, weight: .regular))
                    .foregroundStyle(DS.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Coming soon: after each session, you can review each logged bias and confirm or re-tag it. Correct self-identification = stronger awareness signal.")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(Color(hex: "8B6010"))
                    .italic()
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Citation

    private var citationCard: some View {
        HStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 11))
                .foregroundStyle(DS.goldBase)
            Text("Bias mapping: Tversky & Kahneman 1973–81 · Thaler 1980/85 · Cialdini 2001 · Samuelson & Zeckhauser 1988 · Baumeister 1998. Scoring weight: Stone et al. 1991 · Robinson & Clore 2002 · Beck 1976. Framework: BFAS · Pompian 2012.")
                .font(.system(.footnote, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
        }
        .padding(14)
        .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.goldSurfaceStroke, lineWidth: 0.5))
    }

    // MARK: - CTA

    private var cta: some View {
        Button { dismiss() } label: { Text("Got it") }
            .goldButtonStyle()
    }

    // MARK: - Section card helper

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.goldBase)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
                .premiumCardShadow()
        }
    }
}

#Preview {
    AlgorithmExplainerSheet()
}
