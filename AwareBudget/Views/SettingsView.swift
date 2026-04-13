import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasCompletedOnboarding: Bool
    @State private var isSigningOut = false
    @State private var showResetConfirm = false

    private let service = SupabaseService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                DS.altBg.ignoresSafeArea()

                List {
                    Section {
                        Button(role: .destructive) {
                            isSigningOut = true
                            Task {
                                try? await service.signOut()
                                hasCompletedOnboarding = false
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign out")
                            }
                        }
                        .disabled(isSigningOut)
                    }

                    Section {
                        Button {
                            showResetConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset demo data")
                            }
                            .foregroundStyle(DS.warning)
                        }
                    } footer: {
                        Text("Clears all local check-ins, events, and streaks for testing.")
                            .font(.caption)
                    }

                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(DS.textSecondary)
                        }
                        HStack {
                            Text("Build")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                                .foregroundStyle(DS.textSecondary)
                        }
                    }

                    #if DEBUG
                    Section {
                        Button {
                            Task {
                                try? await service.signOut()
                                hasCompletedOnboarding = false
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                                Text("Reset onboarding (debug)")
                            }
                            .foregroundStyle(DS.warning)
                        }
                    } footer: {
                        Text("Signs out and returns to onboarding. Debug builds only.")
                            .font(.caption)
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DS.accent)
                }
            }
            .confirmationDialog("Reset demo data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    Task {
                        try? await service.resetUserData()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
