import SwiftUI

struct MonthCalendarView: View {
    let eventsByDay: [String: [MoneyEvent]]
    @State private var selectedDay: DayKey?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    struct DayKey: Identifiable, Hashable {
        let date: Date
        var id: String { ISO8601DateFormatter.dateOnly.string(from: date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 6) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(DS.onDarkSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(monthGrid, id: \.self) { cell in
                    if let date = cell {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(16)
        .background(DS.frostedCardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.frostedCardStroke, lineWidth: 0.5)
        )
        .popover(item: $selectedDay) { day in
            dayPopover(day.date)
                .presentationCompactAdaptation(.popover)
        }
    }

    private var header: some View {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        let total = eventsByDay.values.flatMap { $0 }.count
        return HStack(alignment: .firstTextBaseline) {
            Text(f.string(from: Date()))
                .font(.system(.headline, design: .default, weight: .semibold))
                .foregroundStyle(DS.onDarkPrimary)
            Spacer()
            Text("\(total) \(total == 1 ? "event" : "events")")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(DS.onDarkSecondary)
                .textCase(.uppercase)
                .tracking(1.0)
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let cal = Calendar.current
        let key = ISO8601DateFormatter.dateOnly.string(from: date)
        let events = eventsByDay[key] ?? []
        let hasEvents = !events.isEmpty
        let isToday = cal.isDateInToday(date)
        let day = cal.component(.day, from: date)

        return Button {
            if hasEvents { selectedDay = DayKey(date: date) }
        } label: {
            Text("\(day)")
                .font(.system(.footnote, weight: hasEvents ? .bold : .medium))
                .foregroundStyle(
                    hasEvents ? DS.goldForeground :
                    isToday ? DS.onDarkPrimary : DS.onDarkSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    ZStack {
                        if hasEvents {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DS.nuggetGold)
                        }
                        if isToday {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DS.goldText, lineWidth: 1.5)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .disabled(!hasEvents)
    }

    private func dayPopover(_ date: Date) -> some View {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        let key = ISO8601DateFormatter.dateOnly.string(from: date)
        let events = eventsByDay[key] ?? []
        let tagCounts = Dictionary(grouping: events.compactMap(\.behaviourTag), by: { $0 })
            .mapValues(\.count)
        let topTags = tagCounts.sorted { $0.value > $1.value }.prefix(3)
        let totalAmount = events.reduce(0.0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 10) {
            Text(f.string(from: date))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.textPrimary)

            HStack(spacing: 6) {
                Text("\(events.count)")
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundStyle(DS.deepGreen)
                Text(events.count == 1 ? "event" : "events")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.textSecondary)
                Spacer()
                Text("$\(Int(totalAmount))")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(DS.goldText)
            }

            if !topTags.isEmpty {
                Divider()
                Text("TOP BIASES")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(DS.accent)
                    .tracking(1.2)
                ForEach(Array(topTags), id: \.key) { tag, count in
                    HStack {
                        Text(tag)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                        Spacer()
                        Text("×\(count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.textSecondary)
                    }
                }
            } else {
                Text("No bias tags that day")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.textTertiary)
                    .italic()
            }
        }
        .padding(14)
        .frame(width: 220)
        .background(DS.cardBg)
    }

    private var monthGrid: [Date?] {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        let now = Date()
        guard
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
            let range = cal.range(of: .day, in: .month, for: monthStart)
        else { return [] }

        // Weekday offset: Monday=0 ... Sunday=6
        let startWeekday = (cal.component(.weekday, from: monthStart) + 5) % 7

        var cells: [Date?] = Array(repeating: nil, count: startWeekday)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) {
                cells.append(d)
            }
        }
        // Pad trailing to complete the last row
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}
