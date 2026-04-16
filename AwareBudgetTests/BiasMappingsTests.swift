import XCTest
@testable import AwareBudget

/// Tests the citation-grounded mapping data. These guard the
/// research-rigour story — if a mapping disappears or loses its
/// citation, the algorithm-explainer surface starts lying.
final class BiasMappingsTests: XCTestCase {

    func test_allMappingsHaveCitations() {
        for mapping in BiasMappings.all {
            XCTAssertFalse(mapping.citation.isEmpty,
                           "Mapping (\(mapping.category) × \(mapping.status) × \(mapping.bias)) has no citation")
        }
    }

    func test_allMappingsReferenceKnownBiases() {
        let validBiases = Set(BFASQuestion.seed.map(\.biasName))
        for mapping in BiasMappings.all {
            XCTAssertTrue(validBiases.contains(mapping.bias),
                          "Mapping references unknown bias: \(mapping.bias)")
        }
    }

    func test_citedBiases_sortsHighConfidenceFirst() {
        // Coffee + Impulse has both high and medium confidence rows.
        let cited = BiasMappings.citedBiases(category: "Coffee", status: .impulse)
        guard !cited.isEmpty else {
            XCTFail("Expected cited biases for Coffee + Impulse")
            return
        }
        // Verify the first entry has high confidence.
        let firstMapping = BiasMappings.all.first(where: {
            $0.category == "Coffee" && $0.status == .impulse && $0.bias == cited[0]
        })
        XCTAssertEqual(firstMapping?.confidence, .high)
    }

    func test_citation_returnsExpectedSource() {
        let citation = BiasMappings.citation(
            category: "Coffee",
            status: .impulse,
            bias: "Ego Depletion"
        )
        XCTAssertNotNil(citation)
        XCTAssertTrue(citation?.contains("Baumeister") == true,
                      "Coffee + Impulse + Ego Depletion should cite Baumeister")
    }

    func test_citation_returnsNilForUncuratedCombo() {
        let citation = BiasMappings.citation(
            category: "Coffee",
            status: .impulse,
            bias: "Confirmation Bias"  // not in any mapping row
        )
        XCTAssertNil(citation)
    }

    func test_subscriptionsPlannedHasStatusQuoBias() {
        // Subscriptions + Planned is the textbook Status Quo case
        // (Samuelson & Zeckhauser 1988 — direct domain match).
        let cited = BiasMappings.citedBiases(category: "Subscriptions", status: .planned)
        XCTAssertTrue(cited.contains("Status Quo Bias"),
                      "Subscriptions+Planned must surface Status Quo Bias — it's the textbook case")
    }

    func test_travelPlannedHasAnchoring() {
        let cited = BiasMappings.citedBiases(category: "Travel", status: .planned)
        XCTAssertTrue(cited.contains("Anchoring"))
        XCTAssertTrue(cited.contains("Planning Fallacy"))
    }
}
