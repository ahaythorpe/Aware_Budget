import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AwareBudget")
                        .font(.largeTitle.bold())
                    Text("Stay aware. Adjust early. No shame.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Create your account")
                        .font(.headline)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

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
                            } else {
                                Text("Get started")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSubmitting || email.isEmpty || password.isEmpty)
                }
                .padding(.top, 12)
            }
            .padding(24)
        }
    }

    private func stepRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
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
