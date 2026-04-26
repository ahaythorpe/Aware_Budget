import SwiftUI

/// First-open BFAS baseline assessment (handbook §8, PRD v1.2).
/// 16 questions, 1 per bias. YES/NO swipe or tap. Seeds `bfas_weight`.
struct BFASAssessmentView: View {
    enum Stage { case intro, quiz, done }

    @State private var stage: Stage = .intro
    @State private var index: Int = 0
    @State private var answers: [String: Bool] = [:]
    var onFinish: ([String: Bool]) -> Void

    private let questions = BFASQuestion.seed

    var body: some View {
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()
            switch stage {
            case .intro: introView
            case .quiz:  quizView
            case .done:  doneView
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: stage)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: index)
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            VStack(spacing: 8) {
                Text("Let's set your baseline")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(.white)
                    .heroTextLegibility()
                    .multilineTextAlignment(.center)

                Text("16 quick questions · about 3 minutes")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 30)

            credibilityPill

            Spacer()

            VStack(spacing: 8) {
                Button { stage = .quiz } label: {
                    Text("Begin →")
                }
                .goldButtonStyle()

                Text("No right or wrong answers. This is just about you.")
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }

    private var credibilityPill: some View {
        ResearchFootnote(text: "Based on the BFAS framework · Pompian, 2012", style: .pill)
    }

    // MARK: - Quiz

    private var quizView: some View {
        VStack(spacing: 20) {
            quizHeader

            if index < questions.count {
                let q = questions[index]
                card(for: q)
                    .id(q.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .padding(.horizontal, 18)

                yesNoButtons(for: q)
                    .padding(.horizontal, 18)
            }

            Spacer()

            citationFooter
                .padding(.bottom, 24)
        }
        .padding(.top, 12)
    }

    private var quizHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<questions.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= index ? DS.goldText : .white.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 18)

            Text("QUESTION \(index + 1) OF \(questions.count)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.white)
                .heroTextLegibility()
        }
    }

    private func card(for q: BFASQuestion) -> some View {
        VStack(spacing: 16) {
            Text(q.emoji)
                .font(.system(size: 54))
            Text(q.prompt)
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 2.5)
        )
    }

    private func yesNoButtons(for q: BFASQuestion) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                answerButton(label: "Yes", isYes: true)  { record(q, yes: true) }
                answerButton(label: "No", isYes: false) { record(q, yes: false) }
            }
            Text("There are no wrong answers.")
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func answerButton(label: String, isYes: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isYes ? "checkmark" : "xmark")
                    .font(.headline.weight(.bold))
                Text(label)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(isYes ? DS.goldBase : DS.danger)
            )
        }
        .buttonStyle(.plain)
    }

    private var citationFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 10))
                .foregroundStyle(DS.goldText)
            Text("BFAS · Pompian, 2012")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: Capsule())
    }

    private func record(_ q: BFASQuestion, yes: Bool) {
        answers[q.biasName] = yes
        if index + 1 < questions.count {
            index += 1
        } else {
            stage = .done
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            VStack(spacing: 8) {
                Text("Your baseline is set")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(.white)
                    .heroTextLegibility()

                Text("Nudge will watch for these patterns in your decisions from here on.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            credibilityPill

            Spacer()

            Button { onFinish(answers) } label: {
                Text("Enter MoneyMind →")
            }
            .goldButtonStyle()
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    BFASAssessmentView { _ in }
}
