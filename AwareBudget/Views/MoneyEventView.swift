import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MoneyEventViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

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
            ToolbarItem(placement: .cancellationAction) {
                Button(viewModel.didSave ? "Done" : "Cancel") { dismiss() }
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

            Button("Done") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DS.hPadding)

            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Category grid

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What did you spend on?")
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(spendCategories) { cat in
                    categoryCell(cat)
                }
            }
        }
    }

    private func categoryCell(_ cat: SpendCategory) -> some View {
        let selected = viewModel.selectedCategory?.name == cat.name
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedCategory = cat
                viewModel.selectedRange = nil
                viewModel.plannedStatus = nil
                viewModel.behaviourTag = nil
            }
        } label: {
            VStack(spacing: 6) {
                Text(cat.emoji)
                    .font(.system(size: 28))
                Text(cat.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selected ? .white : DS.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.clear : DS.accent.opacity(0.3), lineWidth: selected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Range picker

    private var rangePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How much?")
            HStack(spacing: 8) {
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? .white : DS.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? Color.clear : DS.accent.opacity(0.3), lineWidth: selected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Planned / Surprise / Impulse

    private var plannedStatusPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Was this planned?")
            VStack(spacing: 8) {
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
            HStack {
                Text(status.emoji)
                    .font(.system(size: 20))
                Text(status.label)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(selected ? .white : DS.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.clear : DS.accent.opacity(0.3), lineWidth: selected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Bias tag section

    private var biasTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What's driving this?")

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
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
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
