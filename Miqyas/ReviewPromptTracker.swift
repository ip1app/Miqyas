import Foundation

// MARK: - App Store review prompt

/// Counts successful conversions and decides when to ask for an App Store review.
///
/// A conversion counts only when it produces a new finite result. Showing the
/// conversion already on screen again (a reload) and input that does not parse
/// to a finite number do not count. The prompt is requested once per app version,
/// after `threshold` successful conversions.
nonisolated struct ReviewPromptTracker: Equatable, Sendable {
    static let threshold = 10
    static let countDefaultsKey = "successfulConversionCount"
    static let versionDefaultsKey = "lastReviewPromptedVersion"

    private(set) var successfulConversionCount: Int
    private(set) var lastPromptedVersion: String?
    /// Signature of the conversion currently showing. Matching it is a reload.
    private(set) var lastSignature: String?

    struct Outcome: Equatable, Sendable {
        var counted: Bool
        var shouldRequestReview: Bool

        static let ignored = Outcome(counted: false, shouldRequestReview: false)
    }

    init(
        successfulConversionCount: Int = 0,
        lastPromptedVersion: String? = nil,
        lastSignature: String? = nil
    ) {
        self.successfulConversionCount = max(0, successfulConversionCount)
        self.lastPromptedVersion = lastPromptedVersion
        self.lastSignature = lastSignature
    }

    /// `normalizedInput` must already use ASCII digits. Arabic-Indic digits are
    /// not treated as a successful conversion until the caller normalizes them.
    static func isValidConversion(normalizedInput: String, result: Double?) -> Bool {
        let trimmed = normalizedInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Double(trimmed), parsed.isFinite else { return false }
        guard let result, result.isFinite else { return false }
        return true
    }

    /// Records a conversion attempt.
    /// - Parameter isReload: Pass true for the conversion already visible when the
    ///   screen appears. Reloads never increment the count and never request a review.
    mutating func record(
        normalizedInput: String,
        result: Double?,
        signature: String,
        isReload: Bool,
        currentVersion: String
    ) -> Outcome {
        if isReload {
            lastSignature = signature
            return .ignored
        }
        guard Self.isValidConversion(normalizedInput: normalizedInput, result: result) else {
            return .ignored
        }
        guard signature != lastSignature else {
            return .ignored
        }

        successfulConversionCount += 1
        lastSignature = signature
        let shouldRequest = successfulConversionCount >= Self.threshold
            && lastPromptedVersion != currentVersion
        return Outcome(counted: true, shouldRequestReview: shouldRequest)
    }

    mutating func markReviewRequested(version: String) {
        lastPromptedVersion = version
    }

    static func load(from defaults: UserDefaults) -> ReviewPromptTracker {
        let storedVersion = defaults.string(forKey: versionDefaultsKey)
        let version = (storedVersion?.isEmpty == false) ? storedVersion : nil
        return ReviewPromptTracker(
            successfulConversionCount: defaults.integer(forKey: countDefaultsKey),
            lastPromptedVersion: version
        )
    }

    func save(to defaults: UserDefaults) {
        defaults.set(successfulConversionCount, forKey: Self.countDefaultsKey)
        if let lastPromptedVersion, !lastPromptedVersion.isEmpty {
            defaults.set(lastPromptedVersion, forKey: Self.versionDefaultsKey)
        } else {
            defaults.removeObject(forKey: Self.versionDefaultsKey)
        }
    }
}
