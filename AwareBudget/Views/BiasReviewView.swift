import SwiftUI

/// Post-session bias review — user confirms or denies each suggested bias
/// one at a time. Self-identification reduces the score (awareness);
/// blind spots stay at their tagged weight.
///
/// Writes to `SupabaseService.updateBiasProgress(biasName:reflected:)`:
/// - "Yes, that's me" -> reflected: true   (awareness signal)
/// - "Not sure"       -> no call            (blind spot stays)
/// - "Different"      -> re-tag TODO        (handled locally for now)
struct BiasReviewView: View {
    let entries: [Entry]
    var onDone: (ReviewOutcome) -> Void

    struct Entry: Identifiable {
        let id = UUID()
        let eventId: UUID?
        let emoji: String
        let category: String
        let amountLabel: String
        let plannedStatus: MoneyEventPlannedStatus
        let suggestedBias: String
    }

    /// Repeating the PlannedStatus protocol from MoneyEvent so this view
    /// has no dependency on the model file shape.
    typealias MoneyEventPlannedStatus = MoneyEvent.PlannedStatus

    enum Choice { case identified, notSure, different }

    struct ReviewOutcome {
        var identifiedCount: Int = 0
        var notSureCount: Int = 0
        var differentCount: Int = 0
    }

    @State private var index: Int = 0
    @State private var outcome = ReviewOutcome()
    @State private var isWriting = false
    /// When set, show the alternative-bias picker instead of the default buttons
    /// for this entry. User must pick a different bias before advancing.
    @State private var pickingAlternativeFor: Entry? = nil
    @State private var showAlgoExplainer: Bool = false
    @State private var otherReasonText: String = ""
    @State private var showOtherReasonField: Bool = false
    @FocusState private var otherReasonFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let service = SupabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let entry = currentEntry {
                    if entry.eventId != nil {
                        eventRecapCard(entry)
                    }
                    biasExplanationCard(entry)
                    if let picking = pickingAlternativeFor, picking.id == entry.id {
                        alternativePicker(entry)
                    } else {
                        choiceButtons(entry)
                    }
                } else {
                    completionCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(DS.bg.ignoresSafeArea())
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: index)
    }

    private var currentEntry: Entry? {
        guard index < entries.count else { return nil }
        return entries[index]
    }

    // MARK: - Header (green hero matching Research / CredibilitySheet pattern)

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review your patterns")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: DS.deepGreen.opacity(0.7), radius: 4, x: 0, y: 1)
                .fixedSize(horizontal: false, vertical: true)

            Text(index < entries.count
                 ? "\(index + 1) of \(entries.count) · Did we get this right?"
                 : "All done")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: DS.deepGreen.opacity(0.6), radius: 3, x: 0, y: 1)

            HStack(spacing: 6) {
                ForEach(0..<entries.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= index ? DS.goldBase : Color.white.opacity(0.25))
                        .frame(height: 4)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
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

    // MARK: - Event recap (top card)

    private func eventRecapCard(_ entry: Entry) -> some View {
        HStack(spacing: 14) {
            Text(entry.emoji).font(.system(size: 36))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                Text("\(entry.plannedStatus.emoji) \(entry.plannedStatus.label)")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
            Text(entry.amountLabel)
                .font(.system(.headline, weight: .heavy))
                .foregroundStyle(DS.goldBase)
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius, lineWidth: 2.5)
        .premiumCardShadow()
    }

    // MARK: - Bias explanation (gold card)

    private func biasExplanationCard(_ entry: Entry) -> some View {
        let insight = driverInsights[entry.suggestedBias]
        let pattern = allBiasPatterns.first(where: { $0.name == entry.suggestedBias })
        let citation = pattern?.keyRef ?? ""
        let category = pattern?.category ?? ""

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("TAGGED BY THE MODEL")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color(hex: "8B6010"))
                if !category.isEmpty {
                    Text("·")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(Color(hex: "8B6010").opacity(0.6))
                    Text(category.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(Color(hex: "8B6010").opacity(0.75))
                }
                Spacer()
            }

            Text(entry.suggestedBias)
                .font(.system(.title2, weight: .black))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Fill cards (no eventId) use the pool question stored in entry.category;
            // event-anchored cards fall back to bias-specific contextual question.
            if entry.eventId == nil {
                Text(entry.category)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(.black)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let question = biasQuestion(bias: entry.suggestedBias, category: entry.category, status: entry.plannedStatus) {
                Text(question)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(.black)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let insight {
                Text(insight.means)
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(Color(hex: "3A2000"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !citation.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8B6010"))
                    Text(citation)
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(Color(hex: "8B6010"))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(DS.goldSurfaceBg)
                .shimmerOverlay(duration: 5.5, intensity: 0.14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.7), lineWidth: 2.5)
        )
        .premiumCardShadow()
    }

    // MARK: - Choice buttons

    private func choiceButtons(_ entry: Entry) -> some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button { showAlgoExplainer = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 13))
                        Text("How scoring works")
                            .font(.system(.caption, weight: .semibold))
                    }
                    .foregroundStyle(DS.goldBase)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 2)

            reviewButton(
                icon: "checkmark.circle.fill",
                label: "Yes, that's me",
                tint: DS.positive
            ) {
                Task { await record(entry: entry, choice: .identified) }
            }
            reviewButton(
                icon: "questionmark.circle.fill",
                label: "Not sure",
                tint: DS.warning
            ) {
                Task { await record(entry: entry, choice: .notSure) }
            }
            reviewButton(
                icon: "arrow.triangle.2.circlepath.circle.fill",
                label: "No, different reason",
                tint: DS.textSecondary
            ) {
                pickingAlternativeFor = entry
            }
        }
        .disabled(isWriting)
        .sheet(isPresented: $showAlgoExplainer) {
            AlgorithmExplainerSheet()
        }
    }

    private func reviewButton(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .shimmeringGoldBorder(cornerRadius: DS.cardRadius, lineWidth: 2.5)
            .premiumCardShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Alternative picker ("No, different reason" branch)

    /// 16 candidate biases, excluding the one Nudge suggested. User must
    /// pick one or cancel back — not just skip silently. Nudge motivation
    /// line at top to encourage thoughtful pick over trigger-happy escape.
    private func alternativePicker(_ entry: Entry) -> some View {
        let candidates = allBiasPatterns
            .map(\.name)
            .filter { $0 != entry.suggestedBias }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(DS.goldBase)
                Text("Nudge: noticing the real reason matters more than clicking fast. Pick the pattern that actually fit.")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.goldSurfaceStroke, lineWidth: 0.5))

            Text("PICK THE REAL PATTERN")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.goldBase)
                .padding(.top, 4)

            VStack(spacing: 8) {
                ForEach(candidates, id: \.self) { alt in
                    Button {
                        Task { await recordAlternative(entry: entry, newBias: alt) }
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text(biasEmoji(alt))
                                .font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(alt)
                                    .font(.system(.subheadline, weight: .bold))
                                    .foregroundStyle(DS.textPrimary)
                                Text(biasHint(alt))
                                    .font(.system(.caption, weight: .medium))
                                    .foregroundStyle(DS.textSecondary)
                                    .lineSpacing(2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DS.textTertiary)
                                .padding(.top, 4)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.goldBase.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(isWriting)
                }
            }

            // "Other — doesn't fit any of these" expandable row
            VStack(spacing: 8) {
                Button {
                    withAnimation { showOtherReasonField.toggle() }
                    if showOtherReasonField { otherReasonFocused = true }
                } label: {
                    HStack(spacing: 10) {
                        Text("✏️").font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Other — doesn't fit any of these")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(DS.textPrimary)
                            Text("Type what the real reason was")
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(DS.textSecondary)
                        }
                        Spacer()
                        Image(systemName: showOtherReasonField ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DS.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.goldBase.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isWriting)

                if showOtherReasonField {
                    VStack(spacing: 10) {
                        TextField("e.g. I was bored and wanted a treat", text: $otherReasonText, axis: .vertical)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .focused($otherReasonFocused)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.goldBase.opacity(0.4), lineWidth: 1))

                        Button {
                            Task { await recordOtherReason(entry: entry, reason: otherReasonText) }
                        } label: {
                            Text("Save reason →")
                        }
                        .goldButtonStyle()
                        .disabled(otherReasonText.trimmingCharacters(in: .whitespaces).isEmpty || isWriting)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.top, 4)

            Button {
                pickingAlternativeFor = nil
                showOtherReasonField = false
                otherReasonText = ""
            } label: {
                Text("Back to suggestions")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(DS.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    /// User typed their own reason — save it to the money event's note
    /// field, don't retag the bias (we don't know what to tag it as).
    /// Counts as "different" for outcome tracking.
    @MainActor
    private func recordOtherReason(entry: Entry, reason: String) async {
        isWriting = true
        defer { isWriting = false }
        let trimmed = reason.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        outcome.differentCount += 1
        if let eventId = entry.eventId {
            try? await service.appendEventNote(id: eventId, note: trimmed)
        }
        pickingAlternativeFor = nil
        showOtherReasonField = false
        otherReasonText = ""
        withAnimation { index += 1 }
    }

    @MainActor
    private func recordAlternative(entry: Entry, newBias: String) async {
        isWriting = true
        defer { isWriting = false }
        outcome.differentCount += 1
        // Retag the stored money event so history reflects the corrected bias.
        if let eventId = entry.eventId {
            try? await service.retagMoneyEvent(id: eventId, newTag: newBias)
        }
        // Credit the user's chosen bias as reflected (awareness gained).
        try? await service.updateBiasProgress(biasName: newBias, reflected: true)
        pickingAlternativeFor = nil
        withAnimation { index += 1 }
    }

    /// Plain-English one-liner for each of the 16 biases. Shown as the
    /// subtitle in the alternative-bias picker so the user can pick without
    /// needing to know the theory.
    private func biasHint(_ bias: String) -> String {
        switch bias {
        case "Social Proof":          return "Others were doing it, so I did too"
        case "Availability Heuristic": return "A recent vivid memory pulled me in"
        case "Status Quo Bias":        return "I defaulted — it's just what I do"
        case "Anchoring":              return "A reference price made it feel fair"
        case "Scarcity Heuristic":     return "Urgency ('only a few left') pushed me"
        case "Ego Depletion":          return "I was tired, stressed, or decision-fatigued"
        case "Mental Accounting":      return "This money felt 'different' — bonus, refund, fun money"
        case "Moral Licensing":        return "I'd earned it — recent good behaviour justified this"
        case "Present Bias":           return "Now mattered more than future me"
        case "Planning Fallacy":       return "It cost way more than I thought it would"
        case "Loss Aversion":          return "Fear of missing / losing drove it"
        case "Sunk Cost Fallacy":      return "I'd already spent on this — kept going"
        case "Overconfidence Bias":    return "I was sure — more sure than I should've been"
        case "Framing Effect":         return "How it was sold ('save 30%') shaped my choice"
        case "Denomination Effect":    return "Tap/card felt less real than cash"
        case "Ostrich Effect":         return "I avoided info that might've stopped me"
        default:                       return ""
        }
    }

    private func biasEmoji(_ bias: String) -> String {
        BiasLessonsMock.seed.first(where: { $0.biasName == bias })?.emoji ?? "🧠"
    }

    // MARK: - Per-bias question (context-aware)

    /// One-line contextual question per bias — asked as the lead question
    /// on the review card, tailored to how that bias usually shows up.
    private func biasQuestion(bias: String, category: String, status: MoneyEvent.PlannedStatus) -> String? {
        switch bias {
        case "Social Proof":          return "Was this influenced by what others do?"
        case "Availability Heuristic": return "Did a vivid recent memory drive this?"
        case "Status Quo Bias":        return "Did you default to this out of habit?"
        case "Anchoring":              return "Did a reference price shape your sense of 'fair'?"
        case "Scarcity Heuristic":     return "Did urgency (\"only a few left\", \"sale ends\") push the buy?"
        case "Ego Depletion":          return "Were you tired, stressed, or drained when you decided?"
        case "Mental Accounting":      return "Did the money's label (bonus, refund, 'fun money', rent) make you treat it differently than ordinary income?"
        case "Moral Licensing":        return "Did a recent good behaviour justify this spend?"
        case "Present Bias":           return "Did you choose now over future you?"
        case "Planning Fallacy":       return "Did this cost more than you expected it to?"
        case "Loss Aversion":          return "Did the fear of losing weigh heavier than the chance of gaining?"
        case "Sunk Cost Fallacy":      return "Did past spending on this pull you in further?"
        case "Overconfidence Bias":    return "Were you more sure about this than evidence warranted?"
        case "Framing Effect":         return "Did how it was presented ('save 30%' vs 'pay 70%') shape the choice?"
        case "Denomination Effect":    return "Did paying by tap or card feel different to cash?"
        case "Ostrich Effect":         return "Did you avoid info that might have stopped this?"
        default:                       return nil
        }
    }

    // MARK: - Completion screen

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Awareness summary")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(DS.textPrimary)

            Text("You reflected on \(entries.count) pattern\(entries.count == 1 ? "" : "s").")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DS.textSecondary)

            VStack(spacing: 10) {
                stat(icon: "checkmark.circle.fill", tint: DS.positive,
                     count: outcome.identifiedCount,
                     label: "Identified correctly",
                     detail: "Pattern score lowered — awareness gained")
                stat(icon: "questionmark.circle.fill", tint: DS.warning,
                     count: outcome.notSureCount,
                     label: "Blind spots",
                     detail: "Pattern stays flagged — watch for next time")
                stat(icon: "arrow.triangle.2.circlepath.circle.fill", tint: DS.textSecondary,
                     count: outcome.differentCount,
                     label: "Marked different reason",
                     detail: "Won't count toward this bias")
            }

            Button { onDone(outcome) } label: {
                Text("See full session summary →")
            }
            .goldButtonStyle()
            .padding(.top, 8)
        }
    }

    private func stat(icon: String, tint: Color, count: Int, label: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Spacer()
                    Text("\(count)")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(tint)
                }
                Text(detail)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(DS.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        .premiumCardShadow()
    }

    // MARK: - Record choice + write to Supabase

    @MainActor
    private func record(entry: Entry, choice: Choice) async {
        isWriting = true
        defer { isWriting = false }

        switch choice {
        case .identified:
            outcome.identifiedCount += 1
            // reflected: true -> adds +1 to times_reflected -> noCount+1 -> -1 to score
            try? await service.updateBiasProgress(biasName: entry.suggestedBias, reflected: true)
        case .notSure:
            outcome.notSureCount += 1
            // no update — tag stays, score keeps +3 from tagged event
        case .different:
            outcome.differentCount += 1
            // Future: re-tag the money_event. For now, locally tracked only.
        }

        withAnimation { index += 1 }
    }
}
