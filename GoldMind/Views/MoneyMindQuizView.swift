import SwiftUI

/// 6-question multi-choice Money Mind Quiz. ~2 min. Surfaces the user's
/// archetype (one of 6 from `Archetype.swift`) plus their top biases.
///
/// Flow: launched from Home tile or Education tab → 6 questions one-at-a-time
/// with progress bar → submit → `ArchetypeRevealView`. Persists via
/// `SupabaseService.saveMoneyMindQuizResponse`.
struct MoneyMindQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var answers: [Int?] = Array(repeating: nil, count: MoneyMindQuiz.questions.count)
    @State private var revealedArchetype: Archetype? = nil
    @State private var revealedScores: [Archetype: Int] = [:]
    @State private var saveError: String? = nil
    @State private var isSaving: Bool = false

    private var question: QuizQuestion { MoneyMindQuiz.questions[currentIndex] }
    private var progress: Double {
        Double(currentIndex + 1) / Double(MoneyMindQuiz.questions.count)
    }
    private var isLast: Bool { currentIndex == MoneyMindQuiz.questions.count - 1 }
    private var hasAnswer: Bool { answers[currentIndex] != nil }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        questionCard
                        if let err = saveError {
                            Text(err)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 16)
                }
                footer
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { dismiss() }
                    .foregroundStyle(DS.textSecondary)
            }
        }
        .fullScreenCover(item: $revealedArchetype) { archetype in
            ArchetypeRevealView(archetype: archetype, scores: revealedScores) {
                dismiss()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MONEY MIND QUIZ")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(DS.accent)
                Spacer()
                Text("\(currentIndex + 1) of \(MoneyMindQuiz.questions.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(DS.accent)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.prompt)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, opt in
                    optionRow(idx: idx, option: opt)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func optionRow(idx: Int, option: QuizOption) -> some View {
        let selected = answers[currentIndex] == idx
        return Button {
            answers[currentIndex] = idx
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? DS.accent : DS.textSecondary.opacity(0.35), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(DS.accent)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(option.label)
                    .font(.system(size: 16, weight: selected ? .semibold : .regular))
                    .foregroundStyle(DS.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DS.cardBg)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? DS.accent : Color.black.opacity(0.04), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if currentIndex > 0 {
                Button("Back") { withAnimation { currentIndex -= 1 } }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(DS.textSecondary.opacity(0.25), lineWidth: 1)
                    )
            }
            Spacer()
            Button {
                handleNext()
            } label: {
                HStack(spacing: 6) {
                    if isSaving { ProgressView().tint(.white) }
                    Text(isLast ? "See my result" : "Next")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DS.heroGradient)
                )
                .opacity(hasAnswer && !isSaving ? 1.0 : 0.45)
            }
            .disabled(!hasAnswer || isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DS.bg)
    }

    private func handleNext() {
        guard hasAnswer else { return }
        if isLast {
            Task { await submit() }
        } else {
            withAnimation { currentIndex += 1 }
        }
    }

    private func submit() async {
        isSaving = true
        saveError = nil
        let intAnswers = answers.map { $0 ?? 0 }
        let result = MoneyMindQuiz.score(answers: intAnswers)
        let topBiases = Array(result.winner.topBiasNames.prefix(3))
        do {
            try await SupabaseService.shared.saveMoneyMindQuizResponse(
                answers: intAnswers,
                scores: result.scores,
                archetype: result.winner,
                topBiases: topBiases
            )
            await MainActor.run {
                revealedScores = result.scores
                revealedArchetype = result.winner
                isSaving = false
            }
        } catch {
            await MainActor.run {
                saveError = "Couldn't save your result. Try again."
                isSaving = false
            }
        }
    }
}

#Preview {
    NavigationStack { MoneyMindQuizView() }
}
