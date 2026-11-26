import XCTest
@testable import Miqyas

final class ReviewPromptTrackerTests: XCTestCase {
    private let version = "2.1.0"

    func testThresholdIsTenSuccessfulConversions() {
        XCTAssertEqual(ReviewPromptTracker.threshold, 10)
        var tracker = ReviewPromptTracker()

        for n in 1..<ReviewPromptTracker.threshold {
            let outcome = record(&tracker, n)
            XCTAssertTrue(outcome.counted)
            XCTAssertFalse(outcome.shouldRequestReview, "Conversion \(n) should not prompt")
        }
        XCTAssertEqual(tracker.successfulConversionCount, 9)

        let tenth = record(&tracker, 10)
        XCTAssertTrue(tenth.counted)
        XCTAssertTrue(tenth.shouldRequestReview)
        XCTAssertEqual(tracker.successfulConversionCount, 10)
    }

    func testInvalidInputDoesNotCountOrPrompt() {
        var tracker = ReviewPromptTracker()
        let invalid: [(String, Double?)] = [
            ("", 1),
            ("   ", 1),
            ("abc", nil),
            ("1.", nil),
            ("--", nil),
            ("١٢", 12),
            ("inf", .infinity),
            ("nan", .nan),
            ("1", nil),
            ("1", .infinity),
            ("1", .nan),
        ]

        for (index, sample) in invalid.enumerated() {
            let outcome = tracker.record(
                normalizedInput: sample.0,
                result: sample.1,
                signature: "invalid-\(index)",
                isReload: false,
                currentVersion: version
            )
            XCTAssertEqual(outcome, .ignored)
        }

        XCTAssertEqual(tracker.successfulConversionCount, 0)
        XCTAssertFalse(record(&tracker, 1).shouldRequestReview)
        XCTAssertEqual(tracker.successfulConversionCount, 1)
    }

    func testReloadAndDuplicateSignatureDoNotCount() {
        var tracker = ReviewPromptTracker(successfulConversionCount: 9)

        let reload = tracker.record(
            normalizedInput: "1",
            result: 1,
            signature: "visible",
            isReload: true,
            currentVersion: version
        )
        XCTAssertEqual(reload, .ignored)
        XCTAssertEqual(tracker.successfulConversionCount, 9)

        let sameAgain = tracker.record(
            normalizedInput: "1",
            result: 1,
            signature: "visible",
            isReload: false,
            currentVersion: version
        )
        XCTAssertEqual(sameAgain, .ignored)
        XCTAssertEqual(tracker.successfulConversionCount, 9)

        let next = tracker.record(
            normalizedInput: "2",
            result: 2,
            signature: "next",
            isReload: false,
            currentVersion: version
        )
        XCTAssertTrue(next.counted)
        XCTAssertTrue(next.shouldRequestReview)
        XCTAssertEqual(tracker.successfulConversionCount, 10)
    }

    func testReturningToAnEarlierValueCountsAsANewConversion() {
        var tracker = ReviewPromptTracker()
        XCTAssertTrue(record(&tracker, 1).counted)
        XCTAssertTrue(record(&tracker, 2).counted)
        XCTAssertTrue(record(&tracker, 1).counted)
        XCTAssertEqual(tracker.successfulConversionCount, 3)
    }

    func testZeroAndNegativeResultsCount() {
        var tracker = ReviewPromptTracker()
        let zero = tracker.record(
            normalizedInput: "0",
            result: 0,
            signature: "zero",
            isReload: false,
            currentVersion: version
        )
        let negative = tracker.record(
            normalizedInput: " -5 ",
            result: -5,
            signature: "negative",
            isReload: false,
            currentVersion: version
        )
        XCTAssertTrue(zero.counted)
        XCTAssertTrue(negative.counted)
        XCTAssertEqual(tracker.successfulConversionCount, 2)
    }

