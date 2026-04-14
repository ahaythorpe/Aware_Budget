import SwiftUI

struct WhyView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── HERO ──
                VStack(spacing: 10) {
                    Image("nudge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)

                    Text("Most budgets track\nthe wrong thing.")
                        .font(.system(size: 24, weight: .black, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Here's what's different.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#0A1A0A"), Color(hex: "#1B5E20")],
                        startPoint: .top, endPoint: .bottom)
                )

                // ── COMPARISON TABLE ──
                VStack(spacing: 0) {

                    // Header row
                    HStack {
                        Text("")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Traditional")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(width: 90, alignment: .center)
                        Text("AwareBudget")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(hex: "#4CAF50"))
                            .frame(width: 110, alignment: .center)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#F4F6F4"))

                    CompareRow(label: "Focuses on",  bad: "Categories",   good: "Behaviour")
                    CompareRow(label: "Feels like",  bad: "Shame",        good: "Awareness")
                    CompareRow(label: "Based on",    bad: "Rules",        good: "Research")
                    CompareRow(label: "When wrong",  bad: "You hide it",  good: "You adjust")
                    CompareRow(label: "Result",      bad: "You quit",     good: "You keep going")
                }
                .background(Color.white)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#4CAF50").opacity(0.15), lineWidth: 0.5))
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // ── RESEARCH NOTE ──
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#C59430"))
                    Text("Behavioural economics shows shame reduces engagement")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(hex: "#8B6010"))
                    Spacer()
                    Text("Thaler & Sunstein, 2008")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "#C59430"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#FFF8E1"))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // ── YOU'RE NOT BROKEN ──
                VStack(spacing: 10) {
                    Image("nudge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)

                    Text("You're not broken.\nThe method is.")
                        .font(.system(size: 20, weight: .black, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("70% of people abandon budgeting apps within 30 days.\nNot from laziness — from apps that create shame, not awareness.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    // CTA
                    Text("That's why AwareBudget exists →")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color(hex: "#1B3A00"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FFF0A0"), Color(hex: "#E8B84B"), Color(hex: "#C59430")],
                                startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                }
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#1B5E20"), Color(hex: "#0D2E10")],
                        startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // ── BFAS CARD ──
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#E8F5E9"))
                                .frame(width: 36, height: 36)
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#1B5E20"))
                        }
                        Text("Built on the BFAS framework")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(hex: "#0A1A0A"))
                    }

                    Text("The Behavioural Finance Assessment Score is used by professional financial planners to assess client behaviour before providing advice. AwareBudget brings this same framework to everyday spending — the same 16 patterns, adapted for daily life.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#3A4E3A"))
                        .lineSpacing(3)

                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#C59430"))
                        Text("Pompian, 2012 · Behavioural Finance and Wealth Management")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#8B6010"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FFF8E1"))
                    .cornerRadius(8)

                    // Nudge says
                    NudgeSaysCard(
                        message: "When you share your BFAS profile with a financial planner, they'll know exactly which biases to watch for in your decisions. This is not a generic quiz — it's a professional assessment tool.",
                        citation: "BFAS · Behavioural Finance Assessment Score"
                    )
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#4CAF50").opacity(0.12), lineWidth: 0.5))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
        }
        .background(Color(hex: "#FAFAF8"))
        .navigationBarHidden(true)
    }
}

// ── COMPARISON ROW ──
struct CompareRow: View {
    let label: String
    let bad: String
    let good: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#0A1A0A"))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "#FF6B5B"))
                Text(bad)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .frame(width: 90, alignment: .center)

            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "#4CAF50"))
                Text(good)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#1B5E20"))
            }
            .frame(width: 110, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .overlay(Rectangle()
            .frame(height: 0.5)
            .foregroundColor(Color(hex: "#4CAF50").opacity(0.1)),
            alignment: .bottom)
    }
}

#Preview {
    WhyView()
}
