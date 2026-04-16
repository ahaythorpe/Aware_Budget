import XCTest
@testable import AwareBudget

/// Tests for the score weights + stage transitions. These guard the
/// 5:1 active-vs-passive ratio that's the entire scoring rationale
/// (see docs/ALGORITHM.md §6). If anyone changes a weight, these
/// fail loudly.
final class BiasScoreServiceTests: XCTestCase {

    // MARK: - Weight constants

    func test_weights_match5to1ActivePassiveRatio() {
        XCTAssertEqual(BiasScoreService.yesWeight, 5,
                       "YES must outweigh passive event tag 5:1 (literature ratio)")
        XCTAssertEqual(BiasScoreService.taggedWeight, 1)
        XCTAssertEqual(BiasScoreService.differentWeight, -2)
        XCTAssertEqual(BiasScoreService.notSureWeight, 0)
    }

    func test_noWeightAliasMatchesDifferent() {
        // Backward-compat alias — see BiasScoreService.swift
        XCTAssertEqual(BiasScoreService.noWeight, BiasScoreService.differentWeight)
    }

    // MARK: - Score arithmetic

    func test_computeScore_arithmeticHonoursWeights() {
        // 3 YES, 2 tagged events, no DIFFERENT, BFAS baseline 0
        let progress = BiasProgress(
            id: UUID(), userId: UUID(), biasName: "Loss Aversion",
            timesEncountered: 3, timesReflected: 0,
            firstSeen: nil, lastSeen: nil, createdAt: Date()
        )
        let score = BiasScoreService.computeScore(
            biasName: "Loss Aversion",
            progress: progress,
            taggedEvents: 2
        )
        // yesCount = 3 - 0 = 3 → 3*5 = 15
        // taggedEvents = 2 → 2*1 = 2
        // expected total = 15 + 2 = 17
        XCTAssertEqual(score.score, 17)
    }

    func test_computeScore_includesBfasBaseline() {
        let progress = BiasProgress(
            id: UUID(), userId: UUID(), biasName: "Status Quo Bias",
            timesEncountered: 0, timesReflected: 0,
            firstSeen: nil, lastSeen: nil, createdAt: Date(),
            bfasWeight: 7
        )
        let score = BiasScoreService.computeScore(
            biasName: "Status Quo Bias",
            progress: progress,
            taggedEvents: 0
        )
        XCTAssertEqual(score.score, 7, "BFAS baseline should add directly to score")
    }

    func test_computeScore_nilProgressTreatsAsBlank() {
        let score = BiasScoreService.computeScore(
            biasName: "Anchoring",
            progress: nil,
            taggedEvents: 1
        )
        // 0 yes + 1 tagged * 1 + 0 BFAS = 1
        XCTAssertEqual(score.score, 1)
    }

    // MARK: - Mastery stages

    func test_calculateStage_unseenWhenZeroYes() {
        let stage = BiasScoreService.calculateStage(score: 0, recentAnswers: [])
        XCTAssertEqual(stage, .unseen)
    }

    func test_calculateStage_noticedWith1Or2Yes() {
        let stage = BiasScoreService.calculateStage(score: 5, recentAnswers: [true, false])
        XCTAssertEqual(stage, .noticed)
    }

    func test_calculateStage_emergingWith3To5Yes() {
        let stage = BiasScoreService.calculateStage(
            score: 15,
            recentAnswers: [true, true, true, false]
        )
        XCTAssertEqual(stage, .emerging)
    }

    func test_calculateStage_activeWithMore() {
        let stage = BiasScoreService.calculateStage(
            score: 30,
            recentAnswers: [true, true, true, true, true, true, false]
        )
        XCTAssertEqual(stage, .active)
    }

    func test_calculateStage_improvingWithLast3No() {
        let answers: [Bool] = [true, true, true, false, false, false]
        let stage = BiasScoreService.calculateStage(score: 15, recentAnswers: answers)
        XCTAssertEqual(stage, .improving,
                       "3 NO in a row should signal improving")
    }

    func test_calculateStage_awareAfter21NoStreak() {
        let answers = Array(repeating: false, count: 22)
        let stage = BiasScoreService.calculateStage(score: 0, recentAnswers: answers)
        XCTAssertEqual(stage, .aware)
    }

    // MARK: - Trend

    func test_calculateTrend_improvingWhenSecondHalfHasFewerYes() {
        let answers: [Bool] = [true, true, true, false, false, false]
        XCTAssertEqual(BiasScoreService.calculateTrend(recentAnswers: answers), .improving)
    }

    func test_calculateTrend_stableWhenEqual() {
        let answers: [Bool] = [true, false, true, false]
        XCTAssertEqual(BiasScoreService.calculateTrend(recentAnswers: answers), .stable)
    }

    func test_calculateTrend_worseningWhenSecondHalfHasMoreYes() {
        let answers: [Bool] = [false, false, false, true, true, true]
        XCTAssertEqual(BiasScoreService.calculateTrend(recentAnswers: answers), .worsening)
    }

    func test_calculateTrend_stableForShortHistory() {
        XCTAssertEqual(BiasScoreService.calculateTrend(recentAnswers: [true]), .stable)
    }
}
