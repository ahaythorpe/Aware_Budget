import SwiftUI

struct LearnView: View {
    @State private var allLessons: [BiasLesson] = []
    @State private var selectedCategory: String = "All"
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var biasProgress: [BiasProgress] = []
    @State private var allEvents: [MoneyEvent] = []
    @State private var showGlossary = false

    private let categories: [String] = [
        "All",
        "Avoidance",
        "Decision Making",
        "Money Psychology",
        "Time Perception",
        "External Influence",
        "Self Perception",
    ]

    private let frontBorder = DS.accent.opacity(0.25)
    private let backBg = DS.mintBg
    private let cardHeight: CGFloat = 340

    private var filteredLessons: [BiasLesson] {
        guard selectedCategory != "All" else { return allLessons }
        return allLessons.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    topFiveSection
                    glossaryCard
                    filterPillRow
                    if filteredLessons.isEmpty {
                        emptyState
                    } else {
                        cardStack
                        swipeCounter
                    }
                    if filteredLessons.count > 1 {
                        dotIndicator
                            .padding(.bottom, 20)
                    }
                }
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showGlossary = true } label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(DS.textTertiary)
                }
            }
        }
        .sheet(isPresented: $showGlossary) {
            biasGlossarySheet
        }
        .task {
            if allLessons.isEmpty {
                allLessons = BiasLessonsMock.seed
            }
            biasProgress = (try? await SupabaseService.shared.fetchBiasProgress()) ?? []
            allEvents = (try? await SupabaseService.shared.fetchAllMoneyEvents()) ?? []
        }
        .onChange(of: selectedCategory) { _, _ in
            currentIndex = 0
            dragOffset = .zero
        }
        .navigationDestination(for: BiasLesson.self) { lesson in
            BiasDetailView(lesson: lesson)
        }
    }

    // MARK: - Glossary card (grouped by category)

    private var glossaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("16 patterns. One line each.")
                .font(.headline.weight(.bold))
                .foregroundStyle(DS.textPrimary)
                .padding(.horizontal, DS.hPadding)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(BiasLessonsMock.categoryOrder, id: \.self) { category in
                    let lessons = allLessons.filter { $0.category == category }
                    if !lessons.isEmpty {
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(DS.accent)
                            .tracking(1.5)
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .padding(.bottom, 4)

                        ForEach(lessons) { lesson in
                            NavigationLink(value: lesson) {
                                HStack(spacing: 10) {
                                    Text(lesson.emoji)
                                        .font(.title3)
                                        .frame(width: 28)
                                    Text(lesson.displayName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DS.textPrimary)
                                    Spacer()
                                    Text(lesson.shortDescription)
                                        .font(.caption)
                                        .foregroundStyle(DS.textSecondary)
                                        .lineLimit(1)
                                        .frame(maxWidth: 120, alignment: .trailing)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                            .stroke(DS.paleGreen, lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, DS.hPadding)
        }
    }

    // MARK: - Top 5 ranked section

    private var topFiveRanked: [(rank: Int, lesson: BiasLesson, progress: BiasProgress, score: BiasScore, linkedAmount: Double)] {
        let emojiLookup = Dictionary(uniqueKeysWithValues: allLessons.map { ($0.biasName, $0) })
        let eventsByTag = Dictionary(grouping: allEvents.filter { $0.behaviourTag != nil }, by: { $0.behaviourTag! })

        return biasProgress
            .filter { $0.timesEncountered > 0 }
            .sorted { $0.timesEncountered > $1.timesEncountered }
            .prefix(5)
            .enumerated()
            .compactMap { index, bp in
                guard let lesson = emojiLookup[bp.biasName] else { return nil }
                let score = BiasScoreService.computeScore(biasName: bp.biasName, progress: bp, taggedEvents: 0)
                let linked = eventsByTag[bp.biasName]?.reduce(0.0) { $0 + $1.amount } ?? 0
                return (rank: index + 1, lesson: lesson, progress: bp, score: score, linkedAmount: linked)
            }
    }

    private var topFiveSection: some View {
        Group {
            if !topFiveRanked.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(spacing: 10) {
                        ForEach(topFiveRanked, id: \.lesson.id) { item in
                            NavigationLink(value: item.lesson) {
                                rankedBiasCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DS.hPadding)
                }
            }
        }
    }

    private func rankedBiasCard(_ item: (rank: Int, lesson: BiasLesson, progress: BiasProgress, score: BiasScore, linkedAmount: Double)) -> some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(item.rank)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(DS.goldText)
                .frame(width: 28)

            // Emoji
            Text(item.lesson.emoji)
                .font(.title2)

            // Name + details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.lesson.biasName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.textPrimary)

                HStack(spacing: 8) {
                    Text("\(item.progress.timesEncountered)× triggered")
                        .font(.caption)
                        .foregroundStyle(DS.textSecondary)

                    if item.linkedAmount > 0 {
                        Text("$\(Int(item.linkedAmount)) linked")
                            .font(.caption)
                            .foregroundStyle(DS.textSecondary)
                    }
                }

                Text(biasResearchCitation(for: item.lesson.biasName))
                    .font(.system(size: 9))
                    .italic()
                    .foregroundStyle(DS.textTertiary)
            }

            Spacer()

            // Trend badge
            VStack(spacing: 4) {
                Text(item.score.trend == .improving ? "↓" : (item.score.trend == .worsening ? "↑" : "→"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(trendColor(item.score.trend))
                Text(item.score.trend == .improving ? "Improving" : (item.score.trend == .worsening ? "Worsening" : "Stable"))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(trendColor(item.score.trend))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(trendColor(item.score.trend).opacity(0.1))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
    }

    private func trendColor(_ trend: BiasTrend) -> Color {
        switch trend {
        case .improving: return DS.primary
        case .worsening: return DS.stageActive
        case .stable: return DS.textSecondary
        }
    }

    private func biasResearchCitation(for bias: String) -> String {
        switch bias {
        case "Loss Aversion": return "Kahneman & Tversky, 1979"
        case "Present Bias": return "O'Donoghue & Rabin, 1999"
        case "Anchoring": return "Tversky & Kahneman, 1974"
        case "Overconfidence Bias": return "Barber & Odean, 2001"
        case "Mental Accounting": return "Thaler, 1985"
        case "Status Quo Bias": return "Samuelson & Zeckhauser, 1988"
        case "Ostrich Effect": return "Karlsson et al., 2009"
        case "Sunk Cost Fallacy": return "Arkes & Blumer, 1985"
        case "Ego Depletion": return "Baumeister et al., 1998"
        case "Availability Heuristic": return "Tversky & Kahneman, 1973"
        case "Denomination Effect": return "Raghubir & Srivastava, 2009"
        case "Framing Effect": return "Tversky & Kahneman, 1981"
        case "Planning Fallacy": return "Buehler, Griffin & Ross, 1994"
        case "Bandwagon Effect": return "Cialdini, 1984"
        case "Moral Licensing": return "Monin & Miller, 2001"
        case "Social Proof": return "Cialdini, 1984"
        default: return "Pompian, 2012"
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Understanding your money mind")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(DS.textPrimary)
            Text("Your top 5 patterns ranked by impact")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - Filter pills (compact)

    private var filterPillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(categories, id: \.self) { cat in
                    filterPill(cat)
                }
            }
            .padding(.horizontal, DS.hPadding)
        }
    }

    private func filterPill(_ cat: String) -> some View {
        let selected = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = cat
            }
        } label: {
            Text(cat)
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(selected ? DS.darkGreen : DS.cardBg)
                )
                .foregroundStyle(selected ? .white : DS.textPrimary)
                .overlay(
                    Capsule().stroke(selected ? .clear : DS.accent, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // Category tile colours per PRD v1.1
    static func categoryColour(for category: String) -> (bg: Color, text: Color) {
        switch category {
        case "Avoidance":
            return (Color(hex: "E1F5EE"), Color(hex: "085041"))
        case "Decision Making":
            return (DS.paleGreen, DS.primary)
        case "Money Psychology":
            return (Color(hex: "FAEEDA"), Color(hex: "412402"))
        case "Time Perception":
            return (Color(hex: "F3E5F5"), Color(hex: "4A148C"))
        case "External Influence":
            return (Color(hex: "FAECE7"), Color(hex: "4A1B0C"))
        case "Self Perception":
            return (Color(hex: "E0F7FA"), Color(hex: "006064"))
        case "Inertia":
            return (Color(hex: "FBE9E7"), Color(hex: "BF360C"))
        default:
            return (DS.paleGreen, DS.darkGreen)
        }
    }

    // MARK: - Bias glossary sheet

    private var biasGlossarySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(allLessons) { lesson in
                        NavigationLink(value: lesson) {
                            HStack(spacing: 12) {
                                Text(lesson.emoji)
                                    .font(.title3)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lesson.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DS.textPrimary)
                                    Text(lesson.shortDescription)
                                        .font(.caption)
                                        .foregroundStyle(DS.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if let stage = masteryStage(for: lesson.biasName), stage != .unseen {
                                    Text(stage.rawValue)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(stageColor(stage)))
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(DS.textTertiary)
                            }
                            .padding(.horizontal, DS.hPadding)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 60)
                    }
                }
                .padding(.top, 8)
            }
            .background(DS.bg.ignoresSafeArea())
            .navigationTitle("All 16 biases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showGlossary = false }
                        .foregroundStyle(DS.accent)
                }
            }
            .navigationDestination(for: BiasLesson.self) { lesson in
                BiasDetailView(lesson: lesson)
            }
        }
    }

    // MARK: - Mastery stage helpers

    private func masteryStage(for biasName: String) -> MasteryStage? {
        guard let progress = biasProgress.first(where: { $0.biasName == biasName }) else {
            return nil
        }
        let score = BiasScoreService.computeScore(
            biasName: biasName,
            progress: progress,
            taggedEvents: 0
        )
        return score.masteryStage
    }

    private func stageColor(_ stage: MasteryStage) -> Color {
        switch stage {
        case .unseen:    return DS.textTertiary
        case .noticed:   return DS.stageNoticed
        case .emerging:  return DS.stageEmerging
        case .active:    return DS.warning
        case .improving: return DS.accent
        case .aware:     return DS.goldBase
        }
    }

    // MARK: - Card stack (1 back card only)

    private var cardStack: some View {
        ZStack {
            if currentIndex + 1 < filteredLessons.count {
                cardBase(fill: backBg)
                    .scaleEffect(0.96)
                    .offset(y: 10)
            }
            if currentIndex < filteredLessons.count {
                frontCard(filteredLessons[currentIndex])
                    .offset(x: dragOffset.width)
                    .rotationEffect(.degrees(Double(dragOffset.width / 30)))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = CGSize(width: value.translation.width, height: 0)
                            }
                            .onEnded { value in
                                if value.translation.width < -80 {
                                    advance(direction: -1)
                                } else if value.translation.width > 80 {
                                    advance(direction: 1)
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        dragOffset = .zero
                                    }
                                }
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .padding(.horizontal, DS.hPadding)
    }

    private func cardBase(fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(fill)
            .frame(height: cardHeight)
    }

    private func frontCard(_ lesson: BiasLesson) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(frontBorder, lineWidth: 0.5)
                )

            // Mastery stage badge
            if let stage = masteryStage(for: lesson.biasName), stage != .unseen {
                Text(stage.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(stageColor(stage))
                    )
                    .padding(12)
            }

            VStack(spacing: 0) {
                // Emoji in coloured circle
                ZStack {
                    Circle()
                        .fill(Self.categoryColour(for: lesson.category).bg)
                        .frame(width: 80, height: 80)
                    Text(lesson.emoji)
                        .font(.system(size: 40))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 18)

                // Category pill centred
                categoryPill(lesson.category)
                    .padding(.top, 10)

                // Bias name
                Text(lesson.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.darkGreen)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                // Short description
                Text(lesson.shortDescription)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .padding(.horizontal, 8)

                // Divider with breathing room
                Divider()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)

                // In real life
                Text("IN REAL LIFE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.accent)
                    .tracking(0.8)

                Text(lesson.realWorldExample)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DS.paleGreen)
                    )
                    .padding(.horizontal, 8)
                    .padding(.top, 4)

                Spacer(minLength: 0)

                // Two side-by-side buttons
                HStack(spacing: 10) {
                    NavigationLink(value: lesson) {
                        Text("Learn more")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.darkGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(DS.darkGreen, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: lesson) {
                        Text("How to counter it")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(DS.darkGreen)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: cardHeight)
    }

    private func categoryPill(_ cat: String) -> some View {
        let colours = Self.categoryColour(for: cat)
        return Text(cat)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(colours.bg))
            .foregroundStyle(colours.text)
    }

    // MARK: - Swipe counter

    private var swipeCounter: some View {
        Text("\(currentIndex + 1) of \(filteredLessons.count)")
            .font(.caption)
            .foregroundStyle(DS.textTertiary)
    }

    // MARK: - Dot indicator

    private var dotIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<filteredLessons.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentIndex = i
                        dragOffset = .zero
                    }
                } label: {
                    Circle()
                        .fill(i == currentIndex ? DS.darkGreen : DS.textTertiary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(DS.textTertiary)
            Text("No biases in this category")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
        }
        .padding(32)
    }

    // MARK: - Actions

    private func advance(direction: Int) {
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: CGFloat(direction) * -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if direction > 0 {
                currentIndex = (currentIndex + 1) % max(filteredLessons.count, 1)
            } else {
                currentIndex = (currentIndex - 1 + filteredLessons.count) % max(filteredLessons.count, 1)
            }
            dragOffset = .zero
        }
    }
}

#Preview {
    NavigationStack { LearnView() }
}
