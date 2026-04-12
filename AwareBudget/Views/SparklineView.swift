import SwiftUI

/// 7-bar sparkline showing weekly trend data.
/// Green bars = improving (below average), orange/red = worsening (above average).
struct SparklineView: View {
    let values: [Double]
    let barWidth: CGFloat
    let height: CGFloat
    let improving: Bool

    init(values: [Double], barWidth: CGFloat = 6, height: CGFloat = 36, improving: Bool = true) {
        self.values = values
        self.barWidth = barWidth
        self.height = height
        self.improving = improving
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            let maxVal = max(values.max() ?? 1, 1)
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let fraction = CGFloat(value / maxVal)
                let barHeight = max(fraction * height, 2)
                let isLatest = index == values.count - 1
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(fraction: fraction, isLatest: isLatest))
                    .frame(width: barWidth, height: barHeight)
            }
        }
        .frame(height: height, alignment: .bottom)
    }

    private func barColor(fraction: CGFloat, isLatest: Bool) -> Color {
        if isLatest {
            return improving ? DS.positive : DS.warning
        }
        return fraction > 0.6 ? DS.warning.opacity(0.6) : DS.positive.opacity(0.5)
    }
}

#Preview {
    HStack(spacing: 20) {
        SparklineView(values: [3, 5, 4, 2, 1, 3, 2], improving: true)
        SparklineView(values: [1, 2, 3, 4, 5, 6, 7], improving: false)
    }
    .padding()
}
