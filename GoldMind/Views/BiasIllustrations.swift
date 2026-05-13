import SwiftUI
import Charts

/// Programmatic SwiftUI Chart illustrations for the 5 biases that have
/// a clean mathematical shape. Same pattern as `LossAversionChart`:
/// pure SwiftUI Charts, no paid integrations, render inside the bias
/// detail sheet between the Nudge quote and the counter bullets.
///
/// Locked 2026-05-13.

// MARK: - 1. Present Bias — hyperbolic discounting

/// Plot of v(t) = 1 / (1 + k·t) for k = 0.5, t = 0 to 24 months.
/// Shows how the subjective value of a future reward collapses
/// quickly in the first months then flattens.
struct PresentBiasChart: View {
    private struct Point: Identifiable {
        let id = UUID(); let months: Double; let value: Double
    }

    private static let k = 0.5
    private let curve: [Point] = stride(from: 0.0, through: 24.0, by: 1.0).map {
        Point(months: $0, value: 1.0 / (1.0 + PresentBiasChart.k * $0))
    }

    var body: some View {
        IllustrationCard(
            title: "THE PRESENT-BIAS CURVE",
            caption: "A $100 reward now feels like $100. A $100 reward in a year feels like about $14. The drop is steepest in the first weeks — that's why future-you keeps losing the argument.",
            citation: "Laibson, 1997 · hyperbolic discounting"
        ) {
            Chart {
                ForEach(curve) { p in
                    AreaMark(
                        x: .value("Months from now", p.months),
                        y: .value("Felt value", p.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(
                        colors: [DS.goldBase.opacity(0.4), DS.goldBase.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    LineMark(
                        x: .value("Months from now", p.months),
                        y: .value("Felt value", p.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(DS.goldBase)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                PointMark(x: .value("Months", 0), y: .value("Felt value", 1.0))
                    .symbolSize(120).foregroundStyle(DS.accent)
                    .annotation(position: .topTrailing) {
                        Text("Now · $100").font(.caption2.weight(.semibold)).foregroundStyle(DS.accent)
                    }
                PointMark(x: .value("Months", 12), y: .value("Felt value", 1.0 / (1.0 + 0.5 * 12)))
                    .symbolSize(120).foregroundStyle(DS.warning)
                    .annotation(position: .topTrailing) {
                        Text("In a year · feels like $14").font(.caption2.weight(.semibold)).foregroundStyle(DS.warning)
                    }
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                    AxisGridLine().foregroundStyle(DS.textTertiary.opacity(0.15))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v == 0 ? "now" : "\(Int(v))m")
                                .font(.caption2).foregroundStyle(DS.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
        }
    }
}

// MARK: - 2. Anchoring — high anchor vs no anchor

struct AnchoringChart: View {
    private struct Bar: Identifiable {
        let id = UUID(); let label: String; let estimate: Double
    }
    private let bars: [Bar] = [
        Bar(label: "No anchor", estimate: 25),
        Bar(label: "Saw $200 anchor", estimate: 95),
    ]

    var body: some View {
        IllustrationCard(
            title: "THE ANCHOR PULLS YOU UP",
            caption: "Same jacket. Same buyer. Average willingness-to-pay almost quadruples when an arbitrary $200 anchor is shown first. The number you see first sets the gravity.",
            citation: "Tversky & Kahneman, 1974"
        ) {
            Chart(bars) { b in
                BarMark(
                    x: .value("Condition", b.label),
                    y: .value("Estimate", b.estimate)
                )
                .foregroundStyle(b.label == "No anchor" ? DS.accent : DS.warning)
                .cornerRadius(8)
                .annotation(position: .top) {
                    Text("$\(Int(b.estimate))")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(b.label == "No anchor" ? DS.accent : DS.warning)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
        }
    }
}

// MARK: - 3. Planning Fallacy — estimated vs actual

struct PlanningFallacyChart: View {
    private struct Bar: Identifiable {
        let id = UUID(); let label: String; let dollars: Double; let color: Color
    }
    private let bars: [Bar] = [
        Bar(label: "Estimated", dollars: 5000, color: DS.accent),
        Bar(label: "Actually paid", dollars: 8200, color: DS.warning),
    ]

    var body: some View {
        IllustrationCard(
            title: "THE COST OVERRUN",
            caption: "Renovations, side projects, holidays — the typical actual cost is 30–60% above the estimate. The optimism is baked in from the start.",
            citation: "Buehler, Griffin & Ross, 1994"
        ) {
            Chart(bars) { b in
                BarMark(
                    x: .value("Phase", b.label),
                    y: .value("Dollars", b.dollars)
                )
                .foregroundStyle(b.color)
                .cornerRadius(8)
                .annotation(position: .top) {
                    Text("$\(Int(b.dollars).formatted(.number))")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(b.color)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
        }
    }
}

// MARK: - 4. Mental Accounting — same dollar, different jar

struct MentalAccountingChart: View {
    private struct Jar: Identifiable {
        let id = UUID(); let label: String; let spentFreely: Double; let color: Color
    }
    /// "What fraction of this $300 do people spend on something
    /// non-essential within a week" — illustrative.
    private let jars: [Jar] = [
        Jar(label: "Tax refund jar", spentFreely: 78, color: DS.warning),
        Jar(label: "Salary jar",     spentFreely: 22, color: DS.accent),
    ]

    var body: some View {
        IllustrationCard(
            title: "SAME $300 · DIFFERENT JAR",
            caption: "Identical money. Refund money tends to be spent on something non-essential about 3× as often as salary money. The label changed; the dollars didn't.",
            citation: "Thaler, 1985"
        ) {
            Chart(jars) { j in
                BarMark(
                    x: .value("Jar", j.label),
                    y: .value("Percent spent freely", j.spentFreely)
                )
                .foregroundStyle(j.color)
                .cornerRadius(8)
                .annotation(position: .top) {
                    Text("\(Int(j.spentFreely))%")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(j.color)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisGridLine().foregroundStyle(DS.textTertiary.opacity(0.15))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)%").font(.caption2).foregroundStyle(DS.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
    }
}

// MARK: - 5. Overconfidence — confidence vs accuracy

struct OverconfidenceChart: View {
    private struct Point: Identifiable {
        let id = UUID(); let confidence: Double; let accuracy: Double; let kind: String
    }
    /// Calibration curve: if you were perfectly calibrated, when you
    /// say "90% sure" you'd be right 90% of the time (dashed line).
    /// Real data shows you're right less often than you think.
    private let calibration: [Point] = stride(from: 50.0, through: 100.0, by: 10.0).map { c in
        Point(confidence: c, accuracy: c, kind: "Perfect calibration")
    }
    private let actual: [Point] = [
        Point(confidence: 50, accuracy: 53, kind: "Most people"),
        Point(confidence: 60, accuracy: 58, kind: "Most people"),
        Point(confidence: 70, accuracy: 62, kind: "Most people"),
        Point(confidence: 80, accuracy: 65, kind: "Most people"),
        Point(confidence: 90, accuracy: 68, kind: "Most people"),
        Point(confidence: 100, accuracy: 70, kind: "Most people"),
    ]

    var body: some View {
        IllustrationCard(
            title: "WHEN YOU FEEL 90% SURE",
            caption: "Across decades of forecasting research, people who say they're 90% sure are actually right about 70% of the time. Confidence outruns accuracy. The gap widens at higher confidence.",
            citation: "Lichtenstein, Fischhoff & Phillips, 1982"
        ) {
            Chart {
                ForEach(calibration) { p in
                    LineMark(
                        x: .value("Confidence", p.confidence),
                        y: .value("Accuracy", p.accuracy),
                        series: .value("Series", "Perfect")
                    )
                    .foregroundStyle(DS.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                ForEach(actual) { p in
                    LineMark(
                        x: .value("Confidence", p.confidence),
                        y: .value("Accuracy", p.accuracy),
                        series: .value("Series", "Actual")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(DS.warning)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
            }
            .chartXScale(domain: 50...100)
            .chartYScale(domain: 50...100)
            .chartXAxis {
                AxisMarks(values: [50, 75, 100]) { value in
                    AxisGridLine().foregroundStyle(DS.textTertiary.opacity(0.15))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)% sure").font(.caption2).foregroundStyle(DS.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [50, 75, 100]) { value in
                    AxisGridLine().foregroundStyle(DS.textTertiary.opacity(0.15))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)% right").font(.caption2).foregroundStyle(DS.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
    }
}

// MARK: - Shared illustration card

/// Common card chrome used by every BiasIllustrations entry. Title
/// header, chart slot, caption, citation footer — gold-stroked card
/// matching the rest of the bias-detail aesthetic.
struct IllustrationCard<Chart: View>: View {
    let title: String
    let caption: String
    let citation: String
    @ViewBuilder let chart: () -> Chart

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DS.goldBase)
            chart()
            Text(caption)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(citation)
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

// MARK: - Dispatcher

/// Returns the matching illustration view for a bias name, or `nil`
/// if no illustration is shipped for that bias. Used by BiasDetailSheet
/// to render the chart inline when one exists.
@ViewBuilder
func biasIllustration(for biasName: String) -> some View {
    switch biasName {
    case "Loss Aversion":      LossAversionChart()
    case "Present Bias":       PresentBiasChart()
    case "Anchoring":          AnchoringChart()
    case "Planning Fallacy":   PlanningFallacyChart()
    case "Mental Accounting":  MentalAccountingChart()
    case "Overconfidence Bias": OverconfidenceChart()
    default:                   EmptyView()
    }
}
