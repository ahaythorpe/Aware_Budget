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
        ZStack(alignment: .top) {
            DS.bg.ignoresSafeArea()
            // Soft hero halo behind the header so the screen has lift
            // without competing with the question card itself.
            LinearGradient(
                colors: [DS.accent.opacity(0.22), DS.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        nudgeFramerCard
                        questionCard
                        if let err = saveError {
                            Text(err)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.bottom, 24)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MONEY MIND QUIZ")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(DS.accent)
                Spacer()
                Text("\(currentIndex + 1) of \(MoneyMindQuiz.questions.count)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(DS.goldBase)
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(DS.accent)
                .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    /// Calming framer with Nudge's voice so the user knows there's no
    /// "right" answer. Uses the same NudgeSaysCard treatment as Home so
    /// the quiz feels native, not like a different surface.
    private var nudgeFramerCard: some View {
        NudgeSaysCard(
            message: nudgeFramerLine,
            surface: .whiteShimmer
        )
        .padding(.horizontal, 20)
    }

    /// One short Nudge line per question so the framer stays fresh and
    /// each question feels narrated rather than tested.
    private var nudgeFramerLine: String {
        switch currentIndex {
        case 0: return "No right answer. Just notice what you actually do."
        case 1: return "Be honest. The pattern is the point."
        case 2: return "Where the money lands matters less than how it feels when it lands."
        case 3: return "Now-you and future-you are both on this list."
        case 4: return "The crowd is data, not destiny."
        default: return "Defaults run quietly. Notice yours."
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(question.prompt)
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, opt in
                    optionRow(idx: idx, option: opt)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.35), lineWidth: 1)
        )
        .premiumCardShadow()
        .padding(.horizontal, 20)
    }

    private func optionRow(idx: Int, option: QuizOption) -> some View {
        let selected = answers[currentIndex] == idx
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                answers[currentIndex] = idx
            }
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? DS.accent : DS.textSecondary.opacity(0.35),
                                      lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(DS.accent)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(option.label)
                    .font(.system(size: 16, weight: selected ? .bold : .medium))
                    .foregroundStyle(DS.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? DS.paleGreen : DS.bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? DS.accent : DS.goldBase.opacity(0.18),
                                  lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if currentIndex > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            currentIndex -= 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                            Text("Back")
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
                    .background(
                        Capsule()
                            .strokeBorder(DS.textSecondary.opacity(0.25), lineWidth: 1)
                    )
                }
                Button {
                    handleNext()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        }
                        Text(isLast ? "See my result" : "Next")
                        if !isSaving {
                            Image(systemName: isLast ? "sparkles" : "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                }
                .goldButtonStyle()
                .opacity(hasAnswer && !isSaving ? 1.0 : 0.55)
                .disabled(!hasAnswer || isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ResearchFootnote(text: "BFAS framework · Pompian, 2012", style: .pill)
                .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [DS.bg.opacity(0), DS.bg],
                startPoint: .top, endPoint: .center
            )
        )
    }

    private func handleNext() {
        guard hasAnswer else { return }
        if isLast {
            Task { await submit() }
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                currentIndex += 1
            }
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
