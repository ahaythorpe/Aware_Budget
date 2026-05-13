// GoldMind/Views/Insights/CompoundGrowthCard.swift

import SwiftUI
import Charts

// MARK: - CompoundGrowthCard

struct CompoundGrowthCard: View {
    let monthlySpend: Double

    @State private var selectedYears: Int = 20
    @State private var zoomStart: Double = 0
    @State private var zoomEnd: Double = 20

    private let yearOptions = [5, 10, 20, 30]
    private let annualRate = 0.08
    private let goldColor = Color(hex: "#E8B84B")
    private let darkGreen = Color(hex: "#1B5E20")
    private let cardBg = Color(hex: "#FAFAF8")

    // MARK: Computed

    private var model: CompoundGrowthModel {
        CompoundGrowthModel(monthlyContribution: monthlySpend, annualRate: annualRate)
    }

    private var allPoints: [CompoundGrowthPoint] {
        model.dataPoints(forYears: selectedYears)
    }

    private var visiblePoints: [CompoundGrowthPoint] {
        let startY = Int(zoomStart.rounded())
        let endY   = Int(zoomEnd.rounded())
        return allPoints.filter { $0.year >= startY && $0.year <= endY }
    }

    private var futureValue: Double  { model.futureValue(forYears: Int(zoomEnd.rounded())) }
    private var totalIn: Double      { model.totalContributed(forYears: Int(zoomEnd.rounded())) }
    private var growth: Double       { max(0, futureValue - totalIn) }
    private var growthPct: Int       { totalIn > 0 ? Int((growth / totalIn) * 100) : 0 }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(goldColor)
                            .font(.system(size: 16, weight: .semibold))
                        Text("Future You's Bank Account")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(String(format: "If you redirected the $%.0f/mo you're spending now into an investment at 8%% avg return", monthlySpend))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            // Year preset buttons
            HStack(spacing: 8) {
                ForEach(yearOptions, id: \.self) { yr in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedYears = yr
                            zoomStart = 0
                            zoomEnd = Double(yr)
                        }
                    }) {
                        Text("\(yr)yr")
                            .font(.system(size: 13, weight: selectedYears == yr ? .semibold : .regular))
                            .foregroundColor(selectedYears == yr ? .white : goldColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedYears == yr
                                    ? goldColor
                                    : goldColor.opacity(0.12)
                            )
                            .cornerRadius(20)
                    }
                }
                Spacer()
                Text("Drag to zoom")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Chart
            Group {
                if visiblePoints.count > 1 {
                    Chart(visiblePoints) { point in
                        AreaMark(
                            x: .value("Year", point.year),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [goldColor.opacity(0.30), goldColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Year", point.year),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(goldColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                .foregroundStyle(Color.secondary.opacity(0.25))
                            AxisValueLabel {
                                if let yr = value.as(Int.self) {
                                    Text("yr\(yr)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                .foregroundStyle(Color.secondary.opacity(0.25))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(formatShort(v))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.35), value: zoomStart)
                    .animation(.easeInOut(duration: 0.35), value: zoomEnd)
                    .animation(.easeInOut(duration: 0.35), value: selectedYears)
                } else {
                    // Fallback when no events tracked yet
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(goldColor.opacity(0.07))
                        Text("Start tracking spending to see your projection")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .frame(height: 160)

            // Range slider
            RangeSliderView(
                minValue: 0,
                maxValue: Double(selectedYears),
                lowerValue: $zoomStart,
                upperValue: $zoomEnd
            )
            .frame(height: 36)

            // Zoom label + reset
            HStack {
                Text("yr \(Int(zoomStart.rounded())) → yr \(Int(zoomEnd.rounded()))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Reset zoom") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        zoomStart = 0
                        zoomEnd = Double(selectedYears)
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(goldColor)
            }

            Divider().opacity(0.35)

            // Summary stats
            HStack(alignment: .top, spacing: 0) {
                statColumn(
                    label: "In yr \(Int(zoomEnd.rounded()))",
                    value: formatShort(futureValue),
                    highlight: true
                )
                Spacer()
                statColumn(label: "You'd put in", value: formatShort(totalIn), highlight: false)
                Spacer()
                statColumn(label: "Growth", value: "+\(growthPct)%", highlight: false)
            }

            Text("Based on your last 30 days of tracked spending")
                .font(.system(size: 11))
                .foregroundColor(Color.secondary.opacity(0.65))
        }
        .padding(20)
        .background(cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .onAppear {
            zoomEnd = Double(selectedYears)
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func statColumn(label: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(highlight ? darkGreen : .primary)
        }
    }

    private func formatShort(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "$%.1fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "$%.0fK", v / 1_000) }
        return String(format: "$%.0f", v)
    }
}

// MARK: - RangeSliderView

/// Dual-handle horizontal slider. Both handles are gold circles.
/// The track between handles is filled gold.
private struct RangeSliderView: View {
    let minValue: Double
    let maxValue: Double
    @Binding var lowerValue: Double
    @Binding var upperValue: Double

    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat   = 24
    private let goldColor = Color(hex: "#E8B84B")

    var body: some View {
        GeometryReader { geo in
            let usableWidth = geo.size.width - thumbSize
            let lx = thumbSize / 2 + CGFloat((lowerValue - minValue) / (maxValue - minValue)) * usableWidth
            let ux = thumbSize / 2 + CGFloat((upperValue - minValue) / (maxValue - minValue)) * usableWidth

            ZStack(alignment: .leading) {

                // Background track
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: trackHeight)
                    .padding(.horizontal, thumbSize / 2)

                // Active gold section
                Rectangle()
                    .fill(goldColor.opacity(0.45))
                    .frame(width: max(0, ux - lx), height: trackHeight)
                    .offset(x: lx)

                // Lower handle
                Circle()
                    .fill(goldColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                    .offset(x: lx - thumbSize / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let raw = Double((val.location.x - thumbSize / 2) / usableWidth)
                                    * (maxValue - minValue) + minValue
                                // Snap to 0.5yr, clamp so lower never passes upper
                                let snapped = (raw * 2).rounded() / 2
                                lowerValue = min(max(snapped, minValue), upperValue - 1)
                            }
                    )

                // Upper handle
                Circle()
                    .fill(goldColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                    .offset(x: ux - thumbSize / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let raw = Double((val.location.x - thumbSize / 2) / usableWidth)
                                    * (maxValue - minValue) + minValue
                                let snapped = (raw * 2).rounded() / 2
                                upperValue = min(max(snapped, lowerValue + 1), maxValue)
                            }
                    )
            }
            .frame(height: thumbSize)
        }
    }
}
