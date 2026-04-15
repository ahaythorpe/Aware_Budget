import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showCredibility = false
    var selectedTab: Binding<RootTab>? = nil
    let totalPatterns = 16

    var awarenessPercent: Double {
        Double(viewModel.biasesSeenCount) / Double(totalPatterns)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── GREETING (Nudge-branded notification) ──
                HStack(alignment: .center, spacing: 14) {
                    Image("nudge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.welcomeMessage)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(viewModel.todayLabel)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(DS.textTertiary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundStyle(DS.deepGreen)
                }
                .padding(16)
                .background(DS.paleGreen, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.deepGreen, lineWidth: 1)
                )
                .padding(.horizontal, 18)
                .padding(.top, 14)
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
                    .background(DS.heroGradient)
                    .cornerRadius(DS.cardRadius)

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
                    }
                    .goldButtonStyle()
                }
                .padding(14)
                .background(DS.heroGradient)
                .cornerRadius(16)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── MONTH CALENDAR ──
                MonthCalendarView(eventsByDay: viewModel.monthEventsByDay)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)

                // ── TOP 4 BIASES ──
                TopBiasesCard(
                    patterns: viewModel.dailyPatterns,
                    totalSeen: viewModel.biasesSeenCount,
                    onInfoTap: { showCredibility = true }
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── NUDGE ──
                NudgeSaysCard(
                    message: viewModel.nudgeMessage?.body ?? "Stay aware. Adjust early. No shame."
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
        .background(DS.bg)
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showCredibility) {
            CredibilitySheet(onReadMore: {
                selectedTab?.wrappedValue = .why
            })
        }
    }
}
