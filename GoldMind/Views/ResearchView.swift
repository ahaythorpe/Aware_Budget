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
    /// Reused in TWO tabs: the Education tab passes `.learn` to show
    /// personalities + quiz + your progress; the Research tab passes
    /// `.reference` to show papers + framework + ranking + all biases +
    /// counteract guide. Defaults to `.learn` so existing call sites work.
    enum Mode { case learn, reference }
    var mode: Mode = .learn

    /// Tracks which archetype cards are currently expanded. Multiple can
    /// be open at once so the user can compare families.
    @State private var expandedCategories: Set<String> = []

    // Awareness / Your Progress state (folded in from AwarenessView when
    // mode == .learn). Loaded once via .task; falls back gracefully if
    // the fetch fails (Education still renders the personalities).
    @State private var biasProgress: [BiasProgress] = []
    @State private var eventTagCounts: [String: Int] = [:]

    /// User's archetype from `profiles.archetype` (Money Mind Quiz result).
    /// Drives the "← You" tag on the matching category card and the
    /// "Take the quiz" CTA. Loaded once on appear.
    @State private var userArchetype: String? = nil
    @State private var showQuiz: Bool = false

    /// Bias IDs the user has tapped open inside an expanded category card.
    /// Used for the "Tap to see Nudge's take" interaction so each bias
    /// can flip between a one-liner and a longer Nudge note.
    @State private var revealedBiases: Set<UUID> = []

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
              detail: "Codifies the BFAS framework GoldMind uses: 16 patterns, behavioural investor types, used by professional financial planners."),
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
                if mode == .learn {
                    quizCTA
                    categoriesSection
                    yourProgressSection
                } else {
                    papersSection
                    frameworkSection
                    howRankingWorks
                    allBiasesSection
                    spotAndOvercomeSection
                }
                Spacer(minLength: 32)
            }
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 12)
        }
        .background(DS.bg.ignoresSafeArea())
        .navigationTitle(mode == .learn ? "Education" : "Research")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadArchetype()
            if mode == .learn {
                await loadProgress()
            }
        }
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

    // MARK: - Bias chip fold-ups (Patterns A + C)

    /// Maps a category name to the matching Archetype rawValue so the
    /// "Why this fits" lookup hits the ArchetypeBiasExplanation table.
    /// Returns nil for unknown categories.
    private func archetypeRawValueForExplanation(category: String) -> String? {
        switch category {
        case "Avoidance":         return "Drifter"
        case "Decision Making":   return "Reactor"
        case "Money Psychology":  return "Bookkeeper"
        case "Time Perception":   return "Now"
        case "Social":            return "Bandwagon"
        case "Defaults & Habits": return "Autopilot"
        default:                  return nil
        }
    }

    /// 2nd-level fold-up explaining why this bias fits the parent
    /// personality. Shows under the Nudge note when the user has tapped
    /// the bias open inside an expanded personality card.
    private func whyFitsRow(archetype: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WHY THIS FITS \(archetype.uppercased())S")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.goldBase)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.heroGradient.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DS.accent.opacity(0.25), lineWidth: 1)
        )
    }

    /// Horizontally-scrolling row of sibling-bias chips. Tap a chip to
    /// expand that bias inline (it appears below the current row in the
    /// parent VStack since they share `revealedBiases`).
    private func relatedRow(_ siblings: [BiasPattern]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RELATED")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(siblings) { sib in
                        Button {
                            let anim: Animation = .spring(response: 0.32, dampingFraction: 0.85)
                            withAnimation(anim) {
                                revealedBiases.insert(sib.id)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sib.sfSymbol)
                                    .font(.system(size: 10, weight: .bold))
                                Text(sib.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .heavy))
                            }
                            .foregroundStyle(DS.goldBase)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().stroke(DS.goldBase.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Your Progress (folded in from AwarenessView)

    /// Returns the user's triggered biases — those with any check-in
    /// progress OR any tagged money event this month. Mirrors the
    /// awareness-score logic so Education tab matches what Home shows.
    private var triggeredBiases: [BiasPattern] {
        allBiasPatterns.filter { p in
            let progressed = biasProgress.first(where: { $0.biasName == p.name })?.timesEncountered ?? 0
            let tagged = eventTagCounts[p.name] ?? 0
            return progressed + tagged > 0
        }
    }

    /// Section that surfaces the user's own progress inside Education so
    /// they don't need a separate Awareness tab. Shows a count vs 16 plus
    /// the top 5 most-triggered biases. Quietly disappears if the user
    /// has nothing logged yet — keeps Education calm for new users.
    @ViewBuilder private var yourProgressSection: some View {
        if !triggeredBiases.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("YOUR PROGRESS")
                progressCard
            }
        }
    }

    private var progressCard: some View {
        let count = triggeredBiases.count
        let pct = Double(count) / 16.0
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(DS.mintBg, lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: CGFloat(pct))
                        .stroke(DS.goldBase, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    Text("\(count)/16")
                        .font(.system(size: 13, weight: .black, design: .serif))
                        .foregroundStyle(DS.goldBase)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(Int(pct * 100))% identified")
                        .font(.system(size: 20, weight: .black, design: .serif))
                        .foregroundStyle(DS.textPrimary)
                    Text("Patterns you've started to notice")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.textSecondary)
                }
                Spacer(minLength: 0)
            }

            if triggeredBiases.count > 0 {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOP PATTERNS FOR YOU")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(DS.accent)
                    ForEach(Array(triggeredBiases.sorted { triggerCount(for: $0) > triggerCount(for: $1) }.prefix(5))) { p in
                        HStack(spacing: 10) {
                            Image(systemName: p.sfSymbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: p.iconColor))
                                .frame(width: 22)
                            Text(p.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DS.textPrimary)
                            Spacer()
                            Text("×\(triggerCount(for: p))")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(DS.goldBase)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.3), lineWidth: 1)
        )
    }

    private func triggerCount(for p: BiasPattern) -> Int {
        let progressed = biasProgress.first(where: { $0.biasName == p.name })?.timesEncountered ?? 0
        let tagged = eventTagCounts[p.name] ?? 0
        return progressed + tagged
    }

    /// Loads bias progress + this-month tag counts. Mirrors HomeViewModel
    /// so the Education progress section uses the same source of truth.
    private func loadProgress() async {
        let progress = (try? await SupabaseService.shared.fetchBiasProgress()) ?? []
        let events = (try? await SupabaseService.shared.fetchMoneyEvents(forMonth: Date())) ?? []
        let counts: [String: Int] = events
            .compactMap(\.behaviourTag)
            .reduce(into: [:]) { c, tag in c[tag, default: 0] += 1 }
        await MainActor.run {
            self.biasProgress = progress
            self.eventTagCounts = counts
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
                        Text("Find your spending personality · 2 min")
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

            Text("The 16 patterns behind your decisions, grouped into six families, with the science to back them.")
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

    // MARK: - The 6 spending personalities (clickable bias map)

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("THE 6 SPENDING PERSONALITIES")
            NudgeSaysCard(
                message: "These six personalities come from how you answer the Money Mind quiz. Each is scored across all 16 underlying biases. Most people are a blend; the quiz surfaces the strongest signal.",
                citation: "BFAS · Pompian, 2012",
                surface: .whiteShimmer
            )
            VStack(spacing: 10) {
                ForEach(biasCategories, id: \.name) { category in
                    categoryCard(category)
                }
            }
        }
    }

    /// Per-personality icon + tint. Replaces the flat default emojis with
    /// a gold-circled SF Symbol that matches the canonical Archetype enum,
    /// so the visual identity carries across Education + Home + Reveal.
    private func personalityIcon(forCategory name: String) -> (symbol: String, tint: Color) {
        switch name {
        case "Avoidance":         return ("eye.slash.circle.fill", Color(hex: "E65100"))
        case "Decision Making":   return ("bolt.fill",              Color(hex: "C62828"))
        case "Money Psychology":  return ("tray.2.fill",             Color(hex: "4527A0"))
        case "Time Perception":   return ("hourglass",               Color(hex: "880E4F"))
        case "Social":            return ("person.2.wave.2.fill",    Color(hex: "7B1FA2"))
        case "Defaults & Habits": return ("repeat.circle.fill",      Color(hex: "E65100"))
        default:                  return ("circle.fill",              DS.goldBase)
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
                let icon = personalityIcon(forCategory: category.name)
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(icon.tint.opacity(0.12))
                        Circle()
                            .stroke(icon.tint.opacity(0.35), lineWidth: 1)
                        Image(systemName: icon.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(icon.tint)
                    }
                    .frame(width: 44, height: 44)
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
                        biasMiniRow(pattern, categoryName: category.name)
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

    /// Compact bias row shown inside an expanded category card. Tap to
    /// flip between the one-line definition and Nudge's longer
    /// contextual note (from BiasPattern.nudgeSays). Keeps Education
    /// self-contained — no navigation away.
    private func biasMiniRow(_ pattern: BiasPattern, categoryName: String = "") -> some View {
        let isRevealed = revealedBiases.contains(pattern.id)
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                if isRevealed { revealedBiases.remove(pattern.id) }
                else          { revealedBiases.insert(pattern.id) }
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: pattern.iconBg))
                    Image(systemName: pattern.sfSymbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: pattern.iconColor))
                }
                .frame(width: 32, height: 32)
                .padding(.top, 1)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(pattern.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DS.textPrimary)
                        Spacer(minLength: 0)
                        Image(systemName: isRevealed ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(DS.goldBase)
                    }
                    if isRevealed {
                        Text(pattern.nudgeSays)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.textPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        // Pattern C — "Why this fits [archetype]" 2nd-level
                        // fold-up. Only shows when we have explanation copy
                        // for this archetype × bias pair AND we know the
                        // current category context.
                        if let arch = archetypeRawValueForExplanation(category: categoryName),
                           let why = ArchetypeBiasExplanation.text(forArchetype: arch, bias: pattern.name) {
                            whyFitsRow(archetype: arch, text: why)
                                .padding(.top, 4)
                        }

                        // Pattern A — RELATED chips. Tap a sibling to
                        // expand it inline below the current row.
                        let siblings = BiasRelationships.relatedBiases(for: pattern.name)
                        if !siblings.isEmpty {
                            relatedRow(siblings)
                                .padding(.top, 6)
                        }
                    } else {
                        Text(pattern.oneLiner)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(DS.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(pattern.keyRef)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(DS.goldBase.opacity(0.85))
                        .padding(.top, 2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isRevealed ? DS.paleGreen.opacity(0.4) : Color.clear)
            )
        }
        .buttonStyle(.plain)
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
                Text("The same framework professional planners use before giving advice. GoldMind adapts those 16 patterns into a daily awareness practice, not a one-off test.")
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
                bulletRow(4, "Your first BFAS assessment seeds the baseline. Daily data overrides it over time.")
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
            sectionLabel("HOW TO COUNTERACT YOUR BIASES")

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
