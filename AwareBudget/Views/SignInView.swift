import SwiftUI

struct SignInView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

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
                                    .tint(Color(hex: "3A2000"))
                            } else {
                                Text("Sign in")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            Spacer()
                        }
                        .foregroundStyle(Color(hex: "1B3A00"))
                        .padding(.vertical, 16)
                        .background(DS.nuggetGold, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting || email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
                    .padding(.horizontal, DS.hPadding)

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
}

#Preview {
    NavigationStack {
        SignInView(hasCompletedOnboarding: .constant(false))
    }
}
