import SwiftUI

/// 5th tab — Education. Surfaces the credibility content for users who want
/// the deep-dive. Top: the 6 archetype families (clickable, expand inline to
/// show biases). Below: the 4 canonical papers, BFAS framework, ranking
/// explainer, full bias list, and counter-strategies. CredibilitySheet stays
/// as the in-context popup behind ⓘ.
///
/// Renamed from "Research" 2026-05-11 (RootTabView label updated; struct
/// name kept as ResearchView to avoid a wider rename touching imports and
/// preview names — micro-fix policy).
struct ResearchView: View {
    /// Tracks which archetype cards are currently expanded. Multiple can
    /// be open at once so the user can compare families.
    @State private var expandedCategories: Set<String> = []

    /// User's archetype from `profiles.archetype` (Money Mind Quiz result).
    /// Drives the "← You" tag on the matching category card and the
    /// "Take the quiz" CTA. Loaded once on appear.
    @State private var userArchetype: String? = nil
    @State private var showQuiz: Bool = false

    /// Friendly archetype name + tagline + citation marker per category.
    /// Tied to the canonical 6-archetype framework approved 2026-05-11
    /// (see memory: project_goldmind_archetypes.md).
    private func archetype(for category: String) -> (name: String, tagline: String) {
        switch category {
        case "Avoidance":         return ("The Drifter",     "Looks away. Defers. Hopes it sorts itself.")
        case "Decision Making":   return ("The Reactor",     "Decides fast. Regrets later.")
        case "Money Psychology":  return ("The Bookkeeper",  "Mental ledgers. Tax refund ≠ salary.")
        case "Time Perception":   return ("The Now",         "Now > Future, every time.")
        case "Social":            return ("The Bandwagon",   "Buys what the crowd buys.")
        case "Defaults & Habits": return ("The Autopilot",   "Whatever the default is, fine.")
        default:                  return (category,           "")
        }
    }

    private let papers: [Paper] = [
        .init(author: "Pompian", year: "2012",
              title: "Behavioral Finance and Wealth Management",
              detail: "Codifies the BFAS framework GoldMind uses — 16 patterns, behavioural investor types, used by professional financial planners."),
        .init(author: "Kahneman & Tversky", year: "1979",
              title: "Prospect Theory",
              detail: "The original behavioural-economics paper. Loss aversion, framing, reference points. Econometrica 47(2):263–291."),
        .init(author: "Thaler & Sunstein", year: "2008",
              title: "Nudge",
              detail: "Choice architecture. Why default options matter. The book Nudge (the character) is named after."),
        .init(author: "Kahneman et al.", year: "2004",
              title: "Day Reconstruction Method",
              detail: "Why daily check-ins beat single survey moments. Science 306(5702):1776–1780."),
    ]

