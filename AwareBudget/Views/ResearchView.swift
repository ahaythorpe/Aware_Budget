import SwiftUI

/// 5th tab — Research / Library. Surfaces the credibility content for users
/// who want the deep-dive. Permanent home for the 4 canonical papers, BFAS
/// framework, all 16 biases with citations, and plain-English algorithm
/// transparency. CredibilitySheet stays as the in-context popup behind ⓘ.
struct ResearchView: View {
    private let papers: [Paper] = [
        .init(author: "Pompian", year: "2012",
              title: "Behavioral Finance and Wealth Management",
              detail: "Codifies the BFAS framework AwareBudget uses — 16 patterns, behavioural investor types, used by professional financial planners."),
        .init(author: "Kahneman & Tversky", year: "1979",
              title: "Prospect Theory",
              detail: "The original behavioural-economics paper. Loss aversion, framing, reference points. Econometrica 47(2):263–291."),
        .init(author: "Thaler & Sunstein", year: "2008",
              title: "Nudge",
              detail: "Choice architecture. Why default options matter. The book Nudge (the character) is named after."),
        .init(author: "Kahneman et al.", year: "2004",
              title: "Day Reconstruction Method",
              detail: "Why daily check-ins beat single survey moments. Science 306(5702):1776–1780."),
    ]

    struct Paper: Identifiable {
        let id = UUID()
        let author: String
        let year: String
        let title: String
        let detail: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                papersSection
                frameworkSection
                howRankingWorks
                allBiasesSection
                Spacer(minLength: 32)
            }
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 12)
        }
        .background(DS.bg.ignoresSafeArea())
        .navigationTitle("Research")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero (green moment)

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("The science behind it")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: DS.deepGreen.opacity(0.7), radius: 4, x: 0, y: 1)

            Text("Where AwareBudget's patterns come from, and how the ranking works.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: DS.deepGreen.opacity(0.6), radius: 3, x: 0, y: 1)
                .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - Papers

    private var papersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("THE FOUR PAPERS")
            VStack(spacing: 10) {
                ForEach(papers) { paper in
                    paperCard(paper)
                }
            }
        }
    }

    private func paperCard(_ p: Paper) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.goldBase)
                Text("\(p.author), \(p.year)")
                    .font(.system(.headline, weight: .heavy))
                    .foregroundStyle(DS.textPrimary)
            }
            Text(p.title)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DS.deepGreen)
            Text(p.detail)
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
        .shimmeringGoldBorder(cornerRadius: 14)
    }

    // MARK: - BFAS Framework card

    private var frameworkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("THE FRAMEWORK")
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
                Text("Behavioural Finance Assessment Score is the framework professional financial planners use to assess client behaviour before giving advice. AwareBudget brings the same 16 patterns to everyday spending — adapted from a one-off assessment into a daily awareness practice.")
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
            .shimmeringGoldBorder(cornerRadius: 14)
        }
    }

    // MARK: - Ranking explanation (plain English)

    private var howRankingWorks: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("HOW THE RANKING WORKS")
            VStack(alignment: .leading, spacing: 12) {
                bulletRow(1, "Each check-in answer and tagged spend feeds your bias profile.")
                bulletRow(2, "The algorithm ranks biases by how often they show up in your decisions.")
                bulletRow(3, "As you notice them, they move from Active → Aware.")
                bulletRow(4, "Your first BFAS assessment seeds the baseline — daily data overrides it over time.")
            }
            .padding(16)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
            .shimmeringGoldBorder(cornerRadius: 14)
        }
    }

    private func bulletRow(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(DS.nuggetGold).frame(width: 24, height: 24)
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

    // MARK: - All 16 biases with citations

    private var allBiasesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ALL 16 BIASES")
            VStack(spacing: 8) {
                ForEach(allBiasPatterns) { p in
                    biasRow(p)
                }
            }
        }
    }

    private func biasRow(_ p: BiasPattern) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: p.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.goldBase)
                    .frame(width: 24)
                Text(p.name)
                    .font(.system(.subheadline, weight: .heavy))
                    .foregroundStyle(DS.textPrimary)
            }
            Text(p.oneLiner)
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            ResearchFootnote(text: p.keyRef)
                .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(DS.goldBase)
    }
}
