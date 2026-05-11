import SwiftUI

struct AwarenessView: View {
    let patterns = allBiasPatterns
    @State private var biasProgress: [BiasProgress] = []
    @State private var eventTagCounts: [String: Int] = [:]

    func triggerCount(for pattern: BiasPattern) -> Int {
        let checkInCount = biasProgress.first(where: { $0.biasName == pattern.name })?.timesEncountered ?? 0
        let tagCount = eventTagCounts[pattern.name] ?? 0
        return checkInCount + tagCount
    }

    var triggered: [BiasPattern] { patterns.filter { triggerCount(for: $0) > 0 } }
    var awarenessScore: Int { triggered.count }

    /// Per-category SF Symbol — rendered in gold on the category pill.
    private func icon(for category: String) -> String {
        switch category.lowercased() {
        case "avoidance":         return "eye.slash"
        case "decision making":   return "arrow.triangle.branch"
        case "money psychology":  return "brain.head.profile"
        case "time perception":   return "hourglass"
        case "social":            return "person.2.fill"
        case "defaults & habits": return "arrow.clockwise"
        default:                  return "sparkle"
        }
    }

    /// Category-level BFAS anchor (short attribution under the pill).
    private func anchor(for category: String) -> String {
        switch category.lowercased() {
        case "avoidance":         return "Pompian 2012 · Ch. 4"
        case "decision making":   return "Kahneman 2011 · Thinking Fast & Slow"
        case "money psychology":  return "Thaler 1985 · Mental Accounting"
        case "time perception":   return "Laibson 1997 · Hyperbolic Discounting"
        case "social":            return "Cialdini 1984 · Influence"
        case "defaults & habits": return "Samuelson & Zeckhauser 1988"
        default:                  return "Pompian 2012"
        }
    }

    var body: some View {
        GeometryReader { geo in
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // ── HERO ──
                hero
                    .padding(.top, 16)

                // ── SCORE CARD (frosted dark) ──
                scoreCard

                // ── NUDGE SAYS (gold) ──
                NudgeSaysCard(
                    message: "Each pattern you identify sharpens your BFAS profile. Professional financial planners use the same framework to assess client behaviour.",
                    citation: "BFAS · Behavioural Finance Assessment Score",
                    surface: .whiteShimmer
                )

                // ── MOST COMMON IN RESEARCH (industry benchmark) ──
                industryTopBiasesCard

                // ── CATEGORIES (with mid-tab BFAS callouts every 2 sections) ──
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(biasCategories.enumerated()), id: \.element.name) { index, category in
                        VStack(alignment: .leading, spacing: 8) {
                            categoryHeader(category.name)
                            ForEach(category.patterns) { pattern in
                                BiasAwarenessCard(pattern: pattern, triggerCount: triggerCount(for: pattern))
                            }
                        }

                        // After every 2nd + 4th category
                        if index == 1 {
                            bfasCallout(
                                "These 16 patterns come from the Behavioural Finance Assessment Score. The same framework used by professional financial planners.",
                                cite: "Pompian, 2012"
                            )
                            .padding(.top, 6)
                        }
                        if index == 3 {
                            bfasCallout(
                                "Noticing a pattern is the first step. The algorithm tracks what you recognise, not what you avoid.",
                                cite: "Kahneman & Tversky, 1979"
                            )
                            .padding(.top, 6)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .frame(width: geo.size.width - 36, alignment: .leading)
            .padding(.horizontal, 18)
        }
        .frame(width: geo.size.width)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .background(DS.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if let progress = try? await SupabaseService.shared.fetchBiasProgress() {
                biasProgress = progress
            }
            if let events = try? await SupabaseService.shared.fetchMoneyEvents(forMonth: Date()) {
                eventTagCounts = events.compactMap(\.behaviourTag)
                    .reduce(into: [:]) { counts, tag in counts[tag, default: 0] += 1 }
            }
        }
    }

    // MARK: - Industry benchmark

    /// Top biases consistently flagged as most prevalent across behavioural
    /// finance literature (BFAS + Kahneman + Thaler + Samuelson/Zeckhauser).
    /// Shown as a benchmark so the user can compare their own triggered
    /// patterns against what shows up in the population at large.
    private let industryTopBiases: [(name: String, emoji: String, why: String, cite: String)] = [
        ("Loss Aversion", "⚖️", "Losses feel ~2× worse than equivalent gains. Nearly universal.", "Kahneman & Tversky, 1979"),
        ("Present Bias", "⏳", "Hyperbolic discounting: choosing now over future-you replicates across markets.", "Laibson, 1997"),
        ("Mental Accounting", "💰", "Treating money differently based on its label. Pervasive in household budgets.", "Thaler, 1985"),
        ("Status Quo Bias", "🔁", "Defaults win. Auto-renewals, subscriptions, inertia.", "Samuelson & Zeckhauser, 1988"),
        ("Anchoring", "⚓", "Reference prices shape what feels 'fair'. Present in every negotiation.", "Tversky & Kahneman, 1974"),
    ]

    private var industryTopBiasesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.goldBase)
                Text("MOST COMMON IN RESEARCH")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(DS.goldBase)
                Spacer()
            }

            Text("What shows up in the population. Not necessarily in you.")
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(Array(industryTopBiases.enumerated()), id: \.element.name) { idx, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(DS.goldForeground)
                            .frame(width: 22, height: 22)
                            .background(DS.nuggetGold, in: Circle())
                        Text(item.emoji).font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(DS.textPrimary)
                            Text(item.why)
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(DS.textSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 4) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(DS.goldBase)
                                Text(item.cite)
                                    .font(.system(.caption2, weight: .semibold))
                                    .foregroundStyle(DS.goldBase)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        .premiumCardShadow()
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your money mind")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                Text("YOUR BIAS PROFILE")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(DS.goldBase)
                Text("Tap any triggered pattern to hear from Nudge.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(DS.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            scorePill
        }
    }

    private var scorePill: some View {
        VStack(spacing: 2) {
            Text("\(awarenessScore)")
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(DS.goldForeground)
            Text("OF \(patterns.count)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.goldForeground.opacity(0.7))
        }
        .frame(width: 70, height: 64)
        .background(DS.nuggetGold, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.goldBase.opacity(0.4), lineWidth: 0.5))
    }

    // MARK: - Score card (frosted dark)

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Awareness score")
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                Text("\(awarenessScore) / \(patterns.count)")
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundStyle(DS.goldBase)
            }

            // Proportional progress bar via containerRelativeFrame —
            // GeometryReader's greedy width-claim was triggering iOS 26
            // ScrollView's horizontal-pan rubber-band on this tab.
            ZStack(alignment: .leading) {
                Capsule().fill(DS.mintBg)
                Capsule()
                    .fill(DS.nuggetGold)
                    .containerRelativeFrame(.horizontal) { width, _ in
                        width * CGFloat(awarenessScore) / CGFloat(max(patterns.count, 1))
                    }
                    .animation(.easeInOut(duration: 1.0), value: awarenessScore)
            }
            .frame(height: 8)

            ResearchFootnote(text: "Based on BFAS · used in professional financial planning", style: .pill)
                .padding(.top, 4)
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Category header (gold pill)

    // MARK: - Mid-tab BFAS callout (gold statement card, not a button)

    private func bfasCallout(_ text: String, cite: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(.system(.subheadline, weight: .semibold))
                .italic()
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.goldBase)
                Text("— \(cite)")
                    .font(.system(.caption2, weight: .heavy))
                    .foregroundStyle(DS.goldBase)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
        )
    }

    private func categoryHeader(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon(for: name))
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(DS.goldBase)
                Text(name.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(DS.goldBase)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DS.cardBg, in: Capsule())
            .overlay(Capsule().stroke(DS.goldBase.opacity(0.4), lineWidth: 0.5))

            Text(anchor(for: name))
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
                .padding(.leading, 14)
        }
    }
}

