import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MoneyEventViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.sectionGap) {
                    amountHero
                    typeSelector
                    categorySelector
                    noteField
                    dateField
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    saveButton
                }
                .padding(.horizontal, DS.hPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
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

    // MARK: - Sections

    private var amountHero: some View {
        Card(padding: 24) {
            VStack(alignment: .center, spacing: 10) {
                Text("AMOUNT")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(Locale.current.currencySymbol ?? "$")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                    TextField("0", text: $viewModel.amountText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
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

    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Type")
            HStack(spacing: 12) {
                ForEach(MoneyEvent.EventType.allCases) { type in
                    typeButton(type)
                }
            }
        }
    }

    private func typeButton(_ type: MoneyEvent.EventType) -> some View {
        let selected = viewModel.eventType == type
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.eventType = type
            }
        } label: {
            VStack(spacing: 6) {
                Text(type.emoji)
                    .font(.system(size: 28))
                Text(type.label)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(selected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(selected ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .stroke(selected ? Color.blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Category")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MoneyCategory.allCases) { cat in
                        let selected = viewModel.category == cat
                        Button {
                            viewModel.category = cat
                        } label: {
                            Text(cat.rawValue)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(
                                        selected
                                            ? Color.blue
                                            : Color(.secondarySystemBackground)
                                    )
                                )
                                .foregroundStyle(selected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: selected)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

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
