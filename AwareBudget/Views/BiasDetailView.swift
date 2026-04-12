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
                .foregroundStyle(Color(hex: "4CAF50"))
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