    struct Paper: Identifiable {
        let id = UUID()
        let author: String
        let year: String
        let title: String
        let detail: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                quizCTA
                categoriesSection
                papersSection
                frameworkSection
                howRankingWorks
                allBiasesSection
                spotAndOvercomeSection
                Spacer(minLength: 32)
            }
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 12)
        }
        .background(DS.bg.ignoresSafeArea())
        .navigationTitle("Education")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadArchetype() }
        .fullScreenCover(isPresented: $showQuiz, onDismiss: {
            Task { await loadArchetype() }
        }) {
            NavigationStack { MoneyMindQuizView() }
        }
    }

    /// Maps the BiasCategory name to the matching archetype rawValue (e.g.
    /// "Avoidance" → "Drifter") so we can highlight the user's card. Kept
    /// inline to avoid coupling ResearchView to the Archetype enum's
    /// init(rawValue:) — also more readable.
    private func archetypeRawValue(forCategory name: String) -> String {
        switch name {
        case "Avoidance":         "Drifter"
        case "Decision Making":   "Reactor"
        case "Money Psychology":  "Bookkeeper"
        case "Time Perception":   "Now"
        case "Social":            "Bandwagon"
        case "Defaults & Habits": "Autopilot"
        default:                  ""
        }
    }

    private func loadArchetype() async {
        let profile = try? await SupabaseService.shared.fetchProfile()
        await MainActor.run { userArchetype = profile?.archetype }
    }

    /// Take-the-quiz CTA. Hidden once the user has an archetype — the
    /// "← You" tag on the matching family card becomes the silent indicator.
    @ViewBuilder private var quizCTA: some View {
        if userArchetype == nil {
            Button { showQuiz = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take the Money Mind Quiz")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Find your archetype · 2 min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .fill(DS.heroGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.goldBase, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hero (green moment)

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Your money mind")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: DS.deepGreen.opacity(0.7), radius: 4, x: 0, y: 1)

            Text("The 16 patterns behind your decisions — grouped into six families, with the science to back them.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: DS.deepGreen.opacity(0.6), radius: 3, x: 0, y: 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
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

    // MARK: - The 6 archetype families (clickable bias map)

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("THE 6 FAMILIES")
            VStack(spacing: 10) {
                ForEach(biasCategories, id: \.name) { category in
                    categoryCard(category)
                }
            }
        }
    }

    private func categoryCard(_ category: BiasCategory) -> some View {
        let isExpanded = expandedCategories.contains(category.name)
        let arch = archetype(for: category.name)
        let isYou = userArchetype == archetypeRawValue(forCategory: category.name)
        return VStack(alignment: .leading, spacing: 0) {
            // Header — tap to expand/collapse
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    if isExpanded {
                        expandedCategories.remove(category.name)
                    } else {
                        expandedCategories.insert(category.name)
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(category.emoji)
                        .font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(arch.name)
                                .font(.system(.headline, weight: .bold))
                                .foregroundStyle(DS.textPrimary)
                            if isYou {
                                Text("← You")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .tracking(0.4)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(DS.heroGradient)
                                    )
                            }
                        }
                        Text(category.name.uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(DS.goldBase)
                        Text(arch.tagline)
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(DS.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(category.patterns.count)")
                            .font(.system(size: 22, weight: .black, design: .serif))
                            .foregroundStyle(DS.goldBase)
                        Text("patterns")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(DS.textTertiary)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.goldBase)
                        .padding(.leading, 4)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded — list of biases in this family
            if isExpanded {
                Divider().padding(.horizontal, 14)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(category.patterns) { pattern in
                        biasMiniRow(pattern)
                    }
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(isYou ? DS.accent : DS.goldBase.opacity(0.3),
                        lineWidth: isYou ? 1.5 : 1)
        )
    }

    /// Compact bias row shown inside an expanded category card. Name + 1
    /// sentence + one-liner citation. No navigation away — keeps the
    /// Education tab as a self-contained map.
    private func biasMiniRow(_ pattern: BiasPattern) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: pattern.sfSymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: pattern.iconColor))
                .frame(width: 24, alignment: .center)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(pattern.displayName)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                Text(pattern.oneLiner)
                    .font(.system(.footnote, weight: .regular))
                    .foregroundStyle(DS.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(pattern.keyRef)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(DS.goldBase)
                    .padding(.top, 1)
            }
        }
    }

    // MARK: - Papers

    private var papersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("THE FOUR PAPERS")
            VStack(spacing: 10) {
                ForEach(papers) { paper in
                    paperCard(paper)
                }
            }
        }
    }

    private func paperCard(_ p: Paper) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.goldBase)
                Text("\(p.author), \(p.year)")
                    .font(.system(.headline, weight: .heavy))
                    .foregroundStyle(DS.textPrimary)
            }
            Text(p.title)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DS.deepGreen)
            Text(p.detail)
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
    }

    // MARK: - BFAS Framework card

    private var frameworkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("THE FRAMEWORK")
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(DS.nuggetGold).frame(width: 40, height: 40)
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 17))
                            .foregroundStyle(DS.goldForeground)
                    }
                    Text("Built on BFAS")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                }
                Text("The same framework professional planners use before giving advice. GoldMind adapts those 16 patterns into a daily awareness practice — not a one-off test.")
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        }
    }

    // MARK: - Ranking explanation (plain English)

    private var howRankingWorks: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("HOW THE RANKING WORKS")
            VStack(alignment: .leading, spacing: 12) {
                bulletRow(1, "Each check-in answer and tagged spend feeds your bias profile.")
                bulletRow(2, "The algorithm ranks biases by how often they show up in your decisions.")
                bulletRow(3, "As you notice them, they move from Active → Aware.")
                bulletRow(4, "Your first BFAS assessment seeds the baseline — daily data overrides it over time.")
            }
            .padding(16)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        }
    }

    private func bulletRow(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(DS.nuggetGold).frame(width: 24, height: 24)
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

    // MARK: - All 16 biases with citations

    private var allBiasesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ALL 16 BIASES")
            VStack(spacing: 8) {
                ForEach(allBiasPatterns) { p in
                    biasRow(p)
                }
            }
        }
    }

    private func biasRow(_ p: BiasPattern) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: p.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.goldBase)
                    .frame(width: 24)
                Text(p.displayName)
                    .font(.system(.subheadline, weight: .heavy))
                    .foregroundStyle(DS.textPrimary)
            }
            Text(p.oneLiner)
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            ResearchFootnote(text: p.keyRef)
                .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.goldBase, lineWidth: 1.5)
        )
    }

    // MARK: - Spot & Overcome

    private var spotAndOvercomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("HOW TO SPOT & OVERCOME")

            NudgeSaysCard(
                message: "Awareness is the first step. Below are practical, research-backed strategies for each bias.",
                citation: "Fischhoff 1982 · Larrick 2004 · Soll et al. 2015",
                surface: .whiteShimmer
            )

            ForEach(BiasLessonsMock.seed, id: \.id) { lesson in
                overcomeCard(lesson)
            }
        }
    }

    private func overcomeCard(_ lesson: BiasLesson) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(lesson.emoji)
                    .font(.system(size: 22))
                Text(lesson.biasName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(DS.goldBase)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HOW TO SPOT IT")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(DS.goldBase)
                        Text(lesson.shortDescription)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(DS.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(DS.accent)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HOW TO OVERCOME IT")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(DS.accent)
                        Text(lesson.howToCounter)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(DS.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 1.5)
        )
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(DS.goldBase)
    }
}
