import Foundation

/// Finds the user's historical logging hours from recent `MoneyEvent`s.
/// Used to schedule smart time-of-day nudges (F/N1) — pushes fire at
/// the hours the user actually logs, not arbitrary defaults.
enum LogTimeAnalytics {
    /// Slots of day matching the morning / afternoon / evening nudge
    /// pattern in NotificationService.
    struct SlotHours {
        var morning: Int = 11   // default if no data
        var afternoon: Int = 14
        var evening: Int = 19
    }

    /// Computes median log hour per slot from the given events.
    /// Falls back to defaults for slots with <2 events.
    static func medianHours(from events: [MoneyEvent]) -> SlotHours {
        let cal = Calendar.current
        var hours = SlotHours()

        // Bucket events by slot
        var morningHours: [Int] = []
        var afternoonHours: [Int] = []
        var eveningHours: [Int] = []

        for event in events {
            let hr = cal.component(.hour, from: event.createdAt)
            switch hr {
            case 5..<12:  morningHours.append(hr)
            case 12..<17: afternoonHours.append(hr)
            case 17..<23: eveningHours.append(hr)
            default: break // late-night / pre-dawn ignored
            }
        }

        if morningHours.count >= 2 { hours.morning = median(morningHours) }
        if afternoonHours.count >= 2 { hours.afternoon = median(afternoonHours) }
        if eveningHours.count >= 2 { hours.evening = median(eveningHours) }

        return hours
    }

    private static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }
}
