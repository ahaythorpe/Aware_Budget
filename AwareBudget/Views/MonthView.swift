import SwiftUI

struct MonthView: View {
    @State private var events: [MoneyEvent] = []
    @State private var alignment: Double = 0
    @State private var incomeTarget: Double = 0
    @State private var isEditingTarget = false
    @State private var targetText: String = ""
    @State private var isLoading = false

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    private var alignmentColor: Color {
        switch alignment {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(monthLabel)
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int(alignment))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(alignmentColor)
                    Text("aligned this month")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    targetText = String(format: "%.0f", incomeTarget)
                    isEditingTarget = true
                } label: {
                    HStack {
                        Text("Income target")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(incomeTarget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                categoryBreakdown

                eventsByType
            }
            .padding(16)
        }
        .navigationTitle("This month")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert("Income target", isPresented: $isEditingTarget) {
            TextField("Amount", text: $targetText)
            #if !os(macOS)
                .keyboardType(.decimalPad)
            #endif
            Button("Save") {
                Task {
                    let value = Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0
                    try? await SupabaseService.shared.updateIncomeTarget(value, for: Date())
                    await load()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var categoryBreakdown: some View {
        let totals = Dictionary(grouping: events, by: { $0.category ?? "Other" })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        return VStack(alignment: .leading, spacing: 8) {
            Text("By category").font(.headline)
            if totals.isEmpty {
                Text("No events yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(totals.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var eventsByType: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(MoneyEvent.EventType.allCases) { type in
                let items = events.filter { $0.eventType == type }
                if !items.isEmpty {
                    Text("\(type.emoji) \(type.label)").font(.headline)
                    ForEach(items) { event in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.category ?? type.label)
                                Text(event.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(event.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .fontWeight(.medium)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let now = Date()
            let month = try await SupabaseService.shared.fetchOrCreateBudgetMonth(for: now)
            incomeTarget = month.incomeTarget
            events = try await SupabaseService.shared.fetchMoneyEvents(forMonth: now)

            let unplanned = events.filter { $0.eventType == .surprise }.reduce(0.0) { $0 + $1.amount }
            if month.incomeTarget > 0 {
                alignment = max(0, min(100, (1 - unplanned / month.incomeTarget) * 100))
            } else {
                alignment = 0
            }
        } catch {
            // swallow — month view is read-only
        }
    }
}
