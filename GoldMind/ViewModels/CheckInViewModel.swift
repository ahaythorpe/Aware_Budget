import Foundation
import SwiftUI

@MainActor
@Observable
final class CheckInViewModel {
    var question: Question?
    var response: String = ""
    var emotionalTone: CheckIn.EmotionalTone = .neutral
    var showWhy: Bool = false
    var isSaving = false
    var isComplete = false
    var resultingStreak: Int = 0
    var errorMessage: String?

    private let service = SupabaseService.shared

    func load() async {
        do {
            question = try await service.fetchNextQuestion()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submit() async {
        guard !isSaving, let uid = await service.currentUserId else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let streak = try await computeStreak()
            let alignment = try await computeAlignment()

            let checkIn = CheckIn(
                id: UUID(),
                userId: uid,
                date: Date(),
                questionId: question?.id,
                response: response.isEmpty ? nil : response,
                emotionalTone: emotionalTone,
                streakCount: streak,
                alignmentPct: alignment,
                createdAt: Date()
            )
            try await service.saveCheckIn(checkIn)

            resultingStreak = streak
            isComplete = true

            NotificationService.cancelIfCheckedIn()
            await NotificationService.requestPermission()
            NotificationService.scheduleDailyReminder()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func computeStreak() async throws -> Int {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        if let y = try await service.fetchCheckIn(on: yesterday) {
            return y.streakCount + 1
        }
        return 1
    }

    private func computeAlignment() async throws -> Double {
        let now = Date()
        let month = try await service.fetchOrCreateBudgetMonth(for: now)
        let events = try await service.fetchMoneyEvents(forMonth: now)
        let unplanned = events
            .filter { $0.plannedStatus.isUnplanned }
            .reduce(0.0) { $0 + $1.amount }
        guard month.incomeTarget > 0 else { return 0 }
        let pct = (1 - unplanned / month.incomeTarget) * 100
        return max(0, min(100, pct))
    }
}
