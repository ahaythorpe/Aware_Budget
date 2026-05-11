import SwiftUI

/// Friendly first-launch prompt asking the user what Nudge should call them.
/// Shown when `profile.display_name` is empty AND the user hasn't been
/// asked yet (`hasPromptedForName` AppStorage flag). Bypassed once dismissed,
/// even on Skip — the user can always set their name later in Settings.
///
/// Why this exists: Apple Sign-In with Hide My Email returns no name on
/// subsequent sign-ins, so users end up greeted as "there". This is the
/// recovery flow.
struct NamePromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasPromptedForName") private var hasPromptedForName: Bool = false
    @State private var name: String = ""
    @State private var isSaving: Bool = false
    @State private var errorText: String? = nil
    @FocusState private var fieldFocused: Bool

    var onSaved: (String) -> Void = { _ in }

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool {
        !trimmed.isEmpty && !isSaving
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 22) {
                header
                inputCard
                if let err = errorText {
                    Text(err)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.red)
                }
                Spacer()
                footerButtons
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled(false)
        .onAppear { fieldFocused = true }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
            Text("What should I call you?")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Just a first name is fine. You can change it any time in Settings.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var inputCard: some View {
        TextField("Your name", text: $name)
            .focused($fieldFocused)
            .textContentType(.givenName)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit { if canSave { Task { await save() } } }
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(DS.textPrimary)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
            )
    }

    private var footerButtons: some View {
        VStack(spacing: 10) {
            Button {
                Task { await save() }
            } label: {
                HStack(spacing: 8) {
                    if isSaving { ProgressView().tint(.white) }
                    Text("Save")
                }
            }
            .goldButtonStyle()
            .opacity(canSave ? 1 : 0.45)
            .disabled(!canSave)

            Button("Skip for now") {
                hasPromptedForName = true
                dismiss()
            }
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(DS.textSecondary)
            .padding(.top, 4)
        }
    }

    private func save() async {
        guard canSave else { return }
        isSaving = true
        errorText = nil
        do {
            try await SupabaseService.shared.updateProfile(
                ProfileUpdate(displayName: trimmed, hideName: nil, hideEmail: nil)
            )
            hasPromptedForName = true
            await MainActor.run {
                onSaved(trimmed)
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorText = "Couldn't save. Try again."
                isSaving = false
            }
        }
    }
}

#Preview {
    NamePromptSheet()
}
