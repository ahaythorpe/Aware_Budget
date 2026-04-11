import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showCheckIn = false
    @State private var showMoneyEvent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                streakCard

                alignmentCard

                if let today = viewModel.todaysCheckIn {
                    toneRow(today.emotionalTone)
                }

                primaryButtons

                recentEventsSection

                NavigationLink {
                    MonthView()
                } label: {
                    HStack {
                        Text("This month")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .fullScreenCover(isPresented: $showCheckIn, onDismiss: {
            Task { await viewModel.load() }
        }) {
            NavigationStack { CheckInView() }
        }
        .sheet(isPresented: $showMoneyEvent, onDismiss: {
            Task { await viewModel.load() }
        }) {
            NavigationStack { MoneyEventView() }
        }
    }

    private var header: some View {
        HStack {
            Text("AwareBudget")
                .font(.title2.bold())
            Spacer()
            Button {
                // Settings placeholder
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(viewModel.streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text(viewModel.streak == 1 ? "day" : "days")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text(viewModel.streakMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var alignmentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(Int(viewModel.alignmentPct))%")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.alignmentColor)
            Text("aligned this month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(viewModel.alignmentReassurance)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func toneRow(_ tone: CheckIn.EmotionalTone) -> some View {
        HStack {
            Text("Today's tone")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(tone.emoji) \(tone.label)")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 4)
    }

    private var primaryButtons: some View {
        VStack(spacing: 12) {
            Button {
                showCheckIn = true
            } label: {
                HStack {
                    if viewModel.isCheckedInToday {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Checked in today")
                    } else {
                        Text("Check in today")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isCheckedInToday ? Color.green : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showMoneyEvent = true
            } label: {
                Text("Log money event")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var recentEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent events")
                .font(.headline)
            if viewModel.recentEvents.isEmpty {
                Text("No events logged yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentEvents) { event in
                    HStack {
                        Text(event.eventType.emoji)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.category ?? event.eventType.label)
                                .fontWeight(.medium)
                            Text(event.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
