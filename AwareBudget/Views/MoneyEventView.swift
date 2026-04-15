import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var viewModel = MoneyEventViewModel()
    @State private var rangeSheetCategory: SpendCategory? = nil
    var selectedTab: Binding<RootTab>? = nil

    private let tileColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            if viewModel.didSave, let nudge = viewModel.nudgeResponse {
                savedConfirmation(nudge)
            } else {
                ScrollView {
                    VStack(spacing: DS.sectionGap) {
                        headerSection
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
                .presentationDetents([.height(340)])
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

    // MARK: - Saved confirmation

    private func savedConfirmation(_ nudge: NudgeMessage) -> some View {
        VStack(spacing: 24) {
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
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DS.textPrimary)
                    Text("\(cat.emoji) \(cat.name) · \(range.label)")
                        .font(.subheadline)
                        .foregroundStyle(DS.textSecondary)
                }
            }

            NudgeCardView(message: nudge)

            Button("Done") {
                    if isPresented {
                        dismiss()
                    } else {
                        viewModel.reset()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DS.hPadding)

            Spacer()
        }
        .transition(.opacity)
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
                    HStack(alignment: .top, spacing: 10) {
                        NudgeAvatar(size: 28)
                        Text(inline)
                            .font(.system(size: 13))
                            .foregroundStyle(DS.textSecondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.paleGreen)
                    )
                }

                if let insight = driverInsights[tag] {
                    driverInsightCard(tag: tag, insight: insight)
                        .transition(.move(edge: .top).combined(with: .opacity))

                    Text(biasCitation(for: tag))
                        .font(.system(size: 9))
                        .italic()
                        .foregroundStyle(DS.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
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
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
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