    func testPromptIsOncePerVersionAndCanHappenAgainAfterAnUpdate() {
        var tracker = ReviewPromptTracker(successfulConversionCount: 9)
        XCTAssertTrue(record(&tracker, 10).shouldRequestReview)

        tracker.markReviewRequested(version: version)
        for n in 11...15 {
            let outcome = record(&tracker, n)
            XCTAssertTrue(outcome.counted)
            XCTAssertFalse(outcome.shouldRequestReview)
        }

        let updated = tracker.record(
            normalizedInput: "16",
            result: 16,
            signature: "sig-16",
            isReload: false,
            currentVersion: "2.2.0"
        )
        XCTAssertTrue(updated.counted)
        XCTAssertTrue(updated.shouldRequestReview)

        tracker.markReviewRequested(version: "2.2.0")
        let afterUpdate = record(&tracker, 17, version: "2.2.0")
        XCTAssertTrue(afterUpdate.counted)
        XCTAssertFalse(afterUpdate.shouldRequestReview)
    }

    func testReloadDoesNotPromptEvenWhenANewVersionIsDue() {
        var tracker = ReviewPromptTracker(
            successfulConversionCount: 10,
            lastPromptedVersion: "1.0"
        )
        let reload = tracker.record(
            normalizedInput: "4",
            result: 4,
            signature: "screen",
            isReload: true,
            currentVersion: "2.0"
        )
        XCTAssertEqual(reload, .ignored)

        let conversion = tracker.record(
            normalizedInput: "8",
            result: 8,
            signature: "done",
            isReload: false,
            currentVersion: "2.0"
        )
        XCTAssertTrue(conversion.shouldRequestReview)
    }

    func testCountAndPromptedVersionPersistAcrossLoads() throws {
        let suiteName = "ReviewPromptTrackerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var tracker = ReviewPromptTracker.load(from: defaults)
        XCTAssertEqual(tracker.successfulConversionCount, 0)
        XCTAssertNil(tracker.lastPromptedVersion)

        for n in 1...10 {
            _ = record(&tracker, n)
        }
        tracker.markReviewRequested(version: version)
        tracker.save(to: defaults)

        var loaded = ReviewPromptTracker.load(from: defaults)
        XCTAssertEqual(loaded.successfulConversionCount, 10)
        XCTAssertEqual(loaded.lastPromptedVersion, version)
        XCTAssertNil(loaded.lastSignature)

        let sameVersion = record(&loaded, 11)
        XCTAssertTrue(sameVersion.counted)
        XCTAssertFalse(sameVersion.shouldRequestReview)

        loaded.save(to: defaults)
        let storedAgain = ReviewPromptTracker.load(from: defaults)
        XCTAssertEqual(storedAgain.successfulConversionCount, 11)
        XCTAssertEqual(storedAgain.lastPromptedVersion, version)
    }

    func testInvalidAndReloadAttemptsDoNotAdvanceTheThreshold() {
        var tracker = ReviewPromptTracker()
        var counted = 0
        var attempts = 0

        while counted < ReviewPromptTracker.threshold {
            attempts += 1
            if attempts % 3 == 0 {
                let ignored = tracker.record(
                    normalizedInput: "nope",
                    result: nil,
                    signature: "bad-\(attempts)",
                    isReload: false,
                    currentVersion: version
                )
                XCTAssertFalse(ignored.counted)
            } else if attempts % 3 == 1 && counted > 0 {
                let reload = tracker.record(
                    normalizedInput: "\(counted)",
                    result: Double(counted),
                    signature: "sig-\(counted)",
                    isReload: true,
                    currentVersion: version
                )
                XCTAssertFalse(reload.counted)
                XCTAssertFalse(reload.shouldRequestReview)
            } else {
                counted += 1
                let outcome = record(&tracker, counted)
                XCTAssertTrue(outcome.counted)
                XCTAssertEqual(outcome.shouldRequestReview, counted == ReviewPromptTracker.threshold)
            }
            XCTAssertEqual(tracker.successfulConversionCount, counted)
        }

        XCTAssertGreaterThan(attempts, ReviewPromptTracker.threshold)
    }

    @discardableResult
    private func record(
        _ tracker: inout ReviewPromptTracker,
        _ n: Int,
        version: String? = nil
    ) -> ReviewPromptTracker.Outcome {
        tracker.record(
            normalizedInput: "\(n)",
            result: Double(n),
            signature: "sig-\(n)",
            isReload: false,
            currentVersion: version ?? self.version
        )
    }
}
