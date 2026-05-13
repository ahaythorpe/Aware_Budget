import SwiftUI

/// Interactive concept graph for the Research tab: papers ↔ biases.
///
/// Two layers: papers along the top, biases along the bottom grouped
/// by BFAS category. Tapping a paper highlights the biases it
/// underpins; tapping a bias highlights its primary paper. Anything
/// unrelated dims to 0.25 — same pattern as the Mind Map filter.
///
/// Spec lived in `docs/PLAN_V1_1.md` as #34. Bella greenlit shipping
/// in v1.0 on 2026-05-13.
struct ResearchMapView: View {
    @State private var selectedPaper: String? = nil
    @State private var selectedBias: String?  = nil

    // MARK: Highlight state

    private var hasSelection: Bool {
        selectedPaper != nil || selectedBias != nil
    }

    private func paperOpacity(_ key: String) -> Double {
        guard hasSelection else { return 1.0 }
        if selectedPaper == key { return 1.0 }
        if let bias = selectedBias,
           ResearchGraph.biasToPaper[bias] == key { return 1.0 }
        return 0.25
    }

    private func biasOpacity(_ name: String) -> Double {
        guard hasSelection else { return 1.0 }
        if selectedBias == name { return 1.0 }
        if let paper = selectedPaper,
           ResearchGraph.biasToPaper[name] == paper { return 1.0 }
        return 0.25
    }

    private func clear() {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedPaper = nil
            selectedBias = nil
        }
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header — map-themed with compass icon
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.goldBase)
                Text("THE BIAS-PAPER MAP")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(DS.goldBase)
                Spacer()
                if hasSelection {
                    Button("Clear") { clear() }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.accent)
                }
            }

            // Nudge speech-bubble intro
            HStack(alignment: .top, spacing: 10) {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Text("Every bias traces back to a paper. Tap a paper to see what it underpins, or tap a bias to find its source. The map is yours to wander.")
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
            )

            // Papers — flow grid
            FlexibleStack(spacing: 6) {
                ForEach(ResearchGraph.papers) { paper in
                    paperChip(paper)
                }
            }

            // Visual separator
            HStack(spacing: 8) {
                Rectangle()
                    .fill(DS.goldBase.opacity(0.2))
                    .frame(height: 0.5)
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.goldBase.opacity(0.5))
                Rectangle()
                    .fill(DS.goldBase.opacity(0.2))
                    .frame(height: 0.5)
            }
            .padding(.vertical, 4)

            // Biases — 6 BFAS category sections, biases as chips
            VStack(alignment: .leading, spacing: 10) {
                ForEach(biasCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.name.uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(DS.goldBase.opacity(0.7))
                        FlexibleStack(spacing: 6) {
                            ForEach(category.patterns) { p in
                                biasChip(p.name, sfSymbol: p.sfSymbol)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.18), lineWidth: 0.5)
        )
        .premiumCardShadow()
    }

    // MARK: Chips

    private func paperChip(_ p: PaperCitation) -> some View {
        let isOn = selectedPaper == p.key
        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                if selectedPaper == p.key { selectedPaper = nil }
                else {
                    selectedPaper = p.key
                    selectedBias = nil
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isOn ? .white : DS.goldBase)
                Text(p.label)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isOn ? .white : DS.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isOn ? AnyShapeStyle(DS.heroGradient) : AnyShapeStyle(DS.cardBg))
            )
            .overlay(
                Capsule().stroke(DS.goldBase.opacity(isOn ? 0.4 : 0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .opacity(paperOpacity(p.key))
        .animation(.easeOut(duration: 0.2), value: hasSelection)
    }

    private func biasChip(_ name: String, sfSymbol: String) -> some View {
        let isOn = selectedBias == name
        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                if selectedBias == name { selectedBias = nil }
                else {
                    selectedBias = name
                    selectedPaper = nil
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: sfSymbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isOn ? .white : DS.goldBase)
                Text(name.replacingOccurrences(of: "Heuristic", with: "Shortcut"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isOn ? .white : DS.textPrimary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(isOn ? AnyShapeStyle(DS.accent) : AnyShapeStyle(DS.paleGreen.opacity(0.6)))
            )
            .overlay(
                Capsule().stroke(DS.accent.opacity(isOn ? 0.5 : 0.18), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .opacity(biasOpacity(name))
        .animation(.easeOut(duration: 0.2), value: hasSelection)
    }
}

// MARK: - FlexibleStack

/// Wrapping HStack — lays children left to right, wraps to a new row
/// when width exceeds the parent. Used by ResearchMapView so the
/// paper + bias chip rows reflow naturally on any screen width.
struct FlexibleStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        FlowLayout(spacing: spacing) { content() }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        return layoutSize(maxWidth: maxWidth, subviews: subviews)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func layoutSize(maxWidth: CGFloat, subviews: Subviews) -> CGSize {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            totalWidth = max(totalWidth, x)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }
}
