import SwiftUI

/// Layer C — opt-in pre-spend decision-helper checklist.
///
/// Triggered from a "Help me think this through" button on a category
/// tile (or via long-press for power users). Surfaces the user's top
/// 3 banked lessons for this (category × status) as a tickable
/// checklist. They run through it, tap "I'm ready" or "Skip", and
/// land on the normal range picker.
///
/// **Why this exists** (Gawande 2009 — *The Checklist Manifesto*):
/// brief, bias-aware checklists at the moment of decision improve
/// outcomes in domains where mistakes are repeatable and the cost is
/// known (surgery, aviation). Behavioural finance is exactly this —
/// the same biases repeat, the cost is known, but the decision still
/// happens too fast to think. The checklist activates System 2 long
/// enough to interrupt the bias.
///
/// Opt-in (not forced) so users who don't want the friction can skip.
/// Tracking via SupabaseService.recordLessonOutcome differentiates
/// users who use it from users who don't, so we can measure whether
/// the checklist actually changes behaviour vs just feels good.
struct DecisionHelperSheet: View {
    @Environment(\.dismiss) private var dismiss
    let category: String
    let plannedStatus: MoneyEvent.PlannedStatus?
    let onProceed: () -> Void

    @State private var lessons: [SupabaseService.DecisionLesson] = []
    @State private var checked: Set<UUID> = []
    @State private var loading = true

    private let service = SupabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if lessons.isEmpty {
                    emptyState
                } else {
                    lessonsList
                }
                actionsRow
                citationFooter
            }
            .padding(20)
        }
        .background(DS.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { await load() }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                Text("Think this through")
                    .font(.system(.title2, weight: .black))
                    .foregroundStyle(.white)
                    .heroTextLegibility()
            }
            Text("Quick run-through before you log. 30 seconds, then back to normal.")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .heroTextLegibility()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DS.heroGradient, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.6), lineWidth: 1)
        )
        .premiumCardShadow()
    }

    // MARK: - Lessons list

    private var lessonsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(DS.goldBase)
                Text("YOUR LESSONS FOR \(category.uppercased())")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(DS.goldBase)
            }
            ForEach(lessons.prefix(3)) { lesson in
                lessonRow(lesson)
            }
        }
    }

    private func lessonRow(_ lesson: SupabaseService.DecisionLesson) -> some View {
        let isChecked = checked.contains(lesson.id)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isChecked { checked.remove(lesson.id) }
                else { checked.insert(lesson.id) }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isChecked ? DS.goldBase : DS.textTertiary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.bias_name)
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text(lesson.counter_move)
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(DS.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(isChecked ? DS.goldBase.opacity(0.5) : DS.accent.opacity(0.15), lineWidth: isChecked ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No lessons banked yet for \(category).")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
            Text("Lessons appear here after you confirm a bias was driving a similar spend (\"Yes, that's me\" in review). Until then, just proceed.")
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Actions

    private var actionsRow: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    // Record `useful` for every checked lesson — that's
                    // the strongest signal the lesson worked.
                    for id in checked {
                        try? await service.recordLessonOutcome(id: id, outcome: .useful)
                    }
                    onProceed()
                    dismiss()
                }
            } label: {
                Text("I'm ready. Log it.")
            }
            .goldButtonStyle()

            Button {
                Task {
                    // No checks → record `dismissed` for the surfaced
                    // lessons so we know the checklist didn't help.
                    for lesson in lessons.prefix(3) where !checked.contains(lesson.id) {
                        try? await service.recordLessonOutcome(id: lesson.id, outcome: .dismissed)
                    }
                    dismiss()
                }
            } label: {
                Text("Skip. Go straight to logging.")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Citation

    private var citationFooter: some View {
        ResearchFootnote(
            text: "Pre-decision checklists · Gawande 2009 · adapted from medical + aviation evidence",
            style: .inline
        )
        .padding(.top, 4)
    }

    // MARK: - Load

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            lessons = try await service.fetchLessons(
                category: category,
                plannedStatus: plannedStatus?.rawValue
            )
            // Surfacing is recorded once per session-open, not per row,
            // to avoid skewing the usefulness denominator.
            for lesson in lessons.prefix(3) {
                try? await service.recordLessonOutcome(id: lesson.id, outcome: .surfaced)
            }
        } catch {
            lessons = []
        }
    }
}
