import SwiftUI

struct StreakRingView: View {
    let streak: Int
    let weekDots: [Bool]
    var goalDays: Int = 7

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private var progress: Double {
        guard goalDays > 0 else { return 0 }
        return min(Double(streak) / Double(goalDays), 1.0)
    }

    var body: some View {
        VStack(spacing: 18) {
            ring
            dotsRow
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(DS.coral.opacity(0.18), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(DS.coral, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            VStack(spacing: 2) {
                Text("\(streak)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.deepPurple)
                    .contentTransition(.numericText())
                Text(streak == 1 ? "day streak" : "day streak")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
        }
        .frame(width: 180, height: 180)
    }

    private var dotsRow: some View {
        HStack(spacing: 14) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 6) {
                    Text(dayLabels[i])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Circle()
                        .fill(weekDots.indices.contains(i) && weekDots[i] ? DS.coral : Color.secondary.opacity(0.18))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
}

#Preview {
    StreakRingView(
        streak: 4,
        weekDots: [true, true, true, true, false, false, false]
    )
    .padding()
    .background(DS.bg)
}
