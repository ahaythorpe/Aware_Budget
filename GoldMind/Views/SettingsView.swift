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

    // Profile (display preferences from public.profiles)
    @State private var displayName: String = ""
    @State private var hideName: Bool = false
    @State private var hideEmail: Bool = false
    @State private var profileStatus: String = ""
    @State private var profileLoaded = false
    @State private var archetypeName: String? = nil
    @State private var streak: Int = 0
    @State private var biasesIdentified: Int = 0

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
                    // MARK: - Profile header card
                    Section {
                        profileHeaderCard
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

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
                        Text("Manual entry, no bank connection. Updating today's snapshot overwrites; older snapshots are kept for the trend.")
                            .font(.caption)
                    }

                    Section {
                        HStack {
                            Text("Display name")
                            Spacer()
                            TextField("Your name", text: $displayName)
                                .multilineTextAlignment(.trailing)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .frame(maxWidth: 200)
                        }
                        Toggle("Hide my name in greetings", isOn: $hideName)
                        Toggle("Hide my email below", isOn: $hideEmail)
                        Button {
                            Task { await saveProfile() }
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                Text("Save profile")
                                    .font(.system(.body, weight: .semibold))
                            }
                            .foregroundStyle(DS.accent)
                        }
                        if !profileStatus.isEmpty {
                            Text(profileStatus)
                                .font(.caption)
                                .foregroundStyle(DS.textSecondary)
                        }
                    } header: {
                        Text("Profile")
                    } footer: {
                        Text("Your display name appears in greetings and Nudge messages. Hiding it shows \"there\" instead. Hiding your email replaces it with masked text in the Account section below.")
                            .font(.caption)
                    }

                    Section {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(hideEmail ? maskedEmail(accountEmail) : accountEmail)
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
                        Link(destination: AppConfig.supportMailtoURL) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("Contact support")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(DS.textTertiary)
                            }
                            .foregroundStyle(DS.textPrimary)
                        }
                    } header: {
                        Text("Help")
                    } footer: {
                        Text("Refunds are processed by Apple at reportaproblem.apple.com. For anything else, email us. We read every message.")
                            .font(.caption)
                    }

                    Section {
                        Link(destination: AppConfig.termsOfServiceURL) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Terms of Service")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundStyle(DS.textTertiary)
                            }
                            .foregroundStyle(DS.textPrimary)
                        }
                        Link(destination: AppConfig.privacyPolicyURL) {
                            HStack {
                                Image(systemName: "lock.shield")
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundStyle(DS.textTertiary)
                            }
                            .foregroundStyle(DS.textPrimary)
                        }
                    } header: {
                        Text("Legal")
                    }

                    #if DEBUG
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
                        Text("DEBUG only. Clears your local check-ins, events, and bias progress.")
                            .font(.caption)
                    }
                    #endif

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
                await loadProfile()
            }
        }
    }

    private func loadAccountInfo() async {
        if let info = await service.fetchAccountInfo() {
            accountEmail = info.email
            accountCreatedAt = info.createdAt
        }
    }

    // MARK: - Profile header card

    /// Big avatar + name + personality chip + streak/bias stats. Sits at
    /// the very top of Settings so the gear-icon entry feels like opening
    /// a real profile, not a preferences screen. Read-only display; the
    /// editable fields live in the Profile section below.
    private var profileHeaderCard: some View {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameForCard = trimmed.isEmpty ? "Set your name" : trimmed
        return VStack(spacing: 14) {
            AvatarDisc(name: trimmed.isEmpty ? nil : trimmed, size: 76)

            VStack(spacing: 4) {
                Text(nameForCard)
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundStyle(DS.textPrimary)
                if let arch = archetypeName, !arch.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text("The \(arch)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(0.4)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(DS.heroGradient))
                } else {
                    Text("Take the Money Mind Quiz to find yours")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }
            }

            // Stats row — streak + biases identified. Quiet, not loud.
            HStack(spacing: 0) {
                statColumn(value: "\(streak)", label: "Day streak")
                Divider().frame(height: 32)
                statColumn(value: "\(biasesIdentified)/16", label: "Biases seen")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DS.goldBase.opacity(0.25), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(DS.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, 16)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(DS.goldBase)
            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(DS.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadProfile() async {
        guard let profile = try? await service.fetchProfile() else { return }
        displayName = profile.displayName ?? ""
        hideName = profile.hideName
        hideEmail = profile.hideEmail
        archetypeName = profile.archetype
        profileLoaded = true

        // Stats for the profile card. Counts are best-effort and silent
        // on failure — they're not load-bearing for the screen itself.
        if let history = try? await service.fetchRecentCheckIns(limit: 1),
           let today = history.first {
            streak = today.streakCount
        }
        // Mirror HomeViewModel.biasesSeenCount: union of bias_progress
        // (timesEncountered > 0) + this-month event behaviour tags.
        if let progress = try? await service.fetchBiasProgress(),
           let events = try? await service.fetchMoneyEvents(forMonth: Date()) {
            let progressNames = Set(progress.filter { $0.timesEncountered > 0 }.map(\.biasName))
            let tagNames = Set(events.compactMap(\.behaviourTag))
            biasesIdentified = progressNames.union(tagNames).count
        }
    }

    private func saveProfile() async {
        guard profileLoaded else { return }
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await service.updateProfile(ProfileUpdate(
                displayName: trimmed.isEmpty ? nil : trimmed,
                hideName: hideName,
                hideEmail: hideEmail
            ))
            profileStatus = "Saved."
        } catch {
            profileStatus = "Couldn't save: \(error.localizedDescription)"
        }
    }

    /// Masks an email for cosmetic display when `hideEmail` is on.
    /// Example: "a.haythorpe@hotmail.com" → "a•••@hotmail.com".
    /// Purely visual — does not affect auth or what Supabase has stored.
    private func maskedEmail(_ email: String) -> String {
        guard let atIdx = email.firstIndex(of: "@") else { return email }
        let local = email[..<atIdx]
        let domain = email[atIdx...]
        guard let firstChar = local.first else { return email }
        return "\(firstChar)•••\(domain)"
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
