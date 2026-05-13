import SwiftUI

/// End-of-week bias check-in. Surfaces the user's top 3 most-tagged
/// biases from the past 7 days and asks "Did this pattern show up for
/// you this week?" per bias. Yes / No / Not sure controls per row.
///
/// Each Yes → `updateBiasProgress(reflected: true)` (counts toward
/// awareness signal). Each No → `updateBiasProgress(reflected: false)`
/// (counts as "saw it but not me"). Not sure → no update.
///
/// Bella's #37 spec, shipped lean for v1.0 (2026-05-13).
struct EndOfWeekReviewSheet: View {
    let topBiases: [(biasName: String, count: Int)]
    var onClose: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var answers: [String: Answer] = [:]
    @State private var isSaving = false
    @State private var didSubmit = false

    enum Answer: String { case yes, no, notSure }

    private let service = SupabaseService.shared

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    if didSubmit {
                        completionCard
                    } else {
                        instructionsCard
                        ForEach(topBiases.prefix(3), id: \.biasName) { entry in
                            biasRow(entry.biasName, count: entry.count)
                        }
                        submitButton
                    }
                    citationFooter
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("END-OF-WEEK REVIEW")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(DS.goldText)
                Spacer()
                Button("Close") { dismiss() }
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("Your week, three patterns")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
            Text("Looking back over the last seven days. Did these patterns actually show up for you, or was something else going on?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(DS.heroGradient)
        )
    }

    private var instructionsCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("nudge")
                .resizable().scaledToFit()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("NUDGE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(DS.accent)
                Text("Yes counts more than logging. Saying \"that was me\" is the strongest awareness signal there is.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
        )
    }

    private func biasRow(_ biasName: String, count: Int) -> some View {
        let pattern = allBiasPatterns.first(where: { $0.name == biasName })
        let answer = answers[biasName]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if let pattern {
                    Image(systemName: pattern.sfSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DS.goldBase)
                        .frame(width: 28)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern?.displayName ?? biasName)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(DS.textPrimary)
                    Text("Tagged \(count)× this week")
                        .font(.caption)
                        .foregroundStyle(DS.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                answerButton(.yes,     label: "Yes, that's me", color: DS.accent,    biasName: biasName, selected: answer)
                answerButton(.no,      label: "No, different",   color: DS.warning,   biasName: biasName, selected: answer)
                answerButton(.notSure, label: "Not sure",        color: DS.textSecondary, biasName: biasName, selected: answer)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 1.5)
        )
        .premiumCardShadow()
    }

    private func answerButton(_ value: Answer, label: String, color: Color, biasName: String, selected: Answer?) -> some View {
        let isOn = selected == value
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                answers[biasName] = isOn ? nil : value
            }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(isOn ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(isOn ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(0.08))))
                .overlay(Capsule().stroke(color.opacity(isOn ? 0.5 : 0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                if isSaving { ProgressView().tint(.white) }
                Text(answeredCount > 0 ? "Save my answers" : "Skip this week")
                    .font(.system(.headline, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(answeredCount > 0 ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.textTertiary))
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .padding(.top, 6)
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image("nudge").resizable().scaledToFit().frame(width: 44, height: 44)
                Text("Logged. See you next Sunday.")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
            }
            Text("Each Yes ticked your awareness signal for that bias up by five points. The algorithm uses that to surface the right patterns next week.")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(.headline, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(DS.heroGradient))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase, lineWidth: 1.5)
        )
        .premiumCardShadow()
    }

    private var citationFooter: some View {
        Text("Active confirmation outweighs passive observation 5:1. Stone 1991 · Beck 1976.")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(DS.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 12)
    }

    private var answeredCount: Int {
        answers.values.filter { $0 != .notSure }.count
    }

    private func submit() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        for (biasName, answer) in answers {
            switch answer {
            case .yes:
                try? await service.updateBiasProgress(biasName: biasName, reflected: true)
            case .no:
                try? await service.updateBiasProgress(biasName: biasName, reflected: false)
            case .notSure:
                break
            }
        }
        withAnimation(.spring(response: 0.4)) {
            didSubmit = true
        }
        onClose()
    }
}
