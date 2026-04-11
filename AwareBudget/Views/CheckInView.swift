import SwiftUI

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CheckInViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isComplete {
                    completionView
                } else {
                    questionSection
                    toneSection
                    submitButton
                }
            }
            .padding(20)
        }
        .navigationTitle("Daily Check-in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .task { await viewModel.load() }
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let q = viewModel.question {
                Text(q.biasName.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(q.question)
                    .font(.title2.bold())

                TextField("What's on your mind?", text: $viewModel.response, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .textFieldStyle(.roundedBorder)

                DisclosureGroup(isExpanded: $viewModel.showWhy) {
                    Text(q.whyExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } label: {
                    Text("Why this matters")
                        .font(.footnote.weight(.medium))
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you feeling?")
                .font(.headline)
            HStack(spacing: 12) {
                ForEach(CheckIn.EmotionalTone.allCases) { tone in
                    Button {
                        viewModel.emotionalTone = tone
                    } label: {
                        VStack(spacing: 4) {
                            Text(tone.emoji).font(.title2)
                            Text(tone.label).font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.emotionalTone == tone
                                ? Color.blue.opacity(0.15)
                                : Color(.secondarySystemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            HStack {
                Spacer()
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Complete check-in").fontWeight(.semibold)
                }
                Spacer()
            }
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isSaving || viewModel.question == nil)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Check-in complete")
                .font(.title2.bold())
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(viewModel.resultingStreak) day streak")
                    .font(.headline)
            }
            Button("Done") { dismiss() }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
