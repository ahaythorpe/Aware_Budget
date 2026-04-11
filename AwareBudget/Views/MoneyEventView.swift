import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MoneyEventViewModel()

    var body: some View {
        Form {
            Section("Amount") {
                TextField("0.00", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.semibold))
            }

            Section("Type") {
                HStack(spacing: 12) {
                    ForEach(MoneyEvent.EventType.allCases) { type in
                        Button {
                            viewModel.eventType = type
                        } label: {
                            VStack(spacing: 4) {
                                Text(type.emoji).font(.title2)
                                Text(type.label).font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.eventType == type
                                    ? Color.blue.opacity(0.15)
                                    : Color(.secondarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section("Category") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MoneyCategory.allCases) { cat in
                            Button {
                                viewModel.category = cat
                            } label: {
                                Text(cat.rawValue)
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.category == cat
                                            ? Color.blue
                                            : Color(.secondarySystemBackground)
                                    )
                                    .foregroundStyle(
                                        viewModel.category == cat ? .white : .primary
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Note") {
                TextField("Optional", text: $viewModel.note, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }

            Section("Date") {
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .labelsHidden()
            }

            if let errorMessage = viewModel.errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }
        }
        .navigationTitle("Log money event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.save()
                        if viewModel.didSave { dismiss() }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
    }
}
