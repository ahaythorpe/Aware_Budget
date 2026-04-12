import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0
    @State private var showSignIn = false

    // Quiz state
    @State private var budgetHistory: String? = nil
    @State private var quitReason: String? = nil

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                quizPage.tag(1)
                signUpPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack {
                SignInView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }

    // MARK: - Screen 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            NudgeAvatar(size: 120)

            VStack(spacing: 12) {
                Text("Hi, I'm Nudge.")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(DS.textPrimary)

                Text("Most budgeting apps track your spending.\nAwareBudget tracks why you spend.")
                    .font(.title3)
                    .foregroundStyle(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get started")
                    .font(.system(size: 15, weight: .bold))
                    .goldButtonStyle()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.hPadding)

            progressDots(current: 0)
                .padding(.bottom, 32)
        }
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - Screen 2: Budget Reality Check

    private var quizPage: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    NudgeAvatar(size: 64)
                    Text("Quick question before we start.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DS.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Q1
                VStack(alignment: .leading, spacing: 10) {
                    Text("How long did your last budget last?")
                        .font(.headline)
                        .foregroundStyle(DS.textPrimary)

                    quizPill("Less than a week", selected: budgetHistory == "week", action: { budgetHistory = "week" })
                    quizPill("A month", selected: budgetHistory == "month", action: { budgetHistory = "month" })
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
                        quizPill("Never stopped \u{2014} it failed", selected: quitReason == "failed", action: { quitReason = "failed" })
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
                        Text("Continue")
                            .font(.system(size: 15, weight: .bold))
                            .goldButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DS.hPadding)
                    .transition(.opacity)
                }

                progressDots(current: 1)
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
                .foregroundStyle(DS.textPrimary)
                .multilineTextAlignment(.center)

            Text("70% abandon budgeting apps within 30 days. Not laziness \u{2014} bad design.")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
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

    // MARK: - Screen 3: Sign Up

    private var signUpPage: some View {
        SignUpFormView(
            hasCompletedOnboarding: $hasCompletedOnboarding,
            showSignIn: $showSignIn
        )
    }

    // MARK: - Progress dots

    private func progressDots(current: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color(hex: "1A5C38") : DS.textTertiary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Sign Up Form (extracted for reuse)

private struct SignUpFormView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var showSignIn: Bool

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
                    Text("Create your account")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DS.textPrimary)
                    Text("Your data stays on your device and your private Supabase account.")
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
                        .textContentType(.newPassword)
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
                            Text("Create account")
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
                    showSignIn = true
                } label: {
                    Text("Already have an account? Sign in")
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
            try await SupabaseService.shared.signUp(email: email, password: password)
            _ = try await SupabaseService.shared.fetchOrCreateBudgetMonth(for: Date())
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
