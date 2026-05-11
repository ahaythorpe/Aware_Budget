import SwiftUI
import AuthenticationServices
import CryptoKit

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

                    Text("Most budgeting apps track your spending.\nGoldMind tracks why you spend.")
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
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 20)

                    NudgeAvatar(size: 56)

                    Text("Quick reality check")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                        .heroTextLegibility()

                    Spacer().frame(height: 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR LAST BUDGET LASTED…")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(DS.goldText)
                            .padding(.horizontal, 4)

                        quizPill("Less than a week", selected: budgetHistory == "week", action: { budgetHistory = "week" })
                        quizPill("About a month", selected: budgetHistory == "month", action: { budgetHistory = "month" })
                        quizPill("Never tried", selected: budgetHistory == "never_tried", action: { budgetHistory = "never_tried" })
                        quizPill("Never budgeted", selected: budgetHistory == "never_budgeted", action: { budgetHistory = "never_budgeted" })
                    }
                    .padding(.horizontal, DS.hPadding)

                    if budgetHistory != nil && budgetHistory != "never_tried" && budgetHistory != "never_budgeted" {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHAT WENT WRONG?")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(DS.goldText)
                                .padding(.horizontal, 4)

                            quizPill("Too much work", selected: quitReason == "work", action: { quitReason = "work" })
                            quizPill("Guilt spiral", selected: quitReason == "guilt", action: { quitReason = "guilt" })
                            quizPill("Life happened", selected: quitReason == "life", action: { quitReason = "life" })
                            quizPill("Just didn't stick", selected: quitReason == "failed", action: { quitReason = "failed" })
                        }
                        .padding(.horizontal, DS.hPadding)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer().frame(height: 8)

                    if budgetHistory != nil && (budgetHistory == "never_tried" || budgetHistory == "never_budgeted" || quitReason != nil) {
                        nudgeResponse
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer()

                    progressDots(current: 2, total: 4, light: true)
                        .padding(.bottom, 32)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: budgetHistory)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: quitReason)
            }
        }
    }

    private var nudgeResponse: some View {
        VStack(spacing: 16) {
            NudgeSaysCard(
                message: "You're not broken. The method is. 96% of people have made a budget, but most check it once a month at most.",
                citation: "CFPB · Consumer Financial Protection Bureau",
                surface: .whiteShimmer
            )

            Button {
                withAnimation { currentPage = 3 }
            } label: {
                Text("That's why GoldMind exists \u{2192}")
            }
            .goldButtonStyle()
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, DS.hPadding)
    }

    private func quizPill(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.system(.subheadline, weight: selected ? .bold : .medium))
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(DS.goldBase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .stroke(selected ? DS.goldBase : Color.gray.opacity(0.2), lineWidth: selected ? 2 : 0.5)
            )
        }
        .buttonStyle(.plain)
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
    @State private var nonce: String = ""

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

                    SignInWithAppleButton(.continue) { request in
                        let raw = Self.makeNonce()
                        nonce = raw
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = Self.sha256(raw)
                    } onCompletion: { result in
                        Task { await handleApple(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(Capsule())
                    .padding(.horizontal, DS.hPadding)
                    .disabled(isSubmitting)
                    .opacity(isSubmitting ? 0.6 : 1)

                    HStack(spacing: 12) {
                        Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                        Text("or")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.horizontal, DS.hPadding)

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

                    #if DEBUG
                    Button {
                        UserDefaults.standard.set(true, forKey: "hasSeenNudge")
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Skip for now (DEBUG)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DS.goldText)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    #endif

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

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple didn't return a valid identity token. Please try again."
                return
            }
            do {
                try await SupabaseService.shared.signInWithApple(idToken: token, nonce: nonce)
                _ = try? await SupabaseService.shared.fetchOrCreateBudgetMonth(for: Date())
                UserDefaults.standard.set(true, forKey: "hasSeenNudge")
                hasCompletedOnboarding = true
            } catch {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    private static func makeNonce(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed: \(status)")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
