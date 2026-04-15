import SwiftUI

struct AwarenessView: View {
    let patterns = allBiasPatterns
    @State private var biasProgress: [BiasProgress] = []

    func triggerCount(for pattern: BiasPattern) -> Int {
        biasProgress.first(where: { $0.biasName == pattern.name })?.timesEncountered ?? 0
    }

    var triggered: [BiasPattern] { patterns.filter { triggerCount(for: $0) > 0 } }
    var awarenessScore: Int { triggered.count }

    // Category label icon (single consistent brand icon, not per-category emoji).
    private let categoryIcon = "sparkle"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // ── HERO ──
                hero
                    .padding(.top, 16)
                    .padding(.horizontal, 18)

                // ── SCORE CARD (frosted dark) ──
                scoreCard
                    .padding(.horizontal, 18)

                // ── NUDGE SAYS (gold) ──
                NudgeSaysCard(
                    message: "Each pattern you identify sharpens your BFAS profile. Professional financial planners use the same framework to assess client behaviour.",
                    citation: "BFAS · Behavioural Finance Assessment Score",
                    surface: .gold
                )
                .padding(.horizontal, 18)

                // ── CATEGORIES ──
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(biasCategories, id: \.name) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            categoryHeader(category.name)
                                .padding(.horizontal, 18)
                            ForEach(category.patterns) { pattern in
                                BiasAwarenessCard(pattern: pattern, triggerCount: triggerCount(for: pattern))
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(DS.heroGradient.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            if let progress = try? await SupabaseService.shared.fetchBiasProgress() {
                biasProgress = progress
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your money mind")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(DS.onDarkPrimary)
                Text("Tap any triggered pattern to hear from Nudge.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(DS.onDarkSecondary)
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
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.0)
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

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.mintBg).frame(height: 8)
                    Capsule()
                        .fill(DS.nuggetGold)
                        .frame(
                            width: geo.size.width * CGFloat(awarenessScore) / CGFloat(patterns.count),
                            height: 8)
                        .animation(.easeInOut(duration: 1.0), value: awarenessScore)
                }
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

    private func categoryHeader(_ name: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: categoryIcon)
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
                    Text(pattern.name)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(DS.textPrimary)
                    Text(pattern.oneLiner)
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(DS.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
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
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .tracking(1.5)
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
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isTriggered ? DS.goldBase.opacity(0.4) : DS.accent.opacity(0.15),
                    lineWidth: isTriggered ? 1 : 0.5
                )
        )
    }
}
