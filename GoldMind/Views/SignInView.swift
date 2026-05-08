import SwiftUI
import AuthenticationServices
import CryptoKit

/// Sits between Onboarding and BFAS in the gate. Single CTA: Sign in with
/// Apple. Required because Apple Guideline 5.1.1(v) ties account deletion
/// to account creation — the app can't delete what it never created.
struct SignInView: View {
    @State private var nonce: String = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            DS.heroGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)

                Text("Save your progress")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Sign in to keep your bias profile and check-ins on every device.")
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                SignInWithAppleButton(.continue) { request in
                    let raw = Self.makeNonce()
                    nonce = raw
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = Self.sha256(raw)
                } onCompletion: { result in
                    Task { await handle(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .clipShape(Capsule())
                .padding(.horizontal, 24)
                .disabled(isSigningIn)
                .opacity(isSigningIn ? 0.6 : 1)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                Text("Your Apple ID stays private — we only get the email you choose to share.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) async {
        isSigningIn = true
        defer { isSigningIn = false }

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
                errorMessage = nil
                // AuthStore picks up the session change; the gate will
                // re-render and route forward.
            } catch {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            // User canceling the sheet is not an error worth showing.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Nonce helpers (Apple Sign In flow requirement)

    /// Cryptographically random nonce. Apple receives the SHA-256 hash;
    /// Supabase needs the raw value to verify Apple's signature.
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
