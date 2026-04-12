import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0

    // Quiz state
    @State private var budgetHistory: String? = nil
    @State private var quitReason: String? = nil

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                quizPage.tag(1)
                howItWorksPage.tag(2)
                signUpPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
    }

    // MARK: - Screen 1: Welcome

    private var welcomePage: some View {
        ZStack {
            DS.heroGradient.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                NudgeAvatar(size: 120)

                VStack(spacing: 12) {
                    Text("Hi, I'm Nudge.")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Most budgeting apps track your spending.\nAwareBudget tracks why you spend.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    withAnimation { currentPage = 1 }
                } label: {
                    Text("Get started \u{2192}")
                        .font(.system(size: 15, weight: .bold))
                        .goldButtonStyle()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DS.hPadding)

                progressDots(current: 0, total: 4, light: true)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, DS.hPadding)
        }
    }

    // MARK: - Screen 2: Budget Reality Check

    private var quizPage: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    SectionHeader(title: "Budget Reality Check")
                    NudgeAvatar(size: 60)
                }
                .padding(.top, 40)

                // Q1
                VStack(alignment: .leading, spacing: 10) {
                    Text("How long did your last budget last?")
                        .font(.headline)
                        .foregroundStyle(DS.textPrimary)

                    quizPill("Less than a week", selected: budgetHistory == "week", action: { budgetHistory = "week" })
                    quizPill("About a month", selected: budgetHistory == "month", action: { budgetHistory = "month" })
                    quizPill("Never tried", selected: budgetHistory == "never", action: { budgetHistory = "never" })
                }
                .padding(.horizontal, DS.hPadding)

                // Q2
                if budgetHistory != nil && budgetHistory != "never" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Why did you stop?")
                            .font(.headline)
                            .foregroundStyle(DS.textPrimary)

                        quizPill("Too much work", selected: quitReason == "work", action: { quitReason = "work" })
                        quizPill("Made me feel bad", selected: quitReason == "guilt", action: { quitReason = "guilt" })
                        quizPill("Life got in the way", selected: quitReason == "life", action: { quitReason = "life" })
                        quizPill("It just failed", selected: quitReason == "failed", action: { quitReason = "failed" })
                    }
                    .padding(.horizontal, DS.hPadding)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Nudge response
                if budgetHistory != nil && (budgetHistory == "never" || quitReason != nil) {
                    nudgeResponse
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Continue button
                if budgetHistory != nil && (budgetHistory == "never" || quitReason != nil) {
                    Button {
                        withAnimation { currentPage = 2 }
                    } label: {
                        Text("That's why AwareBudget exists \u{2192}")
                            .font(.system(size: 15, weight: .bold))
                            .goldButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DS.hPadding)
                    .transition(.opacity)
                }

                progressDots(current: 1, total: 4)
                    .padding(.bottom, 32)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: budgetHistory)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: quitReason)
        }
    }

    private var nudgeResponse: some View {
        VStack(spacing: 16) {
            NudgeAvatar(size: 56)

            Text("You're not broken. The method is.")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("70% of people abandon budgeting apps within 30 days. Not from laziness \u{2014} from apps that create shame not awareness.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.heroGradient)
        )
        .padding(.horizontal, DS.hPadding)
    }

    private func quizPill(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selected ? .white : DS.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selected ? Color.clear : DS.paleGreen, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Screen 3: How it works

    @State private var howItWorksCard = 0

    private var howItWorksPage: some View {
        VStack(spacing: 24) {
            Spacer()

            TabView(selection: $howItWorksCard) {
                scienceCard(
                    emoji: "🧠",
                    title: "Built on real research",
                    body: "16 cognitive biases drive most financial decisions. Not character flaws \u{2014} documented patterns proven by Nobel Prize-winning research.",
                    citation: "Kahneman & Tversky, 1979 \u{00B7} Thaler, 1985 \u{00B7} Cialdini, 1984"
                ).tag(0)

                scienceCard(
                    emoji: "\u{2726}",
                    title: "One question. One minute.",
                    body: "Each question is designed to surface a specific bias through your own experience. Yes or no. No right answers. No judgment.",
                    citation: "Based on BFAS methodology, Grable & Joo 2004"
                ).tag(1)

                scienceCard(
                    emoji: "📈",
                    title: "Your patterns. Not a grade.",
                    body: "Yes answers show a bias is active. No answers show your awareness working. After 7 days Nudge shows you what's driving your financial decisions.",
                    citation: "Scoring based on revealed preference theory"
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 340)

            if howItWorksCard == 2 {
                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("I'm ready")
                        .font(.system(size: 15, weight: .bold))
                        .goldButtonStyle()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DS.hPadding)
                .transition(.opacity)
            }

            Spacer()

            progressDots(current: 2, total: 4)
                .padding(.bottom, 32)
        }
    }

    private func scienceCard(emoji: String, title: String, body: String, citation: String) -> some View {
        VStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 52))

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(DS.textPrimary)
                .multilineTextAlignment(.center)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text(citation)
                .font(.system(size: 11))
                .foregroundStyle(DS.textTertiary)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - Screen 4: Sign Up

    private var signUpPage: some View {
        AuthFormView(hasCompletedOnboarding: $hasCompletedOnboarding)
    }

    // MARK: - Progress dots

    private func progressDots(current: Int, total: Int = 4, light: Bool = false) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current
                          ? (light ? Color.white : Color(hex: "1A5C38"))
                          : (light ? Color.white.opacity(0.3) : DS.textTertiary.opacity(0.3)))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Auth Form (sign up / sign in toggle)

private struct AuthFormView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var isSignIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 40)

                NudgeAvatar(size: 100)

                VStack(spacing: 8) {
                    Text(isSignIn ? "Welcome back" : "Create your account")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DS.textPrimary)
                    Text(isSignIn
                         ? "Sign in to pick up where you left off."
                         : "Your data stays private. No bank access. Ever.")
                        .font(.subheadline)
                        .foregroundStyle(DS.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled(true)
                    #if !os(macOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    #endif
                        .font(.body)
                        .padding(14)
                        .background(DS.paleGreen.opacity(0.5))
                        .foregroundStyle(DS.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textContentType(isSignIn ? .password : .newPassword)
                        .font(.body)
                        .padding(14)
                        .background(DS.paleGreen.opacity(0.5))
                        .foregroundStyle(DS.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(DS.warning)
                    }
                }
                .padding(.horizontal, DS.hPadding)

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .tint(Color(hex: "3A2000"))
                        } else {
                            Text(isSignIn ? "Sign in" : "Create account")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Spacer()
                    }
                    .goldButtonStyle()
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting || email.isEmpty || password.isEmpty)
                .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
                .padding(.horizontal, DS.hPadding)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSignIn.toggle()
                        errorMessage = nil
                    }
                } label: {
                    Text(isSignIn
                         ? "Don't have an account? Sign up"
                         : "Already have an account? Sign in")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "4CAF50"))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 32)
            }
        }
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            if isSignIn {
                try await SupabaseService.shared.signIn(email: email, password: password)
            } else {
                try await SupabaseService.shared.signUp(email: email, password: password)
                _ = try await SupabaseService.shared.fetchOrCreateBudgetMonth(for: Date())
            }
            UserDefaults.standard.set(true, forKey: "hasSeenNudge")
            hasCompletedOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
