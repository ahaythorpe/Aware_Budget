import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var viewModel = MoneyEventViewModel()
    @State private var rangeSheetCategory: SpendCategory? = nil
    @State private var sessionLog: [SessionEntry] = []
    @State private var showSessionSummary: Bool = false
    var selectedTab: Binding<RootTab>? = nil

    struct SessionEntry: Identifiable {
        let id = UUID()
        let emoji: String
        let category: String
        let amountLabel: String
        let amount: Double
        let plannedStatus: MoneyEvent.PlannedStatus
        let behaviourTag: String?
    }

    private var sessionTotal: Double { sessionLog.reduce(0.0) { $0 + $1.amount } }

    private let tileColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            if showSessionSummary {
                sessionSummary
            } else if viewModel.didSave, let nudge = viewModel.nudgeResponse {
                savedConfirmation(nudge)
            } else {
                ScrollView {
                    VStack(spacing: DS.sectionGap) {
                        headerSection
                        if !sessionLog.isEmpty {
                            sessionBanner
                        }
                        categoryGrid
                        if viewModel.selectedRange != nil {
                            plannedStatusPicker
                        }
                        if viewModel.plannedStatus != nil {
                            biasTagSection
                        }
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(DS.warning)
                        }
                        if viewModel.canSave {
                            saveButton
                        }
                    }
                    .padding(.horizontal, DS.hPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.selectedCategory?.name)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.selectedRange?.label)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.plannedStatus)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            if isPresented {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.didSave ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(DS.textPrimary)
                }
            }
        }
        .sheet(item: $rangeSheetCategory) { cat in
            rangeSheet(for: cat)
                .presentationDetents([.height(440)])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick log")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(DS.textPrimary)
            Text("Tap what you spent on. Log at your own pace — patterns show up over time.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ResearchFootnote(text: "Powered by the BFAS framework · Pompian, 2012", style: .pill)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Saved confirmation (with multi-log session affordance)

    private func savedConfirmation(_ nudge: NudgeMessage) -> some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DS.paleGreen)
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(DS.darkGreen)
            }

            if let cat = viewModel.selectedCategory, let range = viewModel.selectedRange {
                VStack(spacing: 4) {
                    Text("Logged")
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text("\(cat.emoji) \(cat.name) · \(range.label)")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(DS.textSecondary)
                }
            }

            NudgeSaysCard(message: nudge.body, surface: .whiteShimmer)
                .padding(.horizontal, DS.hPadding)

            VStack(spacing: 10) {
                Button {
                    captureSessionEntry()
                    viewModel.reset()
                } label: {
                    Text("Add another →")
                }
                .goldButtonStyle()

                Button {
                    captureSessionEntry()
                    viewModel.reset()
                    showSessionSummary = true
                } label: {
                    Text("Done with session")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DS.deepGreen)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DS.hPadding)

            Spacer()
        }
        .transition(.opacity)
    }

    // Append the just-saved event to the local session log.
    private func captureSessionEntry() {
        guard let cat = viewModel.selectedCategory,
              let range = viewModel.selectedRange,
              let status = viewModel.plannedStatus else { return }
        sessionLog.append(SessionEntry(
            emoji: cat.emoji,
            category: cat.name,
            amountLabel: range.label,
            amount: range.midpoint,
            plannedStatus: status,
            behaviourTag: viewModel.behaviourTag
        ))
    }

    // MARK: - Session banner (appears on grid when session has entries)

    private var sessionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(DS.goldBase)
            Text("\(sessionLog.count) logged · $\(Int(sessionTotal))")
                .font(.system(.subheadline, weight: .heavy))
                .foregroundStyle(DS.textPrimary)
            Spacer()
            Button {
                showSessionSummary = true
            } label: {
                Text("See summary")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(DS.deepGreen)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
        .shimmeringGoldBorder(cornerRadius: 12)
    }

    // MARK: - Session summary (end-of-session screen)

    private var sessionSummary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session summary")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text("\(sessionLog.count) event\(sessionLog.count == 1 ? "" : "s") · $\(Int(sessionTotal)) total")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }

                VStack(spacing: 8) {
                    ForEach(sessionLog) { entry in
                        sessionRow(entry)
                    }
                }

                if !topSessionBiases.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PATTERNS TRIGGERED")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(DS.goldBase)
                        ForEach(topSessionBiases, id: \.0) { name, count in
                            HStack {
                                Text(name)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(DS.textPrimary)
                                Spacer()
                                Text("×\(count)")
                                    .font(.system(.footnote, weight: .heavy))
                                    .foregroundStyle(DS.deepGreen)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(14)
                    .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .shimmeringGoldBorder(cornerRadius: 12)
                }

                NudgeSaysCard(message: sessionNudgeMessage, surface: .whiteShimmer)

                Button {
                    sessionLog.removeAll()
                    showSessionSummary = false
                    if isPresented { dismiss() } else { selectedTab?.wrappedValue = .home }
                } label: {
                    Text("Back to Home →")
                }
                .goldButtonStyle()
                .padding(.bottom, 24)
            }
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 16)
        }
    }

    private func sessionRow(_ entry: SessionEntry) -> some View {
        HStack(spacing: 12) {
            Text(entry.emoji).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                Text(entry.plannedStatus.label)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(DS.textTertiary)
            }
            Spacer()
            Text(entry.amountLabel)
                .font(.system(.subheadline, weight: .heavy))
                .foregroundStyle(DS.goldBase)
        }
        .padding(12)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var topSessionBiases: [(String, Int)] {
        let tags = sessionLog.compactMap(\.behaviourTag)
        let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
        return counts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    private var sessionNudgeMessage: String {
        if let top = topSessionBiases.first {
            return "Most logged pattern: \(top.0). Worth a look in your bias profile."
        } else if sessionLog.count >= 3 {
            return "Three or more events in one session — that's the noticing muscle building."
        } else {
            return "Logged. Patterns show up over time."
        }
    }

    // MARK: - Category grid (16 gold tiles)

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: tileColumns, spacing: 10) {
                ForEach(spendCategories) { cat in
                    categoryTile(cat)
                }
            }
            ResearchFootnote(
                text: "Ranges based on ABS Household Expenditure Survey 2022–23",
                icon: "chart.bar.doc.horizontal"
            )
            .padding(.top, 2)
        }
    }

    private func categoryTile(_ cat: SpendCategory) -> some View {
        let isSelected = viewModel.selectedCategory?.name == cat.name
        return Button {
            rangeSheetCategory = cat
        } label: {
            VStack(spacing: 6) {
                Text(cat.emoji)
                    .font(.system(size: 30))
                Text(cat.name)
                    .font(.system(.caption, weight: .heavy))
                    .foregroundStyle(isSelected ? DS.goldForeground : DS.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 104)
            .padding(.vertical, 4)
            .background(
                isSelected ? AnyShapeStyle(DS.nuggetGold) : AnyShapeStyle(DS.cardBg),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? DS.goldBase.opacity(0.5) : DS.accent.opacity(0.15), lineWidth: isSelected ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Range sheet (popup)

    private func rangeSheet(for cat: SpendCategory) -> some View {
        let ranges = categoryRanges[cat.name] ?? []
        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(cat.emoji).font(.system(size: 40))
                Text(cat.name)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                Text("How much?")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(DS.accent)
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                ForEach(ranges) { range in
                    Button {
                        viewModel.selectedCategory = cat
                        viewModel.selectedRange = range
                        viewModel.plannedStatus = nil
                        viewModel.behaviourTag = nil
                        rangeSheetCategory = nil
                    } label: {
                        Text(range.label)
                            .font(.system(.headline, weight: .bold))
                            .foregroundStyle(DS.goldForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(DS.nuggetGold, in: Capsule())
                            .overlay(Capsule().stroke(DS.goldBase.opacity(0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: viewModel.selectedRange?.label == range.label)
                }
            }
            .padding(.horizontal, 20)

            if let avg = absMonthlyAverage[cat.name] {
                ResearchFootnote(text: "Avg $\(avg)/mo · ABS 2022–23", icon: "chart.bar.doc.horizontal")
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .background(DS.cardBg)
    }

    // MARK: - Planned / Surprise / Impulse

    private var plannedStatusPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WAS THIS PLANNED?")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.goldBase)
            VStack(spacing: 12) {
                ForEach(MoneyEvent.PlannedStatus.allCases) { status in
                    plannedPill(status)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func plannedPill(_ status: MoneyEvent.PlannedStatus) -> some View {
        let selected = viewModel.plannedStatus == status
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.plannedStatus = status
                viewModel.onPlannedStatusSet()
            }
        } label: {
            HStack(spacing: 10) {
                Text(status.emoji)
                    .font(.system(size: 20))
                Text(status.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(selected ? DS.goldForeground : DS.goldForeground)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.goldForeground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(selected ? AnyShapeStyle(DS.nuggetGold) : AnyShapeStyle(DS.goldSurfaceBg))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(selected ? DS.goldBase.opacity(0.6) : DS.goldSurfaceStroke, lineWidth: selected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Bias tag section

    private var biasTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT'S DRIVING THIS?")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.goldBase)
            ResearchFootnote(text: "BFAS framework · Grable & Joo, 2004")

            if let tag = viewModel.behaviourTag {
                HStack(spacing: 10) {
                    Text(tag)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.goldText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(DS.goldBase.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
                        )

                    if viewModel.suggestedTag == tag {
                        Text("suggested")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(DS.textTertiary)
                    }
                }

                if let inline = viewModel.nudgeInline {
                    NudgeSaysCard(
                        message: inline,
                        surface: .whiteShimmer
                    )
                }

                if let insight = driverInsights[tag] {
                    driverInsightCard(tag: tag, insight: insight)
                        .transition(.move(edge: .top).combined(with: .opacity))

                    ResearchFootnote(text: biasCitation(for: tag))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func driverInsightCard(tag: String, insight: DriverInsight) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DS.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WHAT THIS MEANS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.accent)
                        .tracking(1)
                    Text(insight.means)
                        .font(.subheadline)
                        .foregroundStyle(DS.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("HOW TO BREAK IT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.goldText)
                        .tracking(1)
                    Text(insight.fix)
                        .font(.subheadline)
                        .foregroundStyle(DS.textPrimary)
                }

                Button {
                    selectedTab?.wrappedValue = .insights
                } label: {
                    Text("See your \(tag) pattern \u{2192}")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(DS.paleGreen)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shimmeringGoldBorder(cornerRadius: 12)
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView().tint(DS.goldForeground)
                } else {
                    Text("Log it")
                        .font(.headline.weight(.bold))
                }
            }
            .goldButtonStyle()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Bias citations

    private func biasCitation(for bias: String) -> String {
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
        case "Planning Fallacy": return "Kahneman & Tversky, 1979"
        case "Scarcity Heuristic": return "Cialdini, 1984"
        case "Moral Licensing": return "Merritt et al., 2010"
        case "Herd Behaviour": return "Banerjee, 1992"
        default: return "Pompian, 2012"
        }
    }

}

#Preview {
    NavigationStack { MoneyEventView() }
}
