import SwiftUI
import Charts

/// Loss Aversion S-curve illustration. Renders Kahneman & Tversky's
/// (1979 Prospect Theory; 1992 cumulative) value function v(x):
///   v(x) = x^α        for x ≥ 0
///   v(x) = -λ(-x)^β   for x < 0
/// with α = β = 0.88 and λ = 2.25 (the loss-aversion coefficient).
///
/// Visually: losses (left half) sit steeper and lower than the symmetric
/// gain (right half). A $50 loss is plotted at roughly twice the
/// magnitude of a $50 gain — the "losses feel 2× as bad" finding.
///
/// Bella's v1.0 proof-of-concept (2026-05-13). If users find it
/// useful, extend the same pattern to Present Bias (hyperbolic
/// discount), Anchoring, Planning Fallacy. Plan #36 in v1.1.
struct LossAversionChart: View {

    private struct Point: Identifiable {
        let id = UUID()
        let dollars: Double      // x-axis: $ gain or loss
        let value: Double        // y-axis: subjective value
    }

    /// Prospect Theory value function. λ = 2.25 means a $50 loss
    /// registers with about twice the magnitude of a $50 gain.
    private static let alpha = 0.88
    private static let lambda = 2.25

    private static func subjectiveValue(of dollars: Double) -> Double {
        if dollars >= 0 {
            return pow(dollars, alpha)
        } else {
            return -lambda * pow(-dollars, alpha)
        }
    }

    /// Plot from -$100 to +$100 in $5 steps — smooth enough to read
    /// the curve, light enough to render fast.
    private let curve: [Point] = stride(from: -100.0, through: 100.0, by: 5.0).map {
        Point(dollars: $0, value: LossAversionChart.subjectiveValue(of: $0))
    }

    private let gainAnchor = 50.0
    private let lossAnchor = -50.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE LOSS-AVERSION CURVE")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.goldBase)

            Chart {
                // Curve
                ForEach(curve) { p in
                    LineMark(
                        x: .value("Dollars", p.dollars),
                        y: .value("Felt value", p.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(DS.goldBase)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }

                // Reference dots at ±$50 to show the asymmetry
                PointMark(
                    x: .value("Dollars", gainAnchor),
                    y: .value("Felt value", LossAversionChart.subjectiveValue(of: gainAnchor))
                )
                .symbolSize(120)
                .foregroundStyle(DS.accent)
                .annotation(position: .topTrailing, alignment: .leading) {
                    Text("Gain $50")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DS.accent)
                }

                PointMark(
                    x: .value("Dollars", lossAnchor),
                    y: .value("Felt value", LossAversionChart.subjectiveValue(of: lossAnchor))
                )
                .symbolSize(120)
                .foregroundStyle(DS.warning)
                .annotation(position: .bottomLeading, alignment: .trailing) {
                    Text("Lose $50")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DS.warning)
                }

                // Zero crosshairs
                RuleMark(x: .value("Zero", 0))
                    .foregroundStyle(DS.textTertiary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(DS.textTertiary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
            }
            .chartXAxis {
                AxisMarks(values: [-100, -50, 0, 50, 100]) { value in
                    AxisGridLine().foregroundStyle(DS.textTertiary.opacity(0.15))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            let prefix = v > 0 ? "+$" : (v < 0 ? "-$" : "$")
                            Text("\(prefix)\(Int(abs(v)))")
                                .font(.caption2)
                                .foregroundStyle(DS.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)

            Text("The lose-$50 dot sits about twice as far below zero as the gain-$50 dot sits above. That's loss aversion in one picture.")
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Kahneman & Tversky · Prospect Theory, 1979")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(DS.goldBase)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
        )
    }
}
