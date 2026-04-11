import Foundation
import SwiftUI

@MainActor
@Observable
final class MoneyEventViewModel {
    var amountText: String = ""
    var eventType: MoneyEvent.EventType = .expected
    var category: MoneyCategory = .other
    var note: String = ""
    var date: Date = .init()
    var isSaving = false
    var errorMessage: String?
    var didSave = false

    private let service = SupabaseService.shared

    var canSave: Bool {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 > 0
    }

    func save() async {
        guard !isSaving, let uid = service.currentUserId else { return }
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            errorMessage = "Enter a valid amount."
            return
        }
        isSaving = true
        defer { isSaving = false }

        let event = MoneyEvent(
            id: UUID(),
            userId: uid,
            date: date,
            amount: amount,
            category: category.rawValue,
            eventType: eventType,
            note: note.isEmpty ? nil : note,
            createdAt: Date()
        )

        do {
            try await service.saveMoneyEvent(event)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
