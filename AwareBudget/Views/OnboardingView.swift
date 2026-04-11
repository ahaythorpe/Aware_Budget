import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    steps
                    signUpForm
                    Spacer(minLength: 40)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AwareBudget")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Text("Stay aware. Adjust early. No shame.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepRow(number: "1",
                    title: "Check in daily",
                    detail: "One behavioural question. 60 seconds.")
            stepRow(number: "2",
                    title: "Log money events",
                    detail: "Surprises, wins, and expected costs — all manual.")
            stepRow(number: "3",
                    title: "Stay aware",
                    detail: "Build a streak. Watch alignment. No shame.")
        }
    }

    private var signUpForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create your account")
                .font(.headline)
                .foregroundStyle(.primary)

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocorrectionDisabled(true)
            #if !os(macOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            #endif
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await submit() }
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Get started")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting || email.isEmpty || password.isEmpty)
            .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
        }
        .padding(.top, 12)
    }

    private func stepRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            hasCompletedOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
