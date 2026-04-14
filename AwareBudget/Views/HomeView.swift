import SwiftUI

struct HomeView: View {
    let streakDays = 12
    let patternsFound = 5
    let totalPatterns = 16

    var awarenessPercent: Double {
        Double(patternsFound) / Double(totalPatterns)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── GREETING ──
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greetingText())
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundColor(Color(hex: "#0A1A0A"))
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#4CAF50"))
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 14)

                // ── STREAK + CIRCLE ──
                HStack(spacing: 12) {
                    // Streak card
                    VStack(spacing: 5) {
                        Text("\(streakDays)")
                            .font(.system(size: 40, weight: .black, design: .serif))
                            .foregroundColor(Color(hex: "#E8B84B"))
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
                            colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32")],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(16)

                    // Awareness circle
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color(hex: "#C8E6C9"), lineWidth: 5)
                            Circle()
                                .trim(from: 0, to: CGFloat(awarenessPercent))
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "#2E7D32"), Color(hex: "#4CAF50")],
                                        startPoint: .leading, endPoint: .trailing),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.2), value: awarenessPercent)
                            Text("\(patternsFound)/\(totalPatterns)")
                                .font(.system(size: 10, weight: .black, design: .serif))
                                .foregroundColor(Color(hex: "#1B5E20"))
                        }
                        .frame(width: 54, height: 54)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(Int(awarenessPercent * 100))%")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundColor(Color(hex: "#1B5E20"))
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
                        .stroke(Color(hex: "#4CAF50").opacity(0.2), lineWidth: 0.5))
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
                        colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32"), Color(hex: "#388E3C")],
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

                // ── 7 PATTERNS DARK SECTION ──
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Image("nudge").resizable().frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("The 7 patterns that cost people most")
                                .font(.system(size: 13, weight: .black, design: .serif))
                                .foregroundColor(.white)
                            Text("Pompian, 2012 · Behavioural Finance & Wealth Management")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.bottom, 12)

                    ForEach(topSevenPatterns, id: \.name) { p in
                        HStack(spacing: 10) {
                            Text(p.emoji).font(.system(size: 18)).frame(width: 26)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.name)
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                                Text(p.cost)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            if p.count > 0 {
                                Text("\(p.count)×")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(Color(hex: "#1B3A00"))
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(LinearGradient(
                                        colors: [Color(hex: "#FFF0A0"), Color(hex: "#C59430")],
                                        startPoint: .leading, endPoint: .trailing))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 6)
                        .overlay(Rectangle().frame(height: 0.5)
                            .foregroundColor(.white.opacity(0.07)), alignment: .bottom)
                    }
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#1B5E20"), Color(hex: "#0D2E10")],
                        startPoint: .top, endPoint: .bottom))
                .cornerRadius(16)
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .background(Color(hex: "#FAFAF8"))
        .navigationBarHidden(true)
    }

    func greetingText() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }
}

struct TopPattern { let emoji, name, cost: String; let count: Int }
let topSevenPatterns = [
    TopPattern(emoji:"😰", name:"Loss Aversion",    cost:"Holding losers too long",       count:3),
    TopPattern(emoji:"⏰", name:"Present Bias",      cost:"Robbing future you",             count:2),
    TopPattern(emoji:"🎯", name:"Overconfidence",    cost:"Overtrading, underperforming",   count:0),
    TopPattern(emoji:"🧮", name:"Mental Accounting", cost:"Saving while in debt",           count:0),
    TopPattern(emoji:"🔴", name:"Status Quo Bias",   cost:"Never reviewing super",          count:1),
    TopPattern(emoji:"⚓", name:"Anchoring",          cost:"Stuck on a purchase price",      count:0),
    TopPattern(emoji:"🙈", name:"Ostrich Effect",    cost:"Avoiding the statements",        count:0),
]
