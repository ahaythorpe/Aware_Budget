import SwiftUI

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CheckInViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                if viewModel.isComplete {
                    completionView
                        .padding(.horizontal, DS.hPadding)
                        .padding(.top, 60)
                } else {
                    VStack(spacing: DS.sectionGap) {
                        questionCard
                        toneSection
                        submitButton
                    }
                    .padding(.horizontal, DS.hPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Daily check-in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
            }
        }
        .task { await viewModel.load() }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isComplete)
    }

    // MARK: - Question

    private var questionCard: some View {
        Card(padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                if let q = viewModel.question {
                    Text(q.biasName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                        .tracking(0.8)

                    Text(q.question)
                        .font(.title2.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    DisclosureGroup(isExpanded: $viewModel.showWhy) {
                        Text(q.whyExplanation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .fixedSize(horizontal: false, vertical: true)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb")
                            Text("Why this matters")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                    .tint(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your thoughts (optional)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextField("What's on your mind?", text: $viewModel.response, axis: .vertical)
                            .font(.subheadline)
                            .lineLimit(3, reservesSpace: true)
                            .padding(12)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(height: 200)
                }
            }
        }
    }

    // MARK: - Tone

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How are you feeling?")
            HStack(spacing: 12) {
                ForEach(CheckIn.EmotionalTone.allCases) { tone in
                    toneButton(tone)
                }
            }
        }
    }

    private func toneButton(_ tone: CheckIn.EmotionalTone) -> some View {
        let selected = viewModel.emotionalTone == tone
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.emotionalTone = tone
            }
        } label: {
            VStack(spacing: 8) {
                Text(tone.emoji)
                    .font(.system(size: 32))
                Text(tone.label)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(selected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
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

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Complete check-in")
                    Image(systemName: "arrow.right")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isSaving || viewModel.question == nil)
        .opacity(viewModel.question == nil ? 0.6 : 1.0)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.green)
            }
            .sensoryFeedback(.success, trigger: viewModel.isComplete)

            VStack(spacing: 6) {
                Text("Nice work")
                    .font(.title.weight(.bold))
                Text("One more day of awareness in the bank.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(viewModel.resultingStreak) day streak")
                    .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())

            Button("Done") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack { CheckInView() }
}
