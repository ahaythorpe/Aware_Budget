import SwiftUI

/// Handbook §8.1. Absorbs all content formerly on the Why tab.
/// Presented from TopBiasesCard ⓘ tap. 10 sections top-to-bottom.
struct CredibilitySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                theIdea
                theDifference
                howItWorks
                stageLegend
                theFramework
                citations
                youreNotBroken
                nudgeSays
                cta
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(DS.bg)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 1. Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Backed by research")
                .font(.system(.largeTitle, design: .default, weight: .bold))
                .foregroundStyle(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("How AwareBudget ranks your patterns")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(DS.textSecondary)
        }
    }

    // MARK: - 2. The Idea

    private var theIdea: some View {
        section(label: "THE IDEA") {
            Text("Most budgets track the wrong thing. AwareBudget tracks how you decide, not what you bought.")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 3. The Difference (comparison table, absorbed from Why)

    private var theDifference: some View {
        section(label: "THE DIFFERENCE") {
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Traditional")
                        .font(.system(.caption2, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(DS.textTertiary)
                        .frame(width: 92, alignment: .center)
                    Text("AwareBudget")
                        .font(.system(.caption2, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(DS.accent)
                        .frame(width: 108, alignment: .center)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DS.paleGreen.opacity(0.6))

                compareRow("Focuses on", "Categories", "Behaviour")
                compareRow("Feels like", "Shame", "Awareness")
                compareRow("Based on", "Rules", "Research")
                compareRow("When wrong", "You hide it", "You adjust")
                compareRow("Result", "You quit", "You keep going")
            }
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DS.accent.opacity(0.18), lineWidth: 0.5)
            )
        }
    }

    private func compareRow(_ label: String, _ bad: String, _ good: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.footnote, weight: .bold))
                .foregroundStyle(DS.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.warning)
                Text(bad)
                    .font(.system(.caption, weight: .regular))
                    .foregroundStyle(DS.textSecondary)
            }
            .frame(width: 92, alignment: .center)

            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.positive)
                Text(good)
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(DS.deepGreen)
            }
            .frame(width: 108, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(DS.accent.opacity(0.1)), alignment: .bottom)
    }

    // MARK: - 4. How ranking works

    private var howItWorks: some View {
        section(label: "HOW THE RANKING WORKS") {
            VStack(alignment: .leading, spacing: 10) {
                bullet("Each check-in answer and tagged spend feeds your bias profile.")
                bullet("The algorithm ranks biases by how often they show up in your decisions.")
                bullet("As you notice them, they move from Active → Aware.")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(DS.accent)
                .frame(width: 5, height: 5)
                .padding(.top, 8)
            Text(text)
                .font(.system(.subheadline, weight: .regular))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 5. Stage legend

    private var stageLegend: some View {
        section(label: "WHAT THE STAGES MEAN") {
            VStack(alignment: .leading, spacing: 10) {
                stageRow("Unseen", DS.textTertiary, "Not yet encountered in your data")
                stageRow("Noticed", DS.stageNoticed, "Showing up occasionally")
                stageRow("Emerging", DS.stageEmerging, "Becoming a clear pattern")
                stageRow("Active", DS.stageActive, "Frequently driving decisions")
                stageRow("Aware", DS.positive, "You recognise it — breaking the grip")
            }
        }
    }

    private func stageRow(_ label: String, _ color: Color, _ desc: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.15), in: Capsule())
                .frame(width: 82, alignment: .leading)
            Text(desc)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 6. The Framework (absorbed from Why BFAS card)

    private var theFramework: some View {
        section(label: "THE FRAMEWORK") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(DS.paleGreen).frame(width: 36, height: 36)
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 16))
                            .foregroundStyle(DS.deepGreen)
                    }
                    Text("Built on BFAS")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                }

                Text("The Behavioural Finance Assessment Score is used by professional financial planners before giving advice. AwareBudget brings that same framework to everyday spending — the same 16 patterns, adapted for daily life.")
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(DS.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DS.accent.opacity(0.18), lineWidth: 0.5)
            )
        }
    }

    // MARK: - 7. Citations

    private var citations: some View {
        section(label: "THE RESEARCH") {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                citationCard(author: "Pompian", year: "2012", title: "BFAS framework")
                citationCard(author: "Kahneman & Tversky", year: "1979", title: "Prospect Theory")
                citationCard(author: "Thaler & Sunstein", year: "2008", title: "Nudge")
                citationCard(author: "Kahneman et al.", year: "2004", title: "Day Reconstruction")
            }
        }
    }

    private func citationCard(author: String, year: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 11))
                .foregroundStyle(DS.goldBase)
            Text("\(author), \(year)")
                .font(.system(.footnote, weight: .heavy))
                .foregroundStyle(DS.textPrimary)
            Text(title)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "FFF8E1"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.goldBase.opacity(0.25), lineWidth: 0.5)
        )
    }

    // MARK: - 8. You're not broken

    private var youreNotBroken: some View {
        VStack(spacing: 10) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            Text("You're not broken.\nThe method is.")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("70% of people abandon budgeting apps within 30 days. Not from laziness — from apps that create shame, not awareness.")
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(DS.heroGradient, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.deepGreen, lineWidth: 1)
        )
    }

    // MARK: - 9. Nudge says (in-context)

    private var nudgeSays: some View {
        NudgeSaysCard(
            message: "This is not a generic quiz. It's the same framework professional planners use — so when you share your profile, they know exactly which biases to watch for in your decisions.",
            citation: "BFAS · Pompian, 2012"
        )
    }

    // MARK: - 10. CTA

    private var cta: some View {
        Button { dismiss() } label: {
            Text("Got it")
        }
        .goldButtonStyle()
        .padding(.top, 4)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.accent)
            content()
        }
    }
}
