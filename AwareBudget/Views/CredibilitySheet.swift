import SwiftUI

/// Handbook §8.1. Presented from TopBiasesCard ⓘ tap.
/// Explains the ranking (plain English, no formula) and surfaces the
/// canonical research that backs AwareBudget. Reuses DS tokens + §3.5 type.
struct CredibilitySheet: View {
    @Environment(\.dismiss) private var dismiss
    var onReadMore: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                shortWhy
                howItWorks
                stageLegend
                citations
                readMoreButton
            }
            .padding(22)
        }
        .background(DS.bg)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)

            Text("Backed by research")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(DS.textPrimary)

            Text("How AwareBudget ranks your patterns")
                .font(.system(.subheadline, weight: .regular))
                .foregroundStyle(DS.textSecondary)
        }
    }

    // MARK: - Short Why

    private var shortWhy: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE IDEA")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.accent)

            Text("Most budgets track the wrong thing. AwareBudget tracks how you decide, not what you bought.")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - How the ranking works (plain English, no formula)

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW THE RANKING WORKS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.accent)

            bullet("Each check-in answer and tagged spend feeds your bias profile.")
            bullet("The algorithm ranks biases by how often they show up in your decisions.")
            bullet("As you notice them, they move from Active → Aware.")
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

    // MARK: - Stage legend

    private var stageLegend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT THE STAGES MEAN")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.accent)

            stageRow("Unseen", DS.textTertiary, "Not yet encountered in your data")
            stageRow("Noticed", DS.stageNoticed, "Showing up occasionally")
            stageRow("Emerging", DS.stageEmerging, "Becoming a clear pattern")
            stageRow("Active", DS.stageActive, "Frequently driving decisions")
            stageRow("Aware", DS.positive, "You recognise it — breaking the grip")
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
                .frame(width: 78, alignment: .leading)
            Text(desc)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Citations (4 canonical papers, verified)

    private var citations: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE RESEARCH")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.accent)

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
                .font(.system(.caption2, weight: .heavy))
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

    // MARK: - CTA

    private var readMoreButton: some View {
        Button {
            dismiss()
            onReadMore?()
        } label: {
            Text("Read the full story →")
        }
        .goldButtonStyle()
        .padding(.top, 4)
    }
}
