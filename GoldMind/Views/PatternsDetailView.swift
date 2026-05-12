import SwiftUI

struct PatternsDetailView: View {
    let patterns: [HomeViewModel.DailyPattern]
    let dismiss: () -> Void

    private let lessons = BiasLessonsMock.seed

    private var seenBiases: Set<String> {
        Set(patterns.map(\.biasName))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    algorithmCard
                    identifiedSection
                    unseenSection
                }
                .padding(20)
            }
            .background(DS.bg)
            .navigationTitle("Your patterns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss)
                        .foregroundStyle(DS.goldBase)
                }
            }
        }
    }

    private var algorithmCard: some View {
        NudgeSaysCard(
            message: "Patterns emerge when check-in answers and spending tags point at the same bias. More logs, sharper picture.",
            citation: "BFAS scoring · Pompian 2012 · 5:1 active vs passive weighting",
            surface: .whiteShimmer
        )
    }

    @ViewBuilder
    private var identifiedSection: some View {
        let seenLessons = lessons.filter { seenBiases.contains($0.biasName) }
        if !seenLessons.isEmpty {
            Text("IDENTIFIED")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.goldBase)

            ForEach(seenLessons, id: \.id) { lesson in
                biasRow(lesson: lesson)
            }
        }
    }

    @ViewBuilder
    private var unseenSection: some View {
        let unseenLessons = lessons.filter { !seenBiases.contains($0.biasName) }
        if !unseenLessons.isEmpty {
            Text("NOT YET SEEN (\(unseenLessons.count))")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.textTertiary)
                .padding(.top, 8)

            ForEach(unseenLessons.prefix(4), id: \.id) { lesson in
                HStack(spacing: 8) {
                    Text(lesson.emoji).font(.body)
                    Text(lesson.biasName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DS.textTertiary)
                }
            }
            if unseenLessons.count > 4 {
                Text("+ \(unseenLessons.count - 4) more to discover")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DS.textTertiary)
            }
        }
    }

    private func biasRow(lesson: BiasLesson) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(lesson.emoji).font(.title3)
                Text(lesson.biasName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
            }
            Text(lesson.shortDescription)
                .font(.caption)
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(2)
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundStyle(DS.goldBase)
                Text(firstSentence(lesson.howToCounter))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.accent)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.smallCardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.smallCardRadius)
                .stroke(DS.goldBase.opacity(0.3), lineWidth: 1)
        )
    }

    private func firstSentence(_ text: String) -> String {
        text.split(separator: ".", maxSplits: 1).first
            .map { String($0).trimmingCharacters(in: .whitespaces) + "." } ?? text
    }
}
