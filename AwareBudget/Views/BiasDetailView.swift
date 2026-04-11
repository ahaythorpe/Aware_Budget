import SwiftUI

struct BiasDetailView: View {
    let lesson: BiasLesson
    // Mock: will come from user_bias_progress once Supabase is wired.
    var timesSeen: Int = 0

    @Environment(\.dismiss) private var dismiss

    private let deepPurple = Color(red: 0x2D/255.0, green: 0x1B/255.0, blue: 0x69/255.0)
    private let teal = Color(red: 0x00/255.0, green: 0x60/255.0, blue: 0x64/255.0)

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
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
                .foregroundStyle(deepPurple)
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
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Seen row (mock-gated)

    private var seenRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .foregroundStyle(deepPurple)
            Text("Seen \(timesSeen) time\(timesSeen == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(deepPurple.opacity(0.08))
        )
    }

    // MARK: - What it is

    private var whatItIsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "What it is")
            Text(lesson.fullExplanation)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - In real life (tinted card)

    private var inRealLifeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("IN REAL LIFE")
                .font(.caption.weight(.bold))
                .foregroundStyle(teal)
                .tracking(0.8)
            Text(lesson.realWorldExample)
                .font(.callout)
                .foregroundStyle(.primary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(teal.opacity(0.08))
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
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        BiasDetailView(lesson: BiasLessonsMock.seed[0])
    }
}
