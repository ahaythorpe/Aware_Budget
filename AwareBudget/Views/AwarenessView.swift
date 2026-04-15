import SwiftUI

struct AwarenessView: View {
    let patterns = allBiasPatterns
    @State private var biasProgress: [BiasProgress] = []

    func triggerCount(for pattern: BiasPattern) -> Int {
        biasProgress.first(where: { $0.biasName == pattern.name })?.timesEncountered ?? 0
    }

    var triggered: [BiasPattern] { patterns.filter { triggerCount(for: $0) > 0 } }
    var awarenessScore: Int { triggered.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── HERO ──
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your money mind")
                                .font(.system(.largeTitle, weight: .bold))
                                .foregroundStyle(DS.textPrimary)
                            Text("Tap any triggered pattern to hear from Nudge.")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(DS.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.top, 12)

                    // Awareness score bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("🏅 Awareness score")
                                .font(.system(size: 11, weight: .bold))
                            Spacer()
                            Text("\(awarenessScore) / \(patterns.count)")
                                .font(.system(size: 16, weight: .black, design: .serif))
                                .foregroundColor(Color(hex: "#1B5E20"))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(hex: "#C8E6C9")).frame(height: 7)
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#2E7D32"), Color(hex: "#4CAF50")],
                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(
                                        width: geo.size.width * CGFloat(awarenessScore) / CGFloat(patterns.count),
                                        height: 7)
                                    .animation(.easeInOut(duration: 1.0), value: awarenessScore)
                            }
                        }
                        .frame(height: 7)
                        ResearchFootnote(text: "Based on the BFAS framework · used in professional financial planning assessments")
                            .padding(.top, 2)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius:12)
                        .stroke(Color(hex: "#4CAF50").opacity(0.2), lineWidth: 0.5))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // ── NUDGE ──
                NudgeSaysCard(
                    message: "Each pattern you identify sharpens your BFAS profile. Professional financial planners use the same framework to assess client behaviour.",
                    citation: "BFAS · Behavioural Finance Assessment Score"
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

                // ── CATEGORIES ──
                ForEach(biasCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(category.emoji)
                                .font(.system(size: 14))
                            Text(category.name.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(DS.accent)
                        }
                        .padding(.horizontal, 16)

                        ForEach(category.patterns) { pattern in
                            BiasAwarenessCard(pattern: pattern, triggerCount: triggerCount(for: pattern))
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 14)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color(hex: "#FAFAF8"))
        .navigationBarHidden(true)
        .task {
            if let progress = try? await SupabaseService.shared.fetchBiasProgress() {
                biasProgress = progress
            }
        }
    }
}

// ─────────────────────────────────
// BIAS CARD — tap to expand Nudge
// ─────────────────────────────────
struct BiasAwarenessCard: View {
    let pattern: BiasPattern
    let triggerCount: Int
    @State private var expanded = false
    var isTriggered: Bool { triggerCount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── MAIN ROW ──
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(isTriggered
                              ? Color(hex: pattern.iconBg)
                              : Color.gray.opacity(0.07))
                        .frame(width: 40, height: 40)
                    Image(systemName: pattern.sfSymbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isTriggered
                                         ? Color(hex: pattern.iconColor)
                                         : Color.gray.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.name)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(isTriggered ? Color(hex: "#0A1A0A") : .gray)
                    Text(pattern.oneLiner)
                        .font(.system(size: 9.5))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if isTriggered {
                        Text("\(triggerCount)×")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Color(hex: "#1B5E20"))
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color(hex: "#E8F5E9"))
                            .clipShape(Capsule())
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#4CAF50"))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color.gray.opacity(0.22))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isTriggered else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    expanded.toggle()
                }
            }

            // ── EXPANDED: NUDGE SAYS + KEY REF ──
            if expanded && isTriggered {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().padding(.horizontal, 12)

                    HStack(alignment: .top, spacing: 8) {
                        Image("nudge")
                            .resizable().scaledToFit()
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NUDGE SAYS")
                                .font(.system(size: 8, weight: .black))
                                .tracking(1.0)
                                .foregroundColor(Color(hex: "#2E7D32"))
                            Text(pattern.nudgeSays)
                                .font(.system(size: 10.5))
                                .foregroundColor(Color(hex: "#1B5E20"))
                                .italic()
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.horizontal, 12)

                    // Key reference — one per bias
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#C59430"))
                        Text(pattern.keyRef)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#8B6010"))
                        Spacer()
                        Text("Key source")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
                .background(Color(hex: "#E8F5E9").opacity(0.6))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(isTriggered ? Color.white : Color.white.opacity(0.55))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(
                    isTriggered
                    ? Color(hex: "#4CAF50").opacity(0.3)
                    : Color.gray.opacity(0.1),
                    lineWidth: isTriggered ? 1 : 0.5)
        )
        .shadow(color: isTriggered
                ? Color(hex: "#4CAF50").opacity(0.06)
                : .clear,
                radius: 4, x: 0, y: 2)
    }
}
