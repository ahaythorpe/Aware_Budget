import SwiftUI

struct HowItWorksView: View {
    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.sectionGap) {
                    whyBudgetsFailSection
                }
                .padding(.horizontal, DS.hPadding)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("How it works")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Why budgets fail

    private var whyBudgetsFailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Why budgets fail")

            Text("Most budgets track the wrong thing. Here\u{2019}s what\u{2019}s different.")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)

            VStack(spacing: 0) {
                // Column headers
                HStack(spacing: 0) {
                    Text("")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Traditional")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(DS.textTertiary)
                        .frame(maxWidth: .infinity)
                    Text("AwareBudget")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(DS.primary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Divider()

                comparisonRow(
                    label: "Focuses on",
                    traditional: "Tracks categories",
                    aware: "Tracks behaviour"
                )
                Divider().padding(.horizontal, 14)
                comparisonRow(
                    label: "Feels like",
                    traditional: "Creates shame",
                    aware: "Creates awareness"
                )
                Divider().padding(.horizontal, 14)
                comparisonRow(
                    label: "Result",
                    traditional: "You quit",
                    aware: "You keep going"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                            .stroke(DS.paleGreen, lineWidth: 0.5)
                    )
            )

            Text("Behavioural economics shows shame reduces engagement \u{00B7} Thaler & Sunstein, 2008")
                .font(.system(size: 9))
                .italic()
                .foregroundStyle(DS.textTertiary)
        }
    }

    private func comparisonRow(label: String, traditional: String, aware: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DS.warning)
                Text(traditional)
                    .font(.caption)
                    .foregroundStyle(DS.textSecondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DS.positive)
                Text(aware)
                    .font(.caption)
                    .foregroundStyle(DS.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack { HowItWorksView() }
}
