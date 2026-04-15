import Foundation
import Observation

#if DEBUG
/// Observable wrapper so the DEBUG auth status banner on Home re-renders
/// whenever ensureDebugSession updates the value. @MainActor because
/// SwiftUI expects state changes on main.
@Observable
@MainActor
final class DebugAuthStatus {
    static let shared = DebugAuthStatus()
    var status: String = "unknown"
    private init() {}
}
#endif
