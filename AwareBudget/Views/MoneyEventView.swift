import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var viewModel = MoneyEventViewModel()
    var selectedTab: Binding<RootTab>? = nil

    @State private var showAllCategories = false
    private let topColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]
    private let moreColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            if viewModel.didSave, let nudge = viewModel.nudgeResponse {
                savedConfirmation(nudge)
            } else {
                ScrollView {
                    VStack(spacing: DS.sectionGap) {
                        categoryGrid
                        if viewModel.selectedCategory != nil {
                            rangePicker
                        }
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
        .navigationTitle(viewModel.didSave ? "" : "Quick log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isPresented {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.didSave ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
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
                    .foregroundStyle(Color(hex: "1A5C38"))
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

    // MARK: - Category grid

    private let topSix = Array(spendCategories.prefix(6))
    private let remaining = Array(spendCategories.dropFirst(6))

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What did you spend on?")
            LazyVGrid(columns: topColumns, spacing: 8) {
                ForEach(topSix) { cat in
                    categoryCell(cat)
                }
            }
            if showAllCategories {
                LazyVGrid(columns: moreColumns, spacing: 8) {
                    ForEach(remaining) { cat in
                        categoryCell(cat)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showAllCategories = true
                    }
                } label: {
                    Text("More categories \u{2193}")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectCategory(_ cat: SpendCategory) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewModel.selectedCategory = cat
            viewModel.selectedRange = nil
            viewModel.plannedStatus = nil
            viewModel.behaviourTag = nil
        }
    }

    private func categoryCell(_ cat: SpendCategory) -> some View {
        let selected = viewModel.selectedCategory?.name == cat.name
        return Button {
            selectCategory(cat)
        } label: {
            VStack(spacing: 6) {
                Text(cat.emoji)
                    .font(.system(size: 28))
                Text(cat.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(selected ? .white : DS.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.clear : DS.accent.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Range picker

    private var rangePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How much?")
            if let cat = viewModel.selectedCategory,
               let avg = absMonthlyAverage[cat.name] {
                Text("Avg: $\(avg)/mo \u{00B7} ABS 2022\u{2013}23")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(DS.textTertiary)
            }
            VStack(spacing: 10) {
                ForEach(viewModel.availableRanges) { range in
                    rangeButton(range)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func rangeButton(_ range: AmountRange) -> some View {
        let selected = viewModel.selectedRange?.label == range.label
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedRange = range
            }
        } label: {
            Text(range.label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selected ? Color(hex: "1B3A00") : Color(hex: "2E7D32"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? AnyShapeStyle(DS.nuggetGold) : AnyShapeStyle(Color.white))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "2E7D32").opacity(selected ? 0 : 0.4), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Planned / Surprise / Impulse

    private var plannedStatusPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Was this planned?")
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
                    .foregroundStyle(selected ? Color(hex: "1B3A00") : Color(hex: "2E7D32"))
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "1B3A00"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(selected ? AnyShapeStyle(DS.nuggetGold) : AnyShapeStyle(Color.white))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: "2E7D32").opacity(selected ? 0 : 0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Bias tag section

    private var biasTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What's driving this?")
            Text("Used in professional financial planning assessments")
                .font(.caption2)
                .italic()
                .foregroundStyle(DS.textTertiary)

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
                    ProgressView().tint(Color(hex: "1B3A00"))
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
}

#Preview {
    NavigationStack { MoneyEventView() }
}
