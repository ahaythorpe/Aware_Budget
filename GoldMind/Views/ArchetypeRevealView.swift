import SwiftUI

/// Shown after the Money Mind Quiz completes. Reveals the user's archetype
/// with a soft fade-in, then lists the top biases they're likely prone to
/// in numbered priority, plus a comparison table showing how the other
/// archetypes scored against theirs.
///
/// Per the canonical framework (project_goldmind_archetypes.md): archetype
/// is the SURFACE label, biases are the DEEP data. Citation footer credits
/// Klontz, Pompian, and the underlying BFAS bias canon.
struct ArchetypeRevealView: View {
    let archetype: Archetype
    let scores: [Archetype: Int]
    var onDone: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var revealed: Bool = false

    private var topBiasPatterns: [BiasPattern] {
        // Preserve the numbered order defined on Archetype.topBiasNames.
        let names = archetype.topBiasNames
        return names.compactMap { name in allBiasPatterns.first(where: { $0.name == name }) }
    }

    /// All 6 archetypes sorted by the user's score, descending. Used by
    /// the comparison table so the user can see where they landed
    /// relative to every other archetype.
    private var rankedArchetypes: [(Archetype, Int)] {
        Archetype.allCases
            .map { ($0, scores[$0] ?? 0) }
            .sorted { $0.1 > $1.1 }
    }

    /// Secondary archetype = the one immediately below the primary. Used
    /// to colour the "why this and not that" reorder explanation.
    private var secondaryArchetype: Archetype? {
        rankedArchetypes.first(where: { $0.0 != archetype })?.0
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    heroCard
                    biasesSection
                    comparisonSection
                    citationFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .opacity(revealed ? 1.0 : 0.0)
                .offset(y: revealed ? 0 : 12)
                .animation(.easeOut(duration: 0.55), value: revealed)
            }
            VStack {
                Spacer()
                doneButton
            }
        }
        .onAppear {
            revealed = true
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: archetype.sfSymbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                Text("YOUR SPENDING PERSONALITY")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            Text(archetype.displayName)
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(.white)
            Text(archetype.oneLiner)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DS.heroGradient)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }

    // MARK: - Top biases (numbered)

    private var biasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("TOP 3 BIASES YOU'RE LIKELY PRONE TO")
            ForEach(Array(topBiasPatterns.prefix(3).enumerated()), id: \.element.id) { idx, p in
                numberedBiasRow(rank: idx + 1, pattern: p)
            }
            if topBiasPatterns.isEmpty {
                Text("Awareness of the underlying patterns is most of the work.")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.textSecondary)
            }
        }
    }

    private func numberedBiasRow(rank: Int, pattern p: BiasPattern) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Numbered medallion — gold for #1, gold-outline for #2/#3.
            ZStack {
                Circle()
                    .fill(rank == 1 ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg))
                    .overlay(
                        Circle().stroke(DS.goldBase, lineWidth: rank == 1 ? 0 : 1.5)
                    )
                Text("\(rank)")
                    .font(.system(size: 16, weight: .black, design: .serif))
                    .foregroundStyle(rank == 1 ? Color.white : DS.goldBase)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: p.sfSymbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: p.iconColor))
                    Text(p.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                }
                Text(p.oneLiner)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(p.keyRef)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(DS.goldBase)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DS.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(rank == 1 ? DS.accent.opacity(0.35) : DS.goldBase.opacity(0.18),
                        lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Comparison table

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("HOW THE 6 ARCHETYPES RANKED FOR YOU")
            Text("Your answers gave every personality a score. \(archetype.displayName) came out on top. Here's the full ordering. Most people are a blend.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(Array(rankedArchetypes.enumerated()), id: \.element.0.id) { idx, pair in
                    comparisonRow(rank: idx + 1, arch: pair.0, score: pair.1, maxScore: rankedArchetypes.first?.1 ?? 1)
                    if idx < rankedArchetypes.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DS.goldBase.opacity(0.2), lineWidth: 1)
            )

            if let secondary = secondaryArchetype, (scores[secondary] ?? 0) > 0 {
                whyThisNotThat(primary: archetype, secondary: secondary)
            }
        }
    }

    private func comparisonRow(rank: Int, arch: Archetype, score: Int, maxScore: Int) -> some View {
        let isYou = arch == archetype
        let fraction = maxScore > 0 ? Double(score) / Double(maxScore) : 0
        return HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 14, weight: .heavy, design: .serif))
                .foregroundStyle(isYou ? DS.accent : DS.textSecondary)
                .frame(width: 22)
            Image(systemName: arch.sfSymbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isYou ? DS.accent : DS.textSecondary.opacity(0.7))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(arch.displayName)
                        .font(.system(size: 14, weight: isYou ? .bold : .semibold))
                        .foregroundStyle(DS.textPrimary)
                    if isYou {
                        Text("YOU")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(DS.accent))
                    }
                }
                // Mini bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DS.bg)
                            .frame(height: 4)
                        Capsule()
                            .fill(isYou ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.goldBase.opacity(0.5)))
                            .frame(width: max(2, geo.size.width * fraction), height: 4)
                    }
                }
                .frame(height: 4)
            }
            Text("\(score)")
                .font(.system(size: 13, weight: .heavy, design: .serif))
                .foregroundStyle(isYou ? DS.accent : DS.textSecondary)
                .frame(width: 24, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isYou ? DS.paleGreen.opacity(0.4) : Color.clear)
    }

    private func whyThisNotThat(primary: Archetype, secondary: Archetype) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WHY \(primary.rawValue.uppercased()) AND NOT \(secondary.rawValue.uppercased())")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.goldBase)
            Text(whyExplanation(primary: primary, secondary: secondary))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.paleGreen.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.goldBase.opacity(0.25), lineWidth: 1)
        )
    }

    /// Plain-English explanation of the primary-vs-secondary split.
    /// Keeps the table educational: the secondary signal is also real,
    /// just not the dominant one in your answers.
    private func whyExplanation(primary: Archetype, secondary: Archetype) -> String {
        "Your answers leaned harder on the patterns behind \(primary.displayName) (\(primary.oneLiner)) than \(secondary.displayName) (\(secondary.oneLiner)). Both signals are present in you. The primary is just where Nudge will start watching first."
    }

    // MARK: - Footer

    private var citationFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ABOUT THIS ASSESSMENT")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(DS.textSecondary)
            Text("Based on the BFAS framework (Pompian, 2012) with personality mapping drawn from Klontz & Britt's Money Scripts (2011), Pompian's Behavioral Investor Types (2012), and underlying research (Kahneman & Tversky 1974, 1979; Thaler 1985; Laibson 1997; Samuelson & Zeckhauser 1988; Banerjee 1992; Galai & Sade 2006).")
                .font(.system(size: 11))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .padding(.bottom, 80)
    }

    private var doneButton: some View {
        Button {
            onDone()
            dismiss()
        } label: {
            Text("Take me to my Education")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DS.heroGradient)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(
            LinearGradient(colors: [DS.bg.opacity(0), DS.bg], startPoint: .top, endPoint: .center)
        )
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(DS.accent)
    }
}

#Preview {
    ArchetypeRevealView(archetype: .reactor, scores: [
        .reactor: 6, .now: 4, .drifter: 2, .bandwagon: 1, .autopilot: 0, .bookkeeper: 0
    ])
}