// ─────────────────────────────────
// BIAS CARD — gold surface on dark bg
// ─────────────────────────────────
struct BiasAwarenessCard: View {
    let pattern: BiasPattern
    let triggerCount: Int
    @State private var expanded = false
    var isTriggered: Bool { triggerCount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── MAIN ROW ──
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isTriggered ? DS.goldSurfaceBg : DS.goldBase.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(DS.goldBase.opacity(isTriggered ? 0.4 : 0.2), lineWidth: 0.5))
                    Image(systemName: pattern.sfSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isTriggered ? DS.goldBase : DS.goldBase.opacity(0.45))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.displayName)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(DS.textPrimary)
                    Text(pattern.oneLiner)
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(DS.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if let lesson = BiasLessonsMock.seed.first(where: { $0.biasName == pattern.name }) {
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(DS.goldBase)
                                .padding(.top, 2)
                            Text(lesson.howToCounter.split(separator: ".").first.map { String($0) + "." } ?? lesson.howToCounter)
                                .font(.system(.footnote, weight: .semibold))
                                .foregroundStyle(DS.accent)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    ResearchFootnote(text: pattern.keyRef)
                        .padding(.top, 2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if isTriggered {
                        Text("\(triggerCount)×")
                            .font(.system(.footnote, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(DS.deepGreen, in: Capsule())
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DS.goldBase)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.goldBase.opacity(0.3))
                    }
                }
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isTriggered else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    expanded.toggle()
                }
            }

            // ── EXPANDED: NUDGE SAYS + KEY REF ──
            if expanded && isTriggered {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .background(DS.goldSurfaceStroke)
                        .padding(.horizontal, 14)

                    HStack(alignment: .top, spacing: 10) {
                        Image("nudge")
                            .resizable().scaledToFit()
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NUDGE")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(1.6)
                                .foregroundStyle(DS.accent)
                            Text(pattern.nudgeSays)
                                .font(.system(.subheadline, weight: .regular))
                                .foregroundStyle(DS.textPrimary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 14)

                    ResearchFootnote(text: pattern.keyRef)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            DS.cardBg.opacity(isTriggered ? 1.0 : 0.88),
            in: RoundedRectangle(cornerRadius: DS.cardRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 1.5)
        )
    }
}
