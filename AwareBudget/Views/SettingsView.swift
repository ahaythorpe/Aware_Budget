import SwiftUI
import RevenueCatUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasCompletedOnboarding: Bool
    @State private var isSigningOut = false
    @State private var showResetConfirm = false
    @State private var showCustomerCenter = false

    // Account
    @State private var accountEmail: String = "—"
    @State private var accountCreatedAt: Date?
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirm = false
    @State private var deleteConfirmText = ""
    @State private var isDeleting = false
    @State private var deleteError: String?

    // Finance entry — manual, no bank connection. Drives the
    // net-worth trend chart on the Insights tab.
    @State private var monthlyIncome: String = ""
    @State private var savingsBalance: String = ""
    @State private var investmentBalance: String = ""
    @State private var financeStatus: String = ""

    private let service = SupabaseService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                DS.altBg.ignoresSafeArea()

                List {
                    // MARK: - Finance (manual entry)
                    Section {
                        HStack {
                            Text("Monthly take-home")
                            Spacer()
                            TextField("$0", text: $monthlyIncome)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        HStack {
                            Text("Savings balance")
                            Spacer()
                            TextField("$0", text: $savingsBalance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        HStack {
                            Text("Investment balance")
                            Spacer()
                            TextField("$0", text: $investmentBalance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        Button {
                            Task { await saveFinanceData() }
                        } label: {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("Save trend snapshot")
                                    .font(.system(.body, weight: .semibold))
                            }
                            .foregroundStyle(DS.accent)
                        }
                        if !financeStatus.isEmpty {
                            Text(financeStatus)
                                .font(.caption)
                                .foregroundStyle(DS.textSecondary)
                        }
                    } header: {
                        Text("Net worth tracking")
                    } footer: {
                        Text("Manual entry — no bank connection. Updating today's snapshot overwrites; older snapshots are kept for the trend.")
                            .font(.caption)
                    }

                    Section {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(accountEmail)
                                .foregroundStyle(DS.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        if let createdAt = accountCreatedAt {
                            HStack {
                                Text("Member since")
                                Spacer()
                                Text(createdAt, format: .dateTime.month(.abbreviated).year())
                                    .foregroundStyle(DS.textSecondary)
                            }
                        }
                    } header: {
                        Text("Account")
                    }

                    Section {
                        Button {
                            showCustomerCenter = true
                        } label: {
                            HStack {
                                Image(systemName: "creditcard")
                                Text("Manage subscription")
                            }
                            .foregroundStyle(DS.accent)
                        }
                    } header: {
                        Text("Subscription")
                    } footer: {
                        Text("View, upgrade, or cancel your GoldMind Pro subscription.")
                            .font(.caption)
                    }

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
                        Button(role: .destructive) {
                            showDeleteAccountAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                Text("Delete account")
                            }
                        }
                        .disabled(isDeleting)
                    } header: {
                        Text("Danger zone")
                    } footer: {
                        Text("Permanently deletes your account and all your data. This cannot be undone.")
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
            .sheet(isPresented: $showCustomerCenter) {
                CustomerCenterView()
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
            .alert("Delete account?", isPresented: $showDeleteAccountAlert) {
                Button("Continue", role: .destructive) {
                    deleteConfirmText = ""
                    showDeleteAccountConfirm = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account, all check-ins, money events, bias progress, and saved balances. This cannot be undone.")
            }
            .alert("Type DELETE to confirm", isPresented: $showDeleteAccountConfirm) {
                TextField("DELETE", text: $deleteConfirmText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Delete account", role: .destructive) {
                    guard deleteConfirmText.trimmingCharacters(in: .whitespaces).uppercased() == "DELETE" else { return }
                    Task { await performDeleteAccount() }
                }
                .disabled(deleteConfirmText.trimmingCharacters(in: .whitespaces).uppercased() != "DELETE")
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Type DELETE in the box above to permanently delete your account.")
            }
            .alert("Couldn't delete account", isPresented: .init(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
            .task {
                await loadFinanceData()
                await loadAccountInfo()
            }
        }
    }

    private func loadAccountInfo() async {
        if let info = await service.fetchAccountInfo() {
            accountEmail = info.email
            accountCreatedAt = info.createdAt
        }
    }

    private func performDeleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await service.deleteAccount()
            // Reset every gate so the user lands on Onboarding next launch
            // (and on this launch, after dismiss).
            UserDefaults.standard.removeObject(forKey: "hasCompletedBFAS")
            hasCompletedOnboarding = false
            dismiss()
        } catch {
            deleteError = "Account deletion failed: \(error.localizedDescription). Please try again or contact support."
        }
    }

    /// Pre-fill the income field with the user's current value.
    /// Balances stay empty by default — they're a periodic snapshot,
    /// not a sticky setting.
    private func loadFinanceData() async {
        do {
            let income = try await service.fetchMonthlyIncome()
            if income > 0 {
                monthlyIncome = String(Int(income))
            }
        } catch {
            // Silent — user can still enter income from scratch.
        }
    }

    /// Save monthly income (always) + today's snapshot (if at least
    /// one balance was filled in). Mixed save means the user can
    /// just set income without forcing a balance entry, or just
    /// drop a balance snapshot without changing income.
    private func saveFinanceData() async {
        var savedAnything = false
        if let income = Double(monthlyIncome.filter { "0123456789.".contains($0) }), income > 0 {
            try? await service.saveMonthlyIncome(income)
            savedAnything = true
        }
        let savings = Double(savingsBalance.filter { "0123456789.".contains($0) }) ?? 0
        let investment = Double(investmentBalance.filter { "0123456789.".contains($0) }) ?? 0
        if savings > 0 || investment > 0 {
            try? await service.saveBalanceSnapshot(savings: savings, investment: investment)
            savedAnything = true
        }
        financeStatus = savedAnything ? "Saved." : "Enter at least one value."
    }
}
