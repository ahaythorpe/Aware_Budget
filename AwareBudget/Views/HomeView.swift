import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    let totalPatterns = 16

    var awarenessPercent: Double {
        Double(viewModel.biasesSeenCount) / Double(totalPatterns)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── GREETING ──
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greetingText())
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundColor(DS.textPrimary)
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(DS.accent)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 14)

                // ── STREAK + CIRCLE ──
                HStack(spacing: 12) {
                    // Streak card
                    VStack(spacing: 5) {
                        Text("\(viewModel.streak)")
                            .font(.system(size: 40, weight: .black, design: .serif))
                            .foregroundColor(DS.goldText)
                        Text("🔥 day streak")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(.white.opacity(0.65))
                            .textCase(.uppercase)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [DS.deepGreen, DS.primary],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(16)

                    // Awareness circle
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(DS.mintBg, lineWidth: 5)
                            Circle()
                                .trim(from: 0, to: CGFloat(awarenessPercent))
                                .stroke(
                                    LinearGradient(
                                        colors: [DS.primary, DS.accent],
                                        startPoint: .leading, endPoint: .trailing),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.2), value: awarenessPercent)
                            Text("\(viewModel.biasesSeenCount)/\(totalPatterns)")
                                .font(.system(size: 10, weight: .black, design: .serif))
                                .foregroundColor(DS.deepGreen)
                        }
                        .frame(width: 54, height: 54)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(Int(awarenessPercent * 100))%")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundColor(DS.deepGreen)
                            Text("Patterns\nidentified")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(DS.accent.opacity(0.2), lineWidth: 0.5))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── CHECK IN ──
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's check-in")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    Button(action: {}) {
                        Text("Start check-in →")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(Color(hex: "#1B3A00"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(DS.nuggetGold)
                            .cornerRadius(10)
                    }
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [DS.deepGreen, DS.primary, Color(hex: "#388E3C")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(16)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── NUDGE ──
                NudgeSaysCard(
                    message: "You've shown Loss Aversion 3× this week. Most people never notice this pattern in themselves. You're already ahead.",
                    citation: "Kahneman & Tversky, 1979 · Prospect Theory"
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
        .background(Color(hex: "#FAFAF8"))
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
    }

    func greetingText() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }
}
