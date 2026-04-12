import SwiftUI

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    var selectedTab: Binding<RootTab>? = nil

    // MARK: - State

    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var attemptedCount = 0

    @State private var dragOffset: CGSize = .zero
    @State private var showWhy: Bool = false
    @State private var selectedTone: CheckIn.EmotionalTone? = nil

    @State private var phase: Phase = .questions
    @State private var selectedDriver: CheckIn.SpendingDriver? = nil
    @State private var nudgeCompletionMessage: NudgeMessage?
    @State private var showFollowUp: Bool = false
    @State private var lastAnswerWasYes: Bool = false
    @State private var savedStreak: Int = 0
    @State private var isSaving = false
    @State private var alreadyCheckedIn: CheckIn?

    private let service = SupabaseService.shared

    private enum Phase {
        case questions, driverPick, done
    }

    // MARK: - Design constants

    private let cardCornerRadius: CGFloat = 28
    private let cardHeight: CGFloat = 520
    private let swipeThreshold: CGFloat = 80
    private let maxRotation: Double = 15

    // Card colours
    private let frontColors: [Color] = [Color(hex: "1B5E20"), Color(hex: "2E7D32"), Color(hex: "4CAF50")]
    private let middleBg = Color(hex: "81C784")
    private let backBg   = Color(hex: "A5D6A7")
    private let gold     = DS.goldText

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: "F5F7F5").ignoresSafeArea()

            VStack(spacing: 16) {
                if let existing = alreadyCheckedIn {
                    alreadyDoneView(existing)
                } else {
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
            // Check if already completed today
            if let existing = try? await service.fetchTodaysCheckIn() {
                alreadyCheckedIn = existing
                return
            }
            if questions.isEmpty {
                await loadQuestions()
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

    // MARK: - Card stack (2 back cards visible)

    private var cardStack: some View {
        ZStack {
            // Back card (3rd)
            if currentIndex + 2 < questions.count {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(backBg)
                    .frame(height: cardHeight)
                    .scaleEffect(0.92)
                    .offset(y: 24)
            }
            // Middle card (2nd)
            if currentIndex + 1 < questions.count {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(middleBg)
                    .frame(height: cardHeight)
                    .scaleEffect(0.96)
                    .offset(y: 12)
            }
            // Front card with YES/NO overlays
            ZStack {
                frontCard
                yesNoOverlays
            }
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width) / 20))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let horizontal = value.translation.width
                        if horizontal > swipeThreshold {
                            swipeYes()
                        } else if horizontal < -swipeThreshold {
                            swipeNo()
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight + 30)
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - YES / NO overlays during drag

    private var yesNoOverlays: some View {
        ZStack {
            // YES overlay (right swipe)
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color(hex: "4CAF50").opacity(0.85))
                .overlay(
                    Text("YES")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-15))
                )
                .opacity(max(0, Double(dragOffset.width) / 120))

            // NO overlay (left swipe)
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(DS.warning.opacity(0.85))
                .overlay(
                    Text("NO")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(15))
                )
                .opacity(max(0, Double(-dragOffset.width) / 120))
        }
        .frame(height: cardHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Front card

    private var frontCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(DS.heroGradient)
                .frame(height: cardHeight)

            if currentIndex < questions.count {
                frontContent(for: questions[currentIndex])
                    .padding(24)
            }
        }
        .frame(height: cardHeight)
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

            // Question text — NO text input
            Text(q.question)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Why section (collapsed by default)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(q.whyExplanation)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)

                    if let source = q.researchSource, !source.isEmpty {
                        Text(source)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                            .italic()
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer(minLength: 0)

            // YES / NO buttons inside card
            HStack(spacing: 12) {
                Button { swipeNo() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                        Text("No")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "FF6B6B"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button { swipeYes() } label: {
                    HStack(spacing: 6) {
                        Text("Yes")
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: "1B3A00"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "FFF0A0"), location: 0.0),
                                .init(color: Color(hex: "E8B84B"), location: 0.25),
                                .init(color: Color(hex: "C59430"), location: 0.5),
                                .init(color: Color(hex: "8B6010"), location: 0.75),
                                .init(color: Color(hex: "D4A843"), location: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Follow-up card (shown when YES + question has follow-up)

    private var followUpCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Follow up")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                if currentIndex > 0, currentIndex - 1 < questions.count {
                    Text("You said yes to: \"\(questions[currentIndex - 1].question)\"")
                        .font(.subheadline)
                        .foregroundStyle(DS.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFollowUp = false
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 13, weight: .bold))
                    .goldButtonStyle()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Driver pick

    private var driverPickView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("What drove this")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                Text("No wrong answers. Just noticing")
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(CheckIn.SpendingDriver.allCases) { driver in
                    driverPill(driver)
                }
            }
            .padding(.horizontal, DS.hPadding)

            Button {
                guard !isSaving else { return }
                Task { await saveCheckIn() }
            } label: {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color(hex: "3A2000"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                } else {
                    Text(selectedDriver != nil ? "Continue" : "Skip")
                        .font(.system(size: 13, weight: .bold))
                        .goldButtonStyle()
                }
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
                    .foregroundStyle(isSelected ? Color(hex: "1A5C38") : DS.textPrimary)
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
                    .stroke(isSelected ? DS.accent : Color(hex: "4CAF50").opacity(0.15), lineWidth: isSelected ? 1.5 : 0.5)
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
                    .foregroundStyle(Color(hex: "1A5C38"))
            }
            .sensoryFeedback(.success, trigger: phase == .done)

            VStack(spacing: 6) {
                Text("Day \(savedStreak)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                Text("\(attemptedCount) question\(attemptedCount == 1 ? "" : "s") reflected on")
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
                    .multilineTextAlignment(.center)

                if let driver = selectedDriver {
                    Text("Driver: \(driver.emoji) \(driver.label)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color(hex: "4CAF50"))
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

    // MARK: - Already checked in today

    private func alreadyDoneView(_ checkIn: CheckIn) -> some View {
        VStack(spacing: 24) {
            Spacer()

            NudgeAvatar(size: 72)

            VStack(spacing: 8) {
                Text("You checked in today.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.textPrimary)

                Text("Day \(checkIn.streakCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.accent)

                if checkIn.questionId != nil {
                    Text("Bias reflected on today")
                        .font(.caption)
                        .foregroundStyle(DS.textTertiary)
                }

                Text("Come back tomorrow")
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Load questions from Supabase (fallback to local mock)

    private func loadQuestions() async {
        do {
            var fetched: [Question] = []
            for _ in 0..<5 {
                let q = try await service.fetchNextQuestion()
                if !fetched.contains(where: { $0.id == q.id }) {
                    fetched.append(q)
                }
            }
            questions = fetched.isEmpty ? Array(QuestionPool.seed.shuffled().prefix(5)) : fetched
        } catch {
            questions = Array(QuestionPool.seed.shuffled().prefix(5))
        }
    }

    // MARK: - Save check-in to Supabase

    private func saveCheckIn() async {
        isSaving = true
        defer { isSaving = false }

        guard let uid = await service.currentUserId else { return }

        // Compute streak
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayCheckIn = try? await service.fetchCheckIn(on: yesterday)
        let streak = (yesterdayCheckIn?.streakCount ?? 0) + 1

        // Compute alignment
        let now = Date()
        let month = try? await service.fetchOrCreateBudgetMonth(for: now)
        let events = try? await service.fetchMoneyEvents(forMonth: now)
        let unplanned = (events ?? [])
            .filter { $0.plannedStatus.isUnplanned }
            .reduce(0.0) { $0 + $1.amount }
        let target = month?.incomeTarget ?? 0
        let alignment = target > 0 ? max(0, min(100, (1 - unplanned / target) * 100)) : 0

        let checkIn = CheckIn(
            id: UUID(),
            userId: uid,
            date: Date(),
            questionId: questions.first?.id,
            response: nil,
            emotionalTone: .neutral,
            spendingDriver: selectedDriver,
            streakCount: streak,
            alignmentPct: alignment,
            createdAt: Date()
        )

        do {
            try await service.saveCheckIn(checkIn)
        } catch {
            // Continue to completion even if save fails
        }

        savedStreak = streak

        nudgeCompletionMessage = NudgeEngine.checkInResponse(
            streakDays: streak,
            questionsReflected: attemptedCount,
            driver: selectedDriver,
            emotionalTone: nil
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .done
        }
        NotificationService.scheduleDailyReminder()
    }

    // MARK: - Swipe actions

    private func swipeYes() {
        lastAnswerWasYes = true
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: 600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            advance()
        }
    }

    private func swipeNo() {
        lastAnswerWasYes = false
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            advance()
        }
    }

    private func advance() {
        attemptedCount += 1
        currentIndex += 1
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
