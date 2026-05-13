import SwiftUI

/// Visual map of the 16 biases laid out in 6 horizontal personality
/// lanes. Tapping a node opens a sheet with the bias one-liner, Nudge's
/// contextual note, and the counteract strategy. The user's primary
/// personality cluster gets a glow halo and a Nudge pointer.
///
/// Layout is deterministic: each lane is a fixed-width column with
/// nodes stacked vertically; edges between related biases (from
/// `BiasRelationships`) are drawn as curved beziers across columns.
struct MindMapView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let userArchetype: String?

    @State private var selectedBias: BiasPattern? = nil
    @State private var highlightedBias: BiasPattern? = nil  // stays after sheet closes for neighbour highlight
    @State private var filter: Filter = .all
    @State private var pulse: Bool = false
    @State private var biasProgress: [BiasProgress] = []
    @State private var eventTagCounts: [String: Int] = [:]

    enum Filter: String, CaseIterable, Identifiable {
        case all        = "All"
        case topThree   = "My top 3"
        case triggered  = "Triggered"
        case untouched  = "Untouched"
        var id: String { rawValue }
    }

    // MARK: - Layout constants

    private let laneWidth: CGFloat = 184
    private let laneSpacing: CGFloat = 8
    private let headerHeight: CGFloat = 112  // taller header + breathing room between title and first node
    private let nodeSpacing: CGFloat = 96
    private let nodeSize: CGFloat = 40
    private let canvasTopPadding: CGFloat = 240  // header + NudgeSays card + filter bar — with clearance so lane labels never sit under the chips
    private let labelHeight: CGFloat = 36
    private let headerToNodeGap: CGFloat = 18  // explicit gap after the header divider

    /// Order of the lanes left-to-right. Matches the canonical archetype order.
    private let lanes: [(archetype: String, category: String)] = [
        ("Drifter",    "Avoidance"),
        ("Reactor",    "Decision Making"),
        ("Bookkeeper", "Money Psychology"),
        ("Now",        "Time Perception"),
        ("Bandwagon",  "Social"),
        ("Autopilot",  "Defaults & Habits"),
    ]

    private var canvasWidth: CGFloat {
        CGFloat(lanes.count) * laneWidth + CGFloat(lanes.count - 1) * laneSpacing + 32
    }
    private var canvasHeight: CGFloat {
        // tallest lane is Decision Making with 6 patterns; nodeSpacing now
        // includes room for the 2-line label beneath each disc.
        headerHeight + nodeSpacing * 6 + 80
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            // Subtle dot grid background to read as a 'map' surface.
            dotGrid
                .opacity(0.35)
                .allowsHitTesting(false)
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    edgesLayer
                    ForEach(Array(lanes.enumerated()), id: \.offset) { idx, lane in
                        lanePillar(idx: idx, lane: lane)
                    }
                }
                .frame(width: canvasWidth, height: canvasHeight)
                .padding(.horizontal, 8)
                .padding(.top, canvasTopPadding)
                .padding(.bottom, 40)
            }
            VStack(spacing: 10) {
                header
                // Purpose card with Nudge cut-out coin baked in
                // (showCoin: true). Pinned so the user always has a
                // read on what the canvas is.
                NudgeSaysCard(
                    message: "Six money personalities, sixteen biases. Tap a node to unpack one. Lines show patterns that travel together.",
                    citation: "BFAS · Pompian, 2012",
                    surface: .whiteShimmer
                )
                .padding(.horizontal, 16)
                filterBar
                Spacer()
            }
        }
        // Pulsing animation removed 2026-05-11 — it competed with labels
        // and made the layout feel busy. Primary cluster is now marked
        // by the YOU chip + a slightly bolder gold border, nothing more.
        .task { await loadProgress() }
        .sheet(item: $selectedBias) { bias in
            BiasDetailSheet(
                pattern: bias,
                triggerCount: triggerCount(for: bias)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // Tap empty canvas (anywhere outside a node button) clears the
        // highlight so the user can reset without picking another bias.
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) {
                highlightedBias = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("BIAS MAP")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(DS.accent)
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(DS.cardBg))
                .overlay(Capsule().stroke(DS.goldBase.opacity(0.3), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Filter.allCases) { f in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { filter = f }
                    } label: {
                        Text(f.rawValue)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(0.4)
                            .foregroundStyle(filter == f ? .white : DS.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(filter == f ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg))
                            )
                            .overlay(
                                Capsule().stroke(
                                    filter == f ? DS.accent.opacity(0.4) : DS.goldBase.opacity(0.25),
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    /// Returns whether this bias should be visually emphasised given the
    /// current filter + highlight state. Used by node + edge dim logic.
    private func isInFocus(_ bias: BiasPattern) -> Bool {
        // Filter gate
        let triggered = triggerCount(for: bias) > 0
        let topNames = allBiasPatterns
            .sorted { triggerCount(for: $0) > triggerCount(for: $1) }
            .prefix(3)
            .map(\.name)
        let passesFilter: Bool = switch filter {
        case .all:       true
        case .topThree:  topNames.contains(bias.name)
        case .triggered: triggered
        case .untouched: !triggered
        }
        guard passesFilter else { return false }

        // Highlight gate: if a bias is highlighted, only it + its related
        // siblings stay in focus.
        if let hl = highlightedBias {
            if bias.name == hl.name { return true }
            return BiasRelationships.related[hl.name]?.contains(bias.name) ?? false
        }
        return true
    }

    /// Aggregate trigger count for a whole lane (personality), used to
    /// drive the lane heat tint.
    private func laneTriggerCount(category: String) -> Int {
        let patterns = biasCategories.first(where: { $0.name == category })?.patterns ?? []
        return patterns.reduce(0) { $0 + triggerCount(for: $1) }
    }

    // MARK: - Lane pillar (one cluster)

    private func lanePillar(idx: Int, lane: (archetype: String, category: String)) -> some View {
        let isPrimary = (userArchetype == lane.archetype)
        let xOrigin = laneOriginX(idx)
        let icon = personalityIcon(for: lane.category)

        let nodes = biasCategories.first(where: { $0.name == lane.category })?.patterns ?? []
        // Lane heat tint: opacity scales 0...0.18 with total triggers in
        // this personality. Caps at 8 triggers for the max tint.
        let heat = min(CGFloat(laneTriggerCount(category: lane.category)) / 8.0, 1.0)
        let heatOpacity: CGFloat = isPrimary ? 0.10 : 0.18 * heat
        return ZStack(alignment: .topLeading) {
            // Lane container kept for hit-test/layout but invisible;
            // grouping is conveyed by node placement + the header chip.
            Color.clear
                .frame(width: laneWidth, height: laneHeight(nodeCount: nodes.count))
                .offset(x: xOrigin - laneWidth / 2, y: 0)

            // Header
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(icon.tint.opacity(0.18))
                    Circle().stroke(icon.tint.opacity(0.5), lineWidth: 1)
                    Image(systemName: icon.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(icon.tint)
                }
                .frame(width: 44, height: 44)
                Text("The \(lane.archetype)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if isPrimary {
                    Text("YOU")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(DS.accent))
                }
            }
            .frame(width: laneWidth)
            .position(x: xOrigin, y: 48)

            // Divider line under the header so titles read as their own
            // band, separated from the node grid.
            Rectangle()
                .fill(DS.goldBase.opacity(0.18))
                .frame(width: laneWidth - 32, height: 0.75)
                .position(x: xOrigin, y: headerHeight - headerToNodeGap)

            // Nodes
            ForEach(Array(nodes.enumerated()), id: \.element.id) { i, p in
                node(p, isPrimaryCluster: isPrimary)
                    .opacity(isInFocus(p) ? 1.0 : 0.25)
                    .animation(.easeOut(duration: 0.2), value: filter)
                    .animation(.easeOut(duration: 0.2), value: highlightedBias?.name)
                    .position(nodePosition(laneIdx: idx, nodeIdx: i))
            }
        }
    }

    private func node(_ pattern: BiasPattern, isPrimaryCluster: Bool) -> some View {
        let trigger = triggerCount(for: pattern)
        // Scale node 1.0x to 1.35x based on how often the user has hit it.
        let scale: CGFloat = min(1.35, 1.0 + CGFloat(trigger) * 0.07)
        let isHighlighted = highlightedBias?.name == pattern.name
        return Button {
            // Highlight neighbours immediately; sheet opens after.
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                highlightedBias = pattern
            }
            selectedBias = pattern
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(Color(hex: pattern.iconBg))
                    Circle()
                        .stroke(
                            isHighlighted ? DS.accent : DS.goldBase.opacity(isPrimaryCluster ? 0.85 : 0.4),
                            lineWidth: isHighlighted ? 2.5 : (isPrimaryCluster ? 1.5 : 1)
                        )
                    Image(systemName: pattern.sfSymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: pattern.iconColor))
                    if trigger > 0 {
                        Text("\(trigger)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(DS.accent))
                            .offset(x: nodeSize / 2.4, y: -nodeSize / 2.4)
                    }
                }
                .frame(width: nodeSize, height: nodeSize)
                .scaleEffect(isHighlighted ? scale * 1.12 : scale)
                .shadow(
                    color: isHighlighted ? DS.accent.opacity(0.35) : .black.opacity(0.10),
                    radius: isHighlighted ? 8 : 3,
                    y: 1
                )

                Text(pattern.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(width: laneWidth - 24, height: labelHeight, alignment: .top)
            }
            .opacity(isPrimaryCluster ? 1.0 : 0.85)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pattern.displayName)
    }

    // MARK: - Edges (related-bias bezier lines)

    private var edgesLayer: some View {
        Canvas { ctx, size in
            for (from, tos) in BiasRelationships.related {
                guard let fromPos = position(forBias: from) else { continue }
                for to in tos {
                    guard let toPos = position(forBias: to) else { continue }
                    // Draw each undirected pair once.
                    if from < to {
                        var path = Path()
                        let mid = CGPoint(x: (fromPos.x + toPos.x) / 2,
                                          y: (fromPos.y + toPos.y) / 2 + 16)
                        path.move(to: fromPos)
                        path.addQuadCurve(to: toPos, control: mid)
                        // Brighten the edge if it connects the currently
                        // highlighted bias to one of its siblings.
                        let isHL = highlightedBias.map { hl in
                            hl.name == from || hl.name == to
                        } ?? false
                        ctx.stroke(
                            path,
                            with: .color(DS.goldBase.opacity(isHL ? 0.8 : 0.15)),
                            style: StrokeStyle(lineWidth: isHL ? 2.5 : 1.0, lineCap: .round)
                        )
                    }
                }
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Bias sheet (description + nudge + counteract)

    // MARK: - Background dot grid

    private var dotGrid: some View {
        Canvas { ctx, size in
            let step: CGFloat = 22
            for x in stride(from: 0, through: size.width, by: step) {
                for y in stride(from: 0, through: size.height, by: step) {
                    let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                    ctx.fill(Path(ellipseIn: rect), with: .color(DS.goldBase.opacity(0.18)))
                }
            }
        }
    }

    // MARK: - Layout helpers

    private func laneOriginX(_ idx: Int) -> CGFloat {
        // x of lane CENTER
        16 + laneWidth / 2 + CGFloat(idx) * (laneWidth + laneSpacing)
    }

    private func laneHeight(nodeCount: Int) -> CGFloat {
        headerHeight + nodeSpacing * CGFloat(max(2, nodeCount)) + 30
    }

    private func nodePosition(laneIdx: Int, nodeIdx: Int) -> CGPoint {
        CGPoint(
            x: laneOriginX(laneIdx),
            y: headerHeight + headerToNodeGap + 32 + CGFloat(nodeIdx) * nodeSpacing
        )
    }

    private func position(forBias biasName: String) -> CGPoint? {
        for (laneIdx, lane) in lanes.enumerated() {
            let nodes = biasCategories.first(where: { $0.name == lane.category })?.patterns ?? []
            if let nodeIdx = nodes.firstIndex(where: { $0.name == biasName }) {
                return nodePosition(laneIdx: laneIdx, nodeIdx: nodeIdx)
            }
        }
        return nil
    }

    private func personalityIcon(for category: String) -> (symbol: String, tint: Color) {
        switch category {
        case "Avoidance":         return ("eye.slash.circle.fill", Color(hex: "E65100"))
        case "Decision Making":   return ("bolt.fill",              Color(hex: "C62828"))
        case "Money Psychology":  return ("tray.2.fill",             Color(hex: "4527A0"))
        case "Time Perception":   return ("hourglass",               Color(hex: "880E4F"))
        case "Social":            return ("person.2.wave.2.fill",    Color(hex: "7B1FA2"))
        case "Defaults & Habits": return ("repeat.circle.fill",      Color(hex: "E65100"))
        default:                  return ("circle.fill",              DS.goldBase)
        }
    }

    private func triggerCount(for p: BiasPattern) -> Int {
        let progressed = biasProgress.first(where: { $0.biasName == p.name })?.timesEncountered ?? 0
        let tagged = eventTagCounts[p.name] ?? 0
        return progressed + tagged
    }

    private func loadProgress() async {
        let progress = (try? await SupabaseService.shared.fetchBiasProgress()) ?? []
        let events = (try? await SupabaseService.shared.fetchMoneyEvents(forMonth: Date())) ?? []
        let counts: [String: Int] = events
            .compactMap(\.behaviourTag)
            .reduce(into: [:]) { c, tag in c[tag, default: 0] += 1 }
        await MainActor.run {
            self.biasProgress = progress
            self.eventTagCounts = counts
        }
    }
}

#Preview {
    MindMapView(userArchetype: "Reactor")
}

// ─────────────────────────────────────────────────────────────────
// BIAS DETAIL SHEET — scanable layout: stat chip, Nudge quote,
// bulleted counters, expand-to-see real example, related chips
// (tap navigates the sheet to that bias).
// ─────────────────────────────────────────────────────────────────
private struct BiasDetailSheet: View {
    let pattern: BiasPattern
    let triggerCount: Int

    @State private var showExample = false

    private var counterBullets: [String] {
        let lesson = BiasLessonsMock.seed.first(where: { $0.biasName == pattern.name })
        return (lesson?.howToCounter ?? "")
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)
                     .trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
            .filter { !$0.isEmpty }
    }

    private var example: String? {
        BiasLessonsMock.seed.first(where: { $0.biasName == pattern.name })?.realWorldExample
    }

    private var related: [BiasPattern] {
        BiasRelationships.relatedBiases(for: pattern.name)
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero
                    triggerChip
                    Text(pattern.oneLiner)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DS.textPrimary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    nudgeQuote
                    // v1.0 proof-of-concept: render Kahneman's value
                    // function as a visual illustration for the bias
                    // it directly describes. v1.1 extends to other
                    // biases with clean math shapes (#36).
                    if pattern.name == "Loss Aversion" {
                        LossAversionChart()
                    }
                    if !counterBullets.isEmpty { counterCard }
                    if let example { exampleDisclosure(example) }
                    if !related.isEmpty { relatedRow }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: pattern.iconBg))
                Image(systemName: pattern.sfSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(hex: pattern.iconColor))
            }
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.displayName)
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundStyle(DS.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(pattern.keyRef)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(DS.goldBase)
            }
            Spacer()
        }
    }

    private var triggerChip: some View {
        HStack(spacing: 6) {
            Image(systemName: triggerCount > 0 ? "chart.bar.fill" : "circle.dashed")
                .font(.system(size: 10, weight: .bold))
            Text(triggerCount > 0 ? "Seen \(triggerCount)× in your logs" : "Not seen in your logs yet")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(0.3)
        }
        .foregroundStyle(triggerCount > 0 ? .white : DS.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(
                triggerCount > 0 ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg)
            )
        )
        .overlay(
            Capsule().stroke(
                triggerCount > 0 ? DS.accent.opacity(0.3) : DS.goldBase.opacity(0.25),
                lineWidth: 1
            )
        )
    }

    private var nudgeQuote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("nudge")
                .resizable().scaledToFit()
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text("NUDGE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(DS.accent)
                Text(pattern.nudgeSays)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
        )
    }

    private var counterCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW TO COUNTERACT")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.accent)
            ForEach(Array(counterBullets.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.accent)
                        .padding(.top, 2)
                    Text(line)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.textPrimary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.paleGreen.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.accent.opacity(0.35), lineWidth: 1))
    }

    private func exampleDisclosure(_ example: String) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { showExample.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: showExample ? 10 : 0) {
                HStack {
                    Text("REAL EXAMPLE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(DS.goldBase)
                    Spacer()
                    Image(systemName: showExample ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.goldBase)
                }
                if showExample {
                    Text(example)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.textPrimary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.goldBase.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var relatedRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RELATED PATTERNS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.goldBase)
            // Static informational chips — display-only. The Research
            // tab's concept graph is the place to actually navigate
            // between biases; making these tappable inside a presented
            // sheet caused flicker/dismiss issues on iOS (sheet
            // re-presents when bound Identifiable changes).
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(related) { r in
                        HStack(spacing: 6) {
                            Image(systemName: r.sfSymbol)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DS.goldBase)
                            Text(r.displayName)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(DS.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(DS.cardBg))
                        .overlay(Capsule().stroke(DS.goldBase.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }
}
