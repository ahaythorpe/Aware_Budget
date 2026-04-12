import Foundation
import SwiftUI

@MainActor
@Observable
final class MoneyEventViewModel {
    var amountText: String = ""
    var plannedStatus: MoneyEvent.PlannedStatus = .planned
    var behaviourTag: CheckIn.SpendingDriver?
    var lifeEvent: MoneyEvent.LifeEvent?
    var note: String = ""
    var date: Date = .init()
    var isSaving = false
    var errorMessage: String?
    var didSave = false
    var nudgeResponse: NudgeMessage?

    private let service = SupabaseService.shared

    var parsedAmount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var canSave: Bool { parsedAmount > 0 }

    /// Show behaviour tag picker only for unplanned spend
    var showBehaviourTag: Bool { plannedStatus.isUnplanned }

    /// Show life event picker only for large amounts
    var showLifeEvent: Bool { parsedAmount > 200 }

    func save() async {
        guard !isSaving, let uid = service.currentUserId else { return }
        guard parsedAmount > 0 else {
            errorMessage = "Enter a valid amount."
            return
        }
        isSaving = true
        defer { isSaving = false }

        let event = MoneyEvent(
            id: UUID(),
            userId: uid,
            date: date,
            amount: parsedAmount,
            plannedStatus: plannedStatus,
            behaviourTag: showBehaviourTag ? behaviourTag?.rawValue : nil,
            lifeEvent: showLifeEvent ? lifeEvent?.rawValue : nil,
            note: note.isEmpty ? nil : note,
            createdAt: Date()
        )

        do {
            try await service.saveMoneyEvent(event)

            // Build Nudge response based on pattern
            let tagCount: Int
            if let tag = behaviourTag, showBehaviourTag {
                tagCount = try await service.countBehaviourTag(tag.rawValue)
            } else {
                tagCount = 0
            }

            nudgeResponse = NudgeEngine.moneyEventResponse(
                behaviourTag: showBehaviourTag ? behaviourTag : nil,
                tagCount: tagCount,
                lifeEvent: showLifeEvent ? lifeEvent : nil,
                plannedStatus: plannedStatus
            )

            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
