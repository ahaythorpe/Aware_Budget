import SwiftUI

struct BiasDetailView: View {
    let lesson: BiasLesson
    var timesSeen: Int = 0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    shortDescription
                    if timesSeen > 0 {
                        seenRow
                    }
                    whatItIsSection
                    inRealLifeSection
                    howToCounterSection
                    researchSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, DS.hPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(lesson.biasName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lesson.emoji)
                .font(.system(size: 72))
            Text(lesson.biasName)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(DS.textPrimary)
            categoryPill
        }
    }

    private var categoryPill: some View {
        let colours = LearnView.categoryColour(for: lesson.category)
        return Text(lesson.category)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(colours.bg))
            .foregroundStyle(colours.text)
    }

    // MARK: - Short description

    private var shortDescription: some View {
        Text(lesson.shortDescription)
            .font(.title3)
            .foregroundStyle(DS.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Seen row

    private var seenRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .foregroundStyle(DS.accent)
            Text("Seen \(timesSeen) time\(timesSeen == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.textPrimary)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DS.paleGreen)
        )
    }

    // MARK: - What it is

    private var whatItIsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "What it is")
            Text(lesson.fullExplanation)
                .font(.body)
                .foregroundStyle(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - In real life

    private var inRealLifeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "In real life")
            Text(lesson.realWorldExample)
                .font(.callout)
                .foregroundStyle(DS.textPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DS.paleGreen)
                )
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Research (handbook §8.2 sprinkle)

    private var researchSection: some View {
        let citation = allBiasPatterns.first(where: { $0.name == lesson.biasName })?.citation
        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "The research")
            if let citation {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.goldBase)
                        .padding(.top, 2)
                    Text(citation)
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(DS.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "FFF8E1"), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(DS.goldBase.opacity(0.25), lineWidth: 0.5)
                )
            } else {
                Text("Citation coming soon.")
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(DS.textTertiary)
            }
        }
    }

    // MARK: - How to counter it

    private var howToCounterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "How to counter it")
            Text(lesson.howToCounter)
                .font(.body)
                .foregroundStyle(DS.textPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DS.paleGreen)
                )
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        BiasDetailView(lesson: BiasLessonsMock.seed[0])
    }
}
