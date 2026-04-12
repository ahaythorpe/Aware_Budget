import SwiftUI

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    var selectedTab: Binding<RootTab>? = nil

    // MARK: - State

    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var attemptedCount = 0

    @State private var dragOffset: CGSize = .zero
    @State private var response: String = ""
    @State private var showWhy: Bool = false
    @State private var selectedTone: CheckIn.EmotionalTone? = nil

    @State private var phase: Phase = .questions
    @State private var selectedDriver: CheckIn.SpendingDriver? = nil
    @State private var nudgeCompletionMessage: NudgeMessage?

    private enum Phase {
        case questions, driverPick, done
    }

    // MARK: - Colours (money green)

    private let frontGradient = DS.heroGradient
    private let middleBg = DS.lightGreen                       // #81C784
    private let backBg   = Color(hex: "A5D6A7")               // lighter green
    private let gold     = DS.goldText

    private let swipeThreshold: CGFloat = 80
    private let cardCornerRadius: CGFloat = 28
    private let cardHeight: CGFloat = 560

    // MARK: - Body

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            VStack(spacing: 16) {
                progressDots
                    .padding(.horizontal, DS.hPadding)
                    .padding(.top, 8)

                Spacer(minLength: 0)

                switch phase {
                case .questions:
                    if questions.isEmpty {
                        ProgressView()
                    } else {
                        cardStack
                    }
                case .driverPick:
                    driverPickView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                case .done:
                    completionView
                        .transition(.opacity)
                }

                Spacer(minLength: 0)

                if phase == .questions && !questions.isEmpty {
                    swipeHints
                        .padding(.horizontal, DS.hPadding)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Daily check-in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selectedTab == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.textSecondary)
                            .padding(8)
                            .background(DS.paleGreen)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .task {
            if questions.isEmpty {
                questions = Array(QuestionPool.seed.shuffled().prefix(5))
            }
        }
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<max(questions.count, 1), id: \.self) { i in
                Circle()
                    .fill(i < attemptedCount ? DS.accent : DS.textTertiary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeOut(duration: 0.2), value: attemptedCount)
            }
        }
    }

    // MARK: - Card stack

    private var cardStack: some View {
        ZStack {
            if currentIndex + 2 < questions.count {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(backBg)
                    .scaleEffect(0.92)
                    .offset(y: 24)
            }
            if currentIndex + 1 < questions.count {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(middleBg)
                    .scaleEffect(0.96)
                    .offset(y: 12)
            }
            frontCard
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width / 25)))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            if value.translation.height < -swipeThreshold {
                                completeSwipe()
                            } else if value.translation.width > swipeThreshold {
                                skipSwipe()
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - Front card

    private var frontCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(frontGradient)
            if currentIndex < questions.count {
                frontContent(for: questions[currentIndex])
                    .padding(24)
            }
        }
    }

    private func frontContent(for q: Question) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Gold bias pill on dark green
            Text(q.biasName.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DS.goldText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DS.goldBase.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(DS.goldText.opacity(0.4), lineWidth: 0.5)
                        )
                )

            Text(q.question)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            TextField("", text: $response, prompt: Text("Optional response...").foregroundColor(.white.opacity(0.4)), axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2, reservesSpace: true)
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Why section
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showWhy.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .rotationEffect(.degrees(showWhy ? 90 : 0))
                    Text("Why this matters")
                        .font(.footnote.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.75))
            }
            .buttonStyle(.plain)

            if showWhy {
                Text(q.whyExplanation)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .background(DS.paleGreen.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                ForEach(CheckIn.EmotionalTone.allCases) { tone in
                    toneButton(tone)
                }
            }
        }
    }

    private func toneButton(_ tone: CheckIn.EmotionalTone) -> some View {
        let selected = selectedTone == tone
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTone = selected ? nil : tone
            }
        } label: {
            VStack(spacing: 6) {
                Text(tone.emoji)
                    .font(.system(size: 28))
                Text(tone.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? gold : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Swipe hints

    private var swipeHints: some View {
        HStack {
            Text("skip \u{2192}")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.textSecondary)
            Spacer()
            Text("\u{2191} complete")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.textSecondary)
        }
    }

    // MARK: - Driver pick

    private var driverPickView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("What drove this?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                Text("No wrong answers. Just noticing.")
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(CheckIn.SpendingDriver.allCases) { driver in
                    driverPill(driver)
                }
            }
            .padding(.horizontal, DS.hPadding)

            // Gold complete button
            Button {
                nudgeCompletionMessage = NudgeEngine.checkInResponse(
                    streakDays: attemptedCount,
                    questionsReflected: attemptedCount,
                    driver: selectedDriver,
                    emotionalTone: selectedTone
                )
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = .done
                }
                NotificationService.scheduleDailyReminder()
            } label: {
                Text(selectedDriver != nil ? "Continue" : "Skip")
                    .font(.system(size: 13, weight: .bold))
                    .goldButtonStyle()
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 20)
    }

    private func driverPill(_ driver: CheckIn.SpendingDriver) -> some View {
        let isSelected = selectedDriver == driver
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDriver = isSelected ? nil : driver
            }
        } label: {
            VStack(spacing: 8) {
                Text(driver.emoji)
                    .font(.system(size: 28))
                Text(driver.label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isSelected ? DS.primary : DS.textPrimary)
                Text(driver.shortDescription)
                    .font(.caption2)
                    .foregroundStyle(DS.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? DS.paleGreen : DS.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? DS.accent : DS.textTertiary.opacity(0.3), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DS.paleGreen)
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(DS.primary)
            }
            .sensoryFeedback(.success, trigger: phase == .done)

            VStack(spacing: 6) {
                Text("Nice work")
                    .font(.title.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                Text("\(attemptedCount) question\(attemptedCount == 1 ? "" : "s") reflected on today.")
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
                    .multilineTextAlignment(.center)

                if let driver = selectedDriver {
                    Text("Driver: \(driver.emoji) \(driver.label)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(DS.accent)
                        .padding(.top, 4)
                }
            }

            if let nudge = nudgeCompletionMessage {
                NudgeCardView(message: nudge)
            }

            Button("Done") {
                if let selectedTab {
                    selectedTab.wrappedValue = .home
                } else {
                    dismiss()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Swipe actions

    private func completeSwipe() {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: 0, height: -900)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            advance()
        }
    }

    private func skipSwipe() {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: 900, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            advance()
        }
    }

    private func advance() {
        attemptedCount += 1
        currentIndex += 1
        response = ""
        showWhy = false
        selectedTone = nil
        dragOffset = .zero
        if currentIndex >= questions.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .driverPick
            }
        }
    }
}

#Preview {
    NavigationStack { CheckInView() }
}
