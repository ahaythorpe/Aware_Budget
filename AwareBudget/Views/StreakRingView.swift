import SwiftUI

struct StreakRingView: View {
    let streak: Int
    let weekDots: [Bool]
    var goalDays: Int = 7

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private let goldGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "FFF0A0"), location: 0.0),
            .init(color: Color(hex: "E8B84B"), location: 0.25),
            .init(color: Color(hex: "C59430"), location: 0.5),
            .init(color: Color(hex: "8B6010"), location: 0.75),
            .init(color: Color(hex: "D4A843"), location: 1.0),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let trackGold = Color(hex: "C59430").opacity(0.18)

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
                .stroke(trackGold, lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(goldGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            VStack(spacing: 2) {
                Text("\(streak)")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(DS.nuggetGold)
                    .contentTransition(.numericText())
                Text("day streak")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
        }
        .frame(width: 140, height: 140)
    }

    private var dotsRow: some View {
        HStack(spacing: 14) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 6) {
                    Text(dayLabels[i])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Circle()
                        .fill(weekDots.indices.contains(i) && weekDots[i] ? DS.goldText : Color.secondary.opacity(0.18))
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
