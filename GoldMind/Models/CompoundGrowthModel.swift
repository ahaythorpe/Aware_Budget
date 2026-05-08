// GoldMind/Models/CompoundGrowthModel.swift

import Foundation

struct CompoundGrowthPoint: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
}

struct CompoundGrowthModel {
    let monthlyContribution: Double
    let annualRate: Double

    /// Generates one data point per year from 0 up to `years`
    func dataPoints(forYears years: Int) -> [CompoundGrowthPoint] {
        guard monthlyContribution > 0 else { return [] }
        let monthlyRate = annualRate / 12.0
        return (0...max(1, years)).map { year in
            let n = Double(year * 12)
            let fv: Double
            if monthlyRate == 0 {
                fv = monthlyContribution * n
            } else {
                fv = monthlyContribution * ((pow(1 + monthlyRate, n) - 1) / monthlyRate)
            }
            return CompoundGrowthPoint(year: year, value: fv)
        }
    }

    func totalContributed(forYears years: Int) -> Double {
        monthlyContribution * Double(years * 12)
    }

    func futureValue(forYears years: Int) -> Double {
        dataPoints(forYears: years).last?.value ?? 0
    }
}
