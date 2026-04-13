import Supabase
import SwiftUI

struct SignInView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // OTP state
    @State private var showOTP = false
    @State private var otpEmail = ""
    @State private var otpCode = ""
    @State private var otpSent = false
    @State private var otpSubmitting = false
    @State private var otpMessage: String?
    @State private var otpError: String?

    var body: some View {
        ZStack {
            DS.heroGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    NudgeAvatar(size: 80)

                    VStack(spacing: 8) {
                        Text("Welcome back")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Sign in to pick up where you left off.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    if !showOTP {
                        passwordSection
                    } else {
                        otpSection
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Password sign in

    private var passwordSection: some View {
        VStack(spacing: 16) {
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
                    .textContentType(.password)
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
                Task { await signIn() }
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView()
                            .tint(DS.goldTint)
                    } else {
                        Text("Sign in")
                            .font(.system(size: 17, weight: .bold))
                    }
                    Spacer()
                }
                .foregroundStyle(DS.goldForeground)
                .padding(.vertical, 16)
                .background(DS.nuggetGold, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting || email.isEmpty || password.isEmpty)
            .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
            .padding(.horizontal, DS.hPadding)

            // Divider
            HStack {
                Rectangle().frame(height: 0.5)
                    .foregroundStyle(Color.white.opacity(0.3))
                Text("or").font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Rectangle().frame(height: 0.5)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, DS.hPadding)

            // OTP toggle
            Button("Get a sign-in code instead \u{2192}") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showOTP = true
                    otpEmail = email
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(DS.accent)
            .buttonStyle(.plain)
        }
    }

    // MARK: - OTP sign in

    private var otpSection: some View {
        VStack(spacing: 16) {
            Text("Enter your email to receive\na 6-digit code")
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                TextField("Email", text: $otpEmail, prompt: Text("Email").foregroundStyle(.white.opacity(0.5)))
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

                if otpSent {
                    SecureField("6-digit code", text: $otpCode, prompt: Text("6-digit code").foregroundStyle(.white.opacity(0.5)))
                        .textContentType(.oneTimeCode)
                    #if !os(macOS)
                        .keyboardType(.numberPad)
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
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if let otpMessage {
                    Text(otpMessage)
                        .font(.footnote)
                        .foregroundStyle(DS.accent)
                }

                if let otpError {
                    Text(otpError)
                        .font(.footnote)
                        .foregroundStyle(DS.warning)
                }
            }
            .padding(.horizontal, DS.hPadding)

            if !otpSent {
                Button {
                    Task { await sendOTP() }
                } label: {
                    HStack {
                        Spacer()
                        if otpSubmitting {
                            ProgressView()
                                .tint(DS.goldTint)
                        } else {
                            Text("Send code")
                                .font(.system(size: 17, weight: .bold))
                        }
                        Spacer()
                    }
                    .foregroundStyle(DS.goldForeground)
                    .padding(.vertical, 16)
                    .background(DS.nuggetGold, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(otpSubmitting || otpEmail.isEmpty)
                .opacity(otpEmail.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, DS.hPadding)
            } else {
                Button {
                    Task { await verifyOTP() }
                } label: {
                    HStack {
                        Spacer()
                        if otpSubmitting {
                            ProgressView()
                                .tint(DS.goldTint)
                        } else {
                            Text("Verify and sign in")
                                .font(.system(size: 17, weight: .bold))
                        }
                        Spacer()
                    }
                    .foregroundStyle(DS.goldForeground)
                    .padding(.vertical, 16)
                    .background(DS.nuggetGold, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(otpSubmitting || otpCode.isEmpty)
                .opacity(otpCode.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, DS.hPadding)
            }

            // Back to password
            Button("Use password instead") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showOTP = false
                    email = otpEmail
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: otpSent)
    }

    // MARK: - Actions

    private func signIn() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await SupabaseService.shared.signIn(email: email, password: password)
            hasCompletedOnboarding = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendOTP() async {
        otpError = nil
        otpMessage = nil
        otpSubmitting = true
        defer { otpSubmitting = false }
        do {
            try await SupabaseService.shared.client.auth.signInWithOTP(
                email: otpEmail,
                shouldCreateUser: false
            )
            withAnimation {
                otpSent = true
                otpMessage = "Code sent. Check your email."
            }
        } catch {
            otpError = error.localizedDescription
        }
    }

    private func verifyOTP() async {
        otpError = nil
        otpMessage = nil
        otpSubmitting = true
        defer { otpSubmitting = false }
        do {
            try await SupabaseService.shared.client.auth.verifyOTP(
                email: otpEmail,
                token: otpCode,
                type: .email
            )
            hasCompletedOnboarding = true
            dismiss()
        } catch {
            otpError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SignInView(hasCompletedOnboarding: .constant(false))
    }
}
