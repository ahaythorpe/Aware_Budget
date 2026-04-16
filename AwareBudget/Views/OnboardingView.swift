import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0

    // Quiz state
    @State private var budgetHistory: String? = nil
    @State private var quitReason: String? = nil

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            patternsPage.tag(1)
            quizPage.tag(2)
            signUpPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    // MARK: - Screen 1: Welcome

    private var welcomePage: some View {
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                NudgeAvatar(size: 120)

                VStack(spacing: 14) {
                    Text("Hi, I'm Nudge.")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.white)
                        .heroTextLegibility()

                    Text("Most budgeting apps track your spending.\nMoneyMind tracks why you spend.")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .heroTextLegibility()

                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.goldText)
                        Text("Based on 50+ years of behavioural research")
                            .font(.system(.footnote, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.35), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.75))
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.horizontal, DS.hPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button {
                    withAnimation { currentPage = 1 }
                } label: {
                    Text("Next \u{2192}")
                }
                .goldButtonStyle()
                .padding(.horizontal, 24)

                progressDots(current: 0, total: 4, light: true)
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Screen 2: The 7 Patterns

    private let patterns: [(emoji: String, name: String, line: String)] = [
        ("📉", "Loss Aversion", "Holding losers too long"),
        ("⏰", "Present Bias", "Robbing future you"),
        ("📈", "Overconfidence", "Overtrading, underperforming"),
        ("🧮", "Mental Accounting", "Saving while in debt"),
        ("🛑", "Status Quo Bias", "Never reviewing super"),
        ("🏷️", "Anchoring", "Stuck on a purchase price"),
        ("📭", "Ostrich Effect", "Avoiding the statements"),
    ]

    private var patternsPage: some View {
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 48)

                    NudgeAvatar(size: 60)

                    Text("The 7 patterns that cost\npeople most")
                        .font(.system(.title, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .heroTextLegibility()

                    VStack(spacing: 10) {
                        ForEach(patterns, id: \.name) { p in
                            HStack(spacing: 14) {
                                Text(p.emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.name)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(DS.textPrimary)
                                    Text(p.line)
                                        .font(.caption)
                                        .foregroundStyle(DS.textSecondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                            .shimmeringGoldBorder(cornerRadius: DS.cardRadius, lineWidth: 2.5)
                            .premiumCardShadow()
                        }
                    }
                    .padding(.horizontal, DS.hPadding)

                    ResearchFootnote(
                        text: "Pompian, 2012 \u{00B7} Behavioural Finance and Wealth Management",
                        style: .pill
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Next \u{2192}")
                }
                .goldButtonStyle()
                .padding(.horizontal, 24)

                progressDots(current: 1, total: 4, light: true)
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Screen 3: Budget Reality Check

    private var quizPage: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("BUDGET REALITY CHECK")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(DS.accent)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    NudgeAvatar(size: 52)
                }
                .padding(.top, 48)

                // Q1
                VStack(alignment: .leading, spacing: 12) {
                    Text("How long did your last budget last?")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DS.textPrimary)

                    quizPill("Less than a week", selected: budgetHistory == "week", action: { budgetHistory = "week" })
                    quizPill("About a month", selected: budgetHistory == "month", action: { budgetHistory = "month" })
                    quizPill("Never tried", selected: budgetHistory == "never_tried", action: { budgetHistory = "never_tried" })
                    quizPill("Never budgeted", selected: budgetHistory == "never_budgeted", action: { budgetHistory = "never_budgeted" })
                }
                .padding(.horizontal, DS.hPadding)

                // Q2
                if budgetHistory != nil && budgetHistory != "never_tried" && budgetHistory != "never_budgeted" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why did you stop?")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DS.textPrimary)

                        quizPill("Too much work", selected: quitReason == "work", action: { quitReason = "work" })
                        quizPill("Made me feel bad", selected: quitReason == "guilt", action: { quitReason = "guilt" })
                        quizPill("Life got in the way", selected: quitReason == "life", action: { quitReason = "life" })
                        quizPill("It just failed", selected: quitReason == "failed", action: { quitReason = "failed" })
                    }
                    .padding(.horizontal, DS.hPadding)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Nudge response + continue
                if budgetHistory != nil && (budgetHistory == "never_tried" || budgetHistory == "never_budgeted" || quitReason != nil) {
                    nudgeResponse
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                progressDots(current: 2, total: 4)
                    .padding(.bottom, 32)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: budgetHistory)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: quitReason)
        }
    }

    private var nudgeResponse: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    NudgeAvatar(size: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("You're not broken. The method is.")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)

                        Text("70% abandon budgeting apps within 30 days.\nNot laziness \u{2014} shame-based design.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.heroGradient)
            )

            Button {
                withAnimation { currentPage = 3 }
            } label: {
                Text("That's why MoneyMind exists \u{2192}")
                    .font(.system(size: 15, weight: .bold))
                    .goldButtonStyle()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.hPadding)
    }

    private func quizPill(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: selected ? .bold : .semibold))
                .foregroundStyle(selected ? .white : DS.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selected ? AnyShapeStyle(DS.deepGreen) : AnyShapeStyle(DS.cardBg),
                    in: Capsule()
                )
                .modifier(QuizPillBorderModifier(selected: selected))
                .premiumCardShadow()
        }
        .buttonStyle(.plain)
    }

    /// Selected pill gets the green hero with no extra border;
    /// unselected pill gets the canonical shimmering gold capsule
    /// border so it matches the in-app card spec.
    private struct QuizPillBorderModifier: ViewModifier {
        let selected: Bool
        func body(content: Content) -> some View {
            if selected {
                content
            } else {
                content.shimmeringGoldBorder(cornerRadius: 999, lineWidth: 2)
            }
        }
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
                          ? (light ? Color.white : DS.darkGreen)
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
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    NudgeAvatar(size: 100)

                    VStack(spacing: 8) {
                        Text(isSignIn ? "Welcome back" : "Create your account")
                            .font(.system(.title, weight: .black))
                            .foregroundStyle(.white)
                            .heroTextLegibility()
                        Text(isSignIn
                             ? "Sign in to pick up where you left off."
                             : "No bank access. Your data stays private.")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .heroTextLegibility()
                    }

                    VStack(spacing: 12) {
                        TextField("Email", text: $email, prompt: Text("Email").foregroundStyle(.white.opacity(0.5)))
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled(true)
                        #if !os(macOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        #endif
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )

                        SecureField("Password", text: $password, prompt: Text("Password").foregroundStyle(.white.opacity(0.5)))
                            .textContentType(isSignIn ? .password : .newPassword)
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )

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
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView().tint(DS.goldTint)
                                Spacer()
                            }
                        } else {
                            Text(isSignIn ? "Sign in" : "Create account")
                        }
                    }
                    .goldButtonStyle()
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
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 32)
                }
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
