import SwiftUI

/// Canonical research citation renderer. All BFAS / Pompian / Kahneman /
/// Thaler / ABS / etc. references go through this component.
///
/// See DESIGN_HANDBOOK §3.6 and §5.1.
struct ResearchFootnote: View {
    enum Style { case inline, pill }

    let text: String
    var icon: String = "book.closed.fill"
    var style: Style = .inline

    var body: some View {
        switch style {
        case .inline: inlineView
        case .pill:   pillView
        }
    }

    private var inlineView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(DS.goldBase)
            Text(text)
                .font(.system(.footnote, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pillView: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(DS.goldBase)
            Text(text)
                .font(.system(.footnote, weight: .semibold))
                .foregroundStyle(Color(hex: "8B6010"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(hex: "FFF8E1"), in: Capsule())
        .overlay(Capsule().stroke(DS.goldBase.opacity(0.3), lineWidth: 0.5))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ResearchFootnote(text: "Based on the BFAS framework · Pompian, 2012")
        ResearchFootnote(
            text: "Ranges based on ABS Household Expenditure Survey 2022–23",
            icon: "chart.bar.doc.horizontal"
        )
        ResearchFootnote(text: "Powered by the BFAS framework · Pompian, 2012", style: .pill)
        ResearchFootnote(text: "Based on 50+ years of behavioural research", style: .pill)
    }
    .padding(20)
    .background(DS.bg)
}
