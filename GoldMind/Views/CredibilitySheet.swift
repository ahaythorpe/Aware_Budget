import SwiftUI

/// Handbook §8.1 + §1.3. Metallic-green-first credibility sheet.
/// Green hero + green body with layered gold/frosted/deep cards.
struct CredibilitySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // Trimmed 2026-05-11 — the heavy reference sections (how ranking
        // works, stage legend, BFAS framework, full citations) now live
        // in the Research tab. This sheet is now a focused card with the
        // 96% fact + how GoldMind differs. Drag up to see the full
        // version with all the extra cards.
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                    .padding(.horizontal, 22)
                    .padding(.top, 20)

                youreNotBroken
                    .padding(.horizontal, 22)

                theIdea
                    .padding(.horizontal, 22)

                theDifference
                    .padding(.horizontal, 22)

                cta
                    .padding(.horizontal, 22)
                    .padding(.bottom, 32)
            }
        }
        .background(DS.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 1. Hero (green panel on white body)

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            Text("Backed by research")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: DS.deepGreen.opacity(0.7), radius: 4, x: 0, y: 1)
                .fixedSize(horizontal: false, vertical: true)

            Text("How GoldMind ranks your patterns")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: DS.deepGreen.opacity(0.6), radius: 3, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(DS.heroGradient)
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 1)
        )
    }

    // MARK: - 2. The Idea (gold card)

    private var theIdea: some View {
        goldCard(label: "THE IDEA") {
            Text("Most budgets track the wrong thing. GoldMind tracks how you decide, not what you bought.")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 3. The Difference (frosted dark table)

    private var theDifference: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("THE DIFFERENCE")

            VStack(spacing: 0) {
                HStack {
                    Text("")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Traditional")
                        .font(.system(.caption, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(DS.textTertiary)
                        .frame(width: 96, alignment: .center)
                    Text("GoldMind")
                        .font(.system(.caption, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(DS.goldBase)
                        .frame(width: 112, alignment: .center)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(DS.paleGreen.opacity(0.5))

                compareRow("Focuses on", "Categories", "Behaviour", 0)
                compareRow("Feels like", "Shame", "Awareness", 1)
                compareRow("Based on", "Rules", "Research", 0)
                compareRow("When wrong", "You hide it", "You adjust", 1)
                compareRow("Result", "You quit", "You keep going", 0)
            }
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        }
    }

    private func compareRow(_ label: String, _ bad: String, _ good: String, _ tint: Int) -> some View {
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
                    .font(.system(.footnote, weight: .regular))
                    .foregroundStyle(DS.textSecondary)
            }
            .frame(width: 96, alignment: .center)

            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.goldBase)
                Text(good)
                    .font(.system(.footnote, weight: .bold))
                    .foregroundStyle(DS.deepGreen)
            }
            .frame(width: 112, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint == 1 ? DS.paleGreen.opacity(0.25) : Color.clear)
    }

    // MARK: - 4. How ranking works (gold card, numbered circles ①②③)

    private var howItWorks: some View {
        goldCard(label: "HOW THE RANKING WORKS") {
            VStack(alignment: .leading, spacing: 12) {
                numberedBullet(1, "Each check-in answer and tagged spend feeds your bias profile.")
                numberedBullet(2, "The algorithm ranks biases by how often they show up in your decisions.")
                numberedBullet(3, "As you notice them, they move from Active → Aware.")
            }
        }
    }

    private func numberedBullet(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(DS.nuggetGold)
                    .frame(width: 24, height: 24)
                Text("\(n)")
                    .font(.system(.footnote, weight: .heavy))
                    .foregroundStyle(DS.goldForeground)
            }
            Text(text)
                .font(.system(.subheadline, weight: .regular))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    // MARK: - 5. Stage legend (frosted dark)

    private var stageLegend: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("WHAT THE STAGES MEAN")

            VStack(spacing: 10) {
                stageRow("Unseen", DS.textTertiary, "Not yet encountered in your data")
                stageRow("Noticed", DS.stageNoticed, "Showing up occasionally")
                stageRow("Emerging", DS.stageEmerging, "Becoming a clear pattern")
                stageRow("Active", DS.stageActive, "Frequently driving decisions")
                stageRow("Aware", DS.positive, "You recognise it. Breaking the grip.")
            }
            .padding(14)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
            )
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
                .background(color.opacity(0.18), in: Capsule())
                .frame(width: 82, alignment: .leading)
            Text(desc)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 6. The Framework (gold card — BFAS)

    private var theFramework: some View {
        goldCard(label: "THE FRAMEWORK") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(DS.nuggetGold).frame(width: 40, height: 40)
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 17))
                            .foregroundStyle(DS.goldForeground)
                    }
                    Text("Built on BFAS")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                }

                Text("Used by planners before they advise. GoldMind brings those 16 patterns to everyday spending.")
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 7. Citations (2×2 gold grid)

    private var citations: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("THE RESEARCH")

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
        .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
        )
    }

    // MARK: - 8. You're not broken (solid deep panel)

    private var youreNotBroken: some View {
        VStack(spacing: 10) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            Text("You're not broken.\nThe method is.")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("96% of people have made a budget at some point. More than half check it once a month at most. Not from laziness. From apps that create shame, not awareness.")
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(DS.deepGreen, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 1)
        )
    }

    // MARK: - 9. Nudge says (gold surface variant)

    private var nudgeSays: some View {
        NudgeSaysCard(
            message: "Not a generic quiz. It's the same framework planners use, so a shared profile tells them which biases to watch.",
            citation: "BFAS · Pompian, 2012",
            surface: .whiteShimmer
        )
    }

    // MARK: - 10. CTA

    private var cta: some View {
        Button { dismiss() } label: {
            Text("Got it")
        }
        .goldButtonStyle()
        .padding(.top, 6)
    }

    // MARK: - Helpers

    /// Gold surface card with a section label + content.
    @ViewBuilder
    private func goldCard<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(label)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
                )
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(DS.goldText)
    }
}
