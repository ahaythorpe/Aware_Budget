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
            DS.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    NudgeAvatar(size: 80)

                    VStack(spacing: 8) {
                        Text("Welcome back")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(DS.textPrimary)
                        Text("Sign in to pick up where you left off.")
                            .font(.subheadline)
                            .foregroundStyle(DS.textSecondary)
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
                            .textContentType(.password)
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
                        Task { await signIn() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color(hex: "3A2000"))
                            } else {
                                Text("Sign in")
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

                    Spacer(minLength: 32)
                }
            }
        }
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
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
