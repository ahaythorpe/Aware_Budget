import Foundation

enum ChartScaling {
    static func yDomain(for values: [Double], headroom: Double = 1.25) -> ClosedRange<Double> {
        let max = values.max() ?? 10
        return 0...Swift.max(max * headroom, 10)
    }

    static func yStride(for values: [Double]) -> Double {
        let max = values.max() ?? 10
        switch max {
        case ..<20:    return 5
        case ..<100:   return 20
        case ..<500:   return 100
        case ..<2000:  return 500
        default:       return 1000
        }
    }

    static func dollarLabel(_ value: Double) -> String {
        value < 1000 ? "$\(Int(value))" : "$\(String(format: "%.1f", value / 1000))k"
    }

    static func countLabel(_ value: Double) -> String {
        "\(Int(value))"
    }
}
