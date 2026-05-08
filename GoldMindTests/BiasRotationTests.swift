import XCTest
@testable import GoldMind

/// Unit tests for the bias-tagging math. These guard the algorithm
/// rigour story: if any of these fail in CI later, the algorithm has
/// silently changed shape.
///
/// **Activation:** there's no test target yet. To run these:
/// 1. In Xcode → File → New → Target → Unit Testing Bundle
/// 2. Name it `GoldMindTests` (matches this folder)
/// 3. The PBXFileSystemSynchronizedRootGroup setup picks these up
///    automatically — no manual project.pbxproj edit needed.
final class BiasRotationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Each test starts with a clean rotation index per pattern
        // so order assertions are deterministic.
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("biasRot_") {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Rotation

    func test_nextBias_advancesAcrossShortlist() {
        let s1 = BiasRotation.nextBias(category: "Coffee", status: .impulse)
        let s2 = BiasRotation.nextBias(category: "Coffee", status: .impulse)
        let s3 = BiasRotation.nextBias(category: "Coffee", status: .impulse)
        XCTAssertNotEqual(s1, s2, "Rotation should advance to a different bias")
        XCTAssertNotEqual(s2, s3)
    }

    func test_nextBias_loopsAtEndOfShortlist() {
        let list = BiasRotation.shortlist(category: "Coffee", status: .impulse)
        var picks: [String] = []
        for _ in 0..<list.count + 1 {
            picks.append(BiasRotation.nextBias(category: "Coffee", status: .impulse))
        }
        XCTAssertEqual(picks.first, picks.last, "Rotation should loop back to the start")
    }

    func test_rotation_isPerCategoryStatus() {
        // Independent rotation indices per (category, status).
        let coffee = BiasRotation.nextBias(category: "Coffee", status: .impulse)
        let lunch = BiasRotation.nextBias(category: "Lunch", status: .impulse)
        // The first pick from each independent rotation should be the
        // first item in their respective shortlists, not affected by
        // the other rotation.
        let coffeeList = BiasRotation.shortlist(category: "Coffee", status: .impulse)
        let lunchList = BiasRotation.shortlist(category: "Lunch", status: .impulse)
        XCTAssertEqual(coffee, coffeeList.first)
        XCTAssertEqual(lunch, lunchList.first)
    }

    func test_peekNextBias_doesNotAdvance() {
        let p1 = BiasRotation.peekNextBias(category: "Coffee", status: .impulse)
        let p2 = BiasRotation.peekNextBias(category: "Coffee", status: .impulse)
        XCTAssertEqual(p1, p2, "peekNextBias should not advance the index")
    }

    // MARK: - Shortlist coverage

    func test_shortlist_isNonEmptyForAllPlannedStatuses() {
        let categories = ["Coffee", "Lunch", "Drinks", "Eating out", "Shopping",
                          "Clothing", "Transport", "Pharmacy", "Subscriptions",
                          "Entertainment", "Travel", "Gift", "Home", "Fitness",
                          "Big purchase"]
        for cat in categories {
            for status in MoneyEvent.PlannedStatus.allCases {
                let list = BiasRotation.shortlist(category: cat, status: status)
                XCTAssertFalse(list.isEmpty,
                               "shortlist for (\(cat), \(status.rawValue)) is empty")
            }
        }
    }

    func test_shortlist_allEntriesAreKnownBiases() {
        let validBiases = Set(BFASQuestion.seed.map(\.biasName))
        let list = BiasRotation.shortlist(category: "Coffee", status: .impulse)
        for bias in list {
            XCTAssertTrue(validBiases.contains(bias),
                          "Unknown bias '\(bias)' in shortlist")
        }
    }

    // MARK: - Adaptive threshold

    func test_adaptiveThreshold_clampsLow() {
        // Daily logger: gap=1 → max(14, min(60, 5)) = 14
        XCTAssertEqual(BiasRotation.adaptiveThreshold(medianGapDays: 1), 14)
    }

    func test_adaptiveThreshold_scalesMidRange() {
        // Weekly logger: gap=7 → max(14, min(60, 35)) = 35
        XCTAssertEqual(BiasRotation.adaptiveThreshold(medianGapDays: 7), 35)
    }

    func test_adaptiveThreshold_clampsHigh() {
        // Monthly logger: gap=30 → max(14, min(60, 150)) = 60 (capped)
        XCTAssertEqual(BiasRotation.adaptiveThreshold(medianGapDays: 30), 60)
    }

    func test_adaptiveThreshold_zeroFallsBackToDefault() {
        XCTAssertEqual(BiasRotation.adaptiveThreshold(medianGapDays: 0),
                       BiasRotation.neglectedThresholdDays)
    }

    func test_medianLogGapDays_belowTwoEventsReturnsZero() {
        XCTAssertEqual(BiasRotation.medianLogGapDays(events: []), 0)
    }

    // MARK: - Neglected-bias boost

    func test_boostedPick_returnsRotatedWhenNoNeglectedBias() {
        let progress: [BiasProgress] = []  // empty — nothing qualifies as neglected
        let rotated = "Ego Depletion"
        let boosted = BiasRotation.boostedPick(
            rotatedPick: rotated,
            category: "Coffee",
            status: .impulse,
            progress: progress
        )
        XCTAssertEqual(boosted, rotated,
                       "With no progress, should fall back to the rotation pick")
    }

    func test_boostedPick_promotesBiasOlderThanThreshold() {
        // Build a progress row with a stale lastSeen for "Status Quo Bias"
        // (which is in the Coffee+Impulse shortlist).
        let stale = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let progress = [BiasProgress(
            id: UUID(), userId: UUID(), biasName: "Status Quo Bias",
            timesEncountered: 1, timesReflected: 0,
            firstSeen: stale, lastSeen: stale, createdAt: stale
        )]
        let boosted = BiasRotation.boostedPick(
            rotatedPick: "Ego Depletion",
            category: "Coffee",
            status: .impulse,
            progress: progress,
            thresholdDays: 14
        )
        XCTAssertEqual(boosted, "Status Quo Bias",
                       "Should promote the stale bias when it qualifies")
    }

    func test_boostedPick_ignoresBiasesNotInShortlist() {
        // Anchoring is in Coffee+Planned, NOT Coffee+Impulse. Stale Anchoring
        // shouldn't get promoted into a Coffee+Impulse log.
        let stale = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let progress = [BiasProgress(
            id: UUID(), userId: UUID(), biasName: "Anchoring",
            timesEncountered: 1, timesReflected: 0,
            firstSeen: stale, lastSeen: stale, createdAt: stale
        )]
        let boosted = BiasRotation.boostedPick(
            rotatedPick: "Ego Depletion",
            category: "Coffee",
            status: .impulse,
            progress: progress
        )
        XCTAssertEqual(boosted, "Ego Depletion",
                       "Anchoring isn't in Coffee+Impulse shortlist; should NOT promote")
    }

    func test_boostedPick_picksMostNeglectedAmongCandidates() {
        let older = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let newer = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let progress = [
            BiasProgress(id: UUID(), userId: UUID(), biasName: "Status Quo Bias",
                         timesEncountered: 1, timesReflected: 0,
                         firstSeen: newer, lastSeen: newer, createdAt: newer),
            BiasProgress(id: UUID(), userId: UUID(), biasName: "Moral Licensing",
                         timesEncountered: 1, timesReflected: 0,
                         firstSeen: older, lastSeen: older, createdAt: older),
        ]
        let boosted = BiasRotation.boostedPick(
            rotatedPick: "Ego Depletion",
            category: "Coffee",
            status: .impulse,
            progress: progress,
            thresholdDays: 14
        )
        XCTAssertEqual(boosted, "Moral Licensing",
                       "Should pick the most-neglected (oldest lastSeen)")
    }
}
