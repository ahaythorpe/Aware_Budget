import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MoneyEventViewModel()

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.sectionGap) {
                    amountHero
                    plannedStatusSelector
                    if viewModel.showBehaviourTag {
                        behaviourTagSection
                    }
                    if viewModel.showLifeEvent {
                        lifeEventSection
                    }
                    noteField
                    dateField
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(DS.warning)
                    }
                    saveButton
                }
                .padding(.horizontal, DS.hPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.plannedStatus)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.showLifeEvent)
            }
        }
        .navigationTitle("Log money event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Amount

    private var amountHero: some View {
        Card(padding: 24) {
            VStack(alignment: .center, spacing: 10) {
                Text("AMOUNT")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.textSecondary)
                    .tracking(0.8)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(Locale.current.currencySymbol ?? "$")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DS.textSecondary)
                    TextField("0", text: $viewModel.amountText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize()
                    #if !os(macOS)
                        .keyboardType(.decimalPad)
                    #endif
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Planned / Surprise / Impulse

    private var plannedStatusSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Was this planned?")
            VStack(spacing: 10) {
                ForEach(MoneyEvent.PlannedStatus.allCases) { status in
                    plannedStatusButton(status)
                }
            }
        }
    }

    private func plannedStatusButton(_ status: MoneyEvent.PlannedStatus) -> some View {
        let selected = viewModel.plannedStatus == status
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.plannedStatus = status
            }
        } label: {
            HStack(spacing: 14) {
                Text(status.emoji)
                    .font(.system(size: 24))
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.label)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(selected ? .white : DS.textPrimary)
                    Text(statusDescription(status))
                        .font(.caption)
                        .foregroundStyle(selected ? .white.opacity(0.8) : DS.textSecondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(selected ? DS.primary : DS.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .stroke(selected ? DS.primary : DS.paleGreen, lineWidth: selected ? 0 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func statusDescription(_ status: MoneyEvent.PlannedStatus) -> String {
        switch status {
        case .planned:  return "Expected, budgeted for"
        case .surprise: return "Didn't see this coming"
        case .impulse:  return "Saw it, wanted it, bought it"
        }
    }

    // MARK: - Behaviour tag (only for surprise/impulse)

    private var behaviourTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What drove it?")
            Text("No wrong answers. Just noticing.")
                .font(.caption)
                .foregroundStyle(DS.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(CheckIn.SpendingDriver.allCases) { driver in
                    behaviourTagButton(driver)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func behaviourTagButton(_ driver: CheckIn.SpendingDriver) -> some View {
        let selected = viewModel.behaviourTag == driver
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.behaviourTag = selected ? nil : driver
            }
        } label: {
            VStack(spacing: 6) {
                Text(driver.emoji)
                    .font(.system(size: 22))
                Text(driver.label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(selected ? .white : DS.textPrimary)
                Text(driver.shortDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(selected ? .white.opacity(0.8) : DS.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(selected ? DS.primary : DS.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .stroke(selected ? DS.primary : DS.paleGreen, lineWidth: selected ? 0 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Life event (only for amount > 200)

    private var lifeEventSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Anything significant behind this?")
            Text("Helps Nudge understand the bigger picture.")
                .font(.caption)
                .foregroundStyle(DS.textSecondary)
            VStack(spacing: 8) {
                ForEach(MoneyEvent.LifeEvent.allCases) { event in
                    lifeEventButton(event)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func lifeEventButton(_ event: MoneyEvent.LifeEvent) -> some View {
        let selected = viewModel.lifeEvent == event
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.lifeEvent = selected ? nil : event
            }
        } label: {
            HStack(spacing: 12) {
                Text(event.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(selected ? .white : DS.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(selected ? DS.primary : DS.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .stroke(selected ? DS.primary : DS.paleGreen, lineWidth: selected ? 0 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Note

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Note")
            Card(padding: 14) {
                TextField("Optional — what was this for?", text: $viewModel.note, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(2, reservesSpace: true)
            }
        }
    }

    // MARK: - Date

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Date")
            Card(padding: 12) {
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save()
                if viewModel.didSave { dismiss() }
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Save event")
                    Image(systemName: "checkmark")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.canSave || viewModel.isSaving)
        .opacity(viewModel.canSave ? 1.0 : 0.5)
    }
}

#Preview {
    NavigationStack { MoneyEventView() }
}
