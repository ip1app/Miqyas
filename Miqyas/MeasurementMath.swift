import Foundation

// Pure measurement math. No sensors, UI, or localization, so unit tests can
// cover the Qibla formula, the level angles, and the sound-level conversion
// without hardware.

// MARK: - Angles

nonisolated enum CompassMath {
    /// Headings worse than this (degrees, 1σ) are treated as poorly calibrated.
    /// A negative Core Location accuracy means the heading is invalid.
    static let poorAccuracyDegrees = 25.0

    static func positiveDegrees(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return 0 }
        let wrapped = degrees.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }

    /// Shortest signed turn from `heading` to `bearing`, in degrees.
    /// Positive is clockwise (turn right). Range is −180...180.
    static func signedDelta(from heading: Double, to bearing: Double) -> Double {
        var delta = positiveDegrees(bearing - heading)
        if delta > 180 {
            delta -= 360
        }
        return delta
    }

    static func cardinal(forDegrees degrees: Double) -> CardinalDirection {
        let normalized = positiveDegrees(degrees)
        let index = Int((normalized + 22.5) / 45.0) % CardinalDirection.allCases.count
        return CardinalDirection.allCases[index]
    }

    static func needsCalibration(headingAccuracy: Double) -> Bool {
        headingAccuracy < 0 || headingAccuracy > poorAccuracyDegrees
    }

    /// Prefers true north when Core Location provides it, otherwise magnetic north.
    /// Returns nil when the accuracy is negative (invalid heading).
    static func resolvedHeading(trueHeading: Double, magneticHeading: Double, accuracy: Double) -> HeadingFix? {
        guard accuracy >= 0 else { return nil }
        if trueHeading >= 0 {
            return HeadingFix(
                degrees: positiveDegrees(trueHeading),
                isTrueNorth: true,
                accuracy: accuracy
            )
        }
        guard magneticHeading >= 0 else { return nil }
        return HeadingFix(
            degrees: positiveDegrees(magneticHeading),
            isTrueNorth: false,
            accuracy: accuracy
        )
    }
}

nonisolated enum CardinalDirection: Int, CaseIterable, Equatable, Sendable {
    case north
    case northEast
    case east
    case southEast
    case south
    case southWest
    case west
    case northWest
}

nonisolated struct HeadingFix: Equatable, Sendable {
    var degrees: Double
    var isTrueNorth: Bool
    var accuracy: Double
}

// MARK: - Qibla

nonisolated enum QiblaMath {
    /// Kaaba, Masjid al-Haram.
    static let kaabaLatitude = 21.4225
    static let kaabaLongitude = 39.8262

    /// IUGG mean Earth radius, used for the great-circle distance.
    static let earthRadiusKilometers = 6371.0

    /// Inside this distance the bearing is not meaningful to display.
    static let atKaabaThresholdKilometers = 0.05

    static func qibla(fromLatitude latitude: Double, longitude: Double) -> Qibla? {
        guard isValidCoordinate(latitude: latitude, longitude: longitude) else { return nil }
        let bearing = initialBearingDegrees(
            fromLatitude: latitude,
            fromLongitude: longitude,
            toLatitude: kaabaLatitude,
            toLongitude: kaabaLongitude
        )
        let distance = distanceKilometers(
            fromLatitude: latitude,
            fromLongitude: longitude,
            toLatitude: kaabaLatitude,
            toLongitude: kaabaLongitude
        )
        return Qibla(bearingDegrees: bearing, distanceKilometers: distance)
    }

    static func isAtKaaba(distanceKilometers: Double) -> Bool {
        distanceKilometers >= 0 && distanceKilometers < atKaabaThresholdKilometers
    }

    /// Initial great-circle bearing, degrees clockwise from true north, in [0, 360).
    static func initialBearingDegrees(
        fromLatitude: Double,
        fromLongitude: Double,
        toLatitude: Double,
        toLongitude: Double
    ) -> Double {
        let phi1 = fromLatitude * .pi / 180
        let phi2 = toLatitude * .pi / 180
        let deltaLambda = (toLongitude - fromLongitude) * .pi / 180
        let y = sin(deltaLambda) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda)
        let degrees = atan2(y, x) * 180 / .pi
        return CompassMath.positiveDegrees(degrees)
    }

    /// Haversine distance in kilometers.
    static func distanceKilometers(
        fromLatitude: Double,
        fromLongitude: Double,
        toLatitude: Double,
        toLongitude: Double
    ) -> Double {
        let phi1 = fromLatitude * .pi / 180
        let phi2 = toLatitude * .pi / 180
        let deltaPhi = phi2 - phi1
        let deltaLambda = (toLongitude - fromLongitude) * .pi / 180
        let a = sin(deltaPhi / 2) * sin(deltaPhi / 2)
            + cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return max(0, earthRadiusKilometers * c)
    }

    private static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite && abs(latitude) <= 90 && abs(longitude) <= 180
    }
}

nonisolated struct Qibla: Equatable, Sendable {
    var bearingDegrees: Double
    var distanceKilometers: Double
}

// MARK: - Level

/// How the phone's interface is rotated relative to the hardware.
/// Screen coordinates are +x right and +y down.
nonisolated enum LevelInterfaceOrientation: Sendable {
    case portrait
    /// Device top points to the user's left (status bar on the left).
    case landscapeDeviceTopLeft
    /// Device top points to the user's right (status bar on the right).
    case landscapeDeviceTopRight
    case portraitUpsideDown
}

nonisolated struct GravityVector: Equatable, Sendable {
    var x: Double
    var y: Double
    var z: Double

    var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    func normalized() -> GravityVector? {
        let length = magnitude
        guard length > 1e-8 else { return nil }
        return GravityVector(x: x / length, y: y / length, z: z / length)
    }

    static func dot(_ lhs: GravityVector, _ rhs: GravityVector) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }

    static func cross(_ lhs: GravityVector, _ rhs: GravityVector) -> GravityVector {
        GravityVector(
            x: lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.z * rhs.x - lhs.x * rhs.z,
            z: lhs.x * rhs.y - lhs.y * rhs.x
        )
    }

    static func + (lhs: GravityVector, rhs: GravityVector) -> GravityVector {
        GravityVector(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    static func * (lhs: GravityVector, scale: Double) -> GravityVector {
        GravityVector(x: lhs.x * scale, y: lhs.y * scale, z: lhs.z * scale)
    }
}

nonisolated struct ScreenOffset: Equatable, Sendable {
    var x: Double
    var y: Double
}

nonisolated struct LevelReading: Equatable, Sendable {
    /// Bubble position in the device frame. +x is toward the right side of the phone,
    /// +y is toward the top. About −1...1, where ±1 means the bubble is against the rim.
    var bubbleX: Double
    var bubbleY: Double
    /// Tilt away from flat, degrees, always ≥ 0. Zero means the screen is horizontal.
    var tiltDegrees: Double
    /// Angle of the phone's long edge from horizontal, degrees, about −90...90.
    /// Positive means the top of the phone is raised.
    var edgeAngleDegrees: Double
    var isSurfaceLevel: Bool
    var isEdgeLevel: Bool

    static let flat = LevelReading(
        bubbleX: 0,
        bubbleY: 0,
        tiltDegrees: 0,
        edgeAngleDegrees: 0,
        isSurfaceLevel: true,
        isEdgeLevel: true
    )
}

nonisolated enum LevelMath {
    /// Device gravity when the phone is flat, screen up: +x right, +y toward the top, +z out of the screen.
    static let screenUpGravity = GravityVector(x: 0, y: 0, z: -1)

    /// A tilt inside this range counts as level for the raw reading.
    static let levelThresholdDegrees = 0.8

    /// Tilt, in degrees, that pins the bubble to the rim. Smaller tilts stay visible.
    static let bubbleFullScaleDegrees = 12.0

    static func reading(
        gravity: GravityVector,
        reference: GravityVector? = nil,
        levelThresholdDegrees: Double = LevelMath.levelThresholdDegrees
    ) -> LevelReading {
        let adjusted: GravityVector
        if let reference {
            adjusted = calibratedGravity(current: gravity, reference: reference)
        } else {
            adjusted = gravity
        }
        guard let unit = adjusted.normalized() else { return .flat }
        let tilt = surfaceTiltDegrees(x: unit.x, y: unit.y, z: unit.z)
        let edge = edgeAngleDegrees(x: unit.x, y: unit.y, z: unit.z)
        let bubble = bubbleOffset(unitX: unit.x, unitY: unit.y)
        return LevelReading(
            bubbleX: bubble.x,
            bubbleY: bubble.y,
            tiltDegrees: tilt,
            edgeAngleDegrees: edge,
            isSurfaceLevel: tilt <= levelThresholdDegrees,
            isEdgeLevel: abs(edge) <= levelThresholdDegrees
        )
    }

    /// Angle between gravity and the screen axis, 0 when the phone is flat on either face.
    static func surfaceTiltDegrees(x: Double, y: Double, z: Double) -> Double {
        atan2(hypot(x, y), abs(z)) * 180 / .pi
    }

    /// Angle of the device +Y axis (top of the phone) from horizontal.
    static func edgeAngleDegrees(x: Double, y: Double, z: Double) -> Double {
        let magnitude = (x * x + y * y + z * z).squareRoot()
        guard magnitude > 1e-8 else { return 0 }
        let sine = min(1, max(-1, -y / magnitude))
        return asin(sine) * 180 / .pi
    }

    /// Bubble moves uphill, opposite the horizontal part of gravity.
    /// `unitX` and `unitY` are components of a unit gravity vector.
    static func bubbleOffset(unitX: Double, unitY: Double) -> ScreenOffset {
        let limit = sin(bubbleFullScaleDegrees * .pi / 180)
        guard limit > 0 else { return ScreenOffset(x: 0, y: 0) }
        return ScreenOffset(
            x: min(1, max(-1, -unitX / limit)),
            y: min(1, max(-1, -unitY / limit))
        )
    }

    /// Maps a device-frame offset (+x right, +y toward the top of the phone)
    /// into screen coordinates (+x right, +y down) for the current interface.
    static func screenOffset(
        deviceX: Double,
        deviceY: Double,
        orientation: LevelInterfaceOrientation
    ) -> ScreenOffset {
        switch orientation {
        case .portrait:
            return ScreenOffset(x: deviceX, y: -deviceY)
        case .portraitUpsideDown:
            return ScreenOffset(x: -deviceX, y: deviceY)
        case .landscapeDeviceTopLeft:
            return ScreenOffset(x: -deviceY, y: -deviceX)
        case .landscapeDeviceTopRight:
            return ScreenOffset(x: deviceY, y: deviceX)
        }
    }

    /// Shortest rotation that takes `reference` onto screen-up gravity, applied to `current`.
    /// Holding the phone in the zeroed pose then reports a flat, level reading.
    static func calibratedGravity(current: GravityVector, reference: GravityVector) -> GravityVector {
        rotated(current, from: reference, to: screenUpGravity)
    }

    /// Hysteresis so a noisy reading does not flicker in and out of "level".
    static func latchedLevel(
        angleDegrees: Double,
        wasLevel: Bool,
        enterDegrees: Double = 0.6,
        exitDegrees: Double = 1.2
    ) -> Bool {
        let magnitude = abs(angleDegrees)
        if wasLevel {
            return magnitude <= exitDegrees
        }
        return magnitude <= enterDegrees
    }

    private static func rotated(
        _ vector: GravityVector,
        from source: GravityVector,
        to target: GravityVector
    ) -> GravityVector {
        guard let from = source.normalized(),
              let to = target.normalized(),
              let current = vector.normalized() else {
            return vector
        }

        let cosine = min(1, max(-1, GravityVector.dot(from, to)))
        let axis = GravityVector.cross(from, to)
        let sine = axis.magnitude

        if sine < 1e-8 {
            if cosine > 0 {
                return current
            }
            let helper = abs(from.x) < 0.9
                ? GravityVector(x: 1, y: 0, z: 0)
                : GravityVector(x: 0, y: 1, z: 0)
            guard let unitAxis = GravityVector.cross(from, helper).normalized() else {
                return current
            }
            let along = GravityVector.dot(unitAxis, current)
            return (unitAxis * (2 * along)) + (current * -1)
        }

        guard let unitAxis = axis.normalized() else { return current }
        let crossAxis = GravityVector.cross(unitAxis, current)
        let along = GravityVector.dot(unitAxis, current)
        return (current * cosine) + (crossAxis * sine) + (unitAxis * (along * (1 - cosine)))
    }
}

// MARK: - Sound level

nonisolated enum SoundLevelMath {
    /// Digital silence floor used by AVAudioRecorder metering, in dBFS.
    static let silenceFloorDBFS = -160.0

    /// Rough offset that maps 0 dBFS to an approximate displayed level.
    /// Phone microphones are not calibrated sound-level meters; this is only a display scale.
    static let fullScaleOffsetDecibels = 100.0

    static func rootMeanSquare(_ samples: some Sequence<Float>) -> Double {
        var count = 0
        var sum = 0.0
        for sample in samples {
            let value = Double(sample)
            sum += value * value
            count += 1
        }
        guard count > 0 else { return 0 }
        return (sum / Double(count)).squareRoot()
    }

    /// 16-bit PCM samples scaled into −1...1 before the RMS.
    static func rootMeanSquare(int16 samples: some Sequence<Int16>) -> Double {
        var count = 0
        var sum = 0.0
        let scale = 1.0 / 32768.0
        for sample in samples {
            let value = Double(sample) * scale
            sum += value * value
            count += 1
        }
        guard count > 0 else { return 0 }
        return (sum / Double(count)).squareRoot()
    }

    /// 20·log10(rms). A full-scale RMS of 1 is 0 dBFS. Silence is the floor, never above 0.
    static func decibelsFullScale(rms: Double) -> Double {
        guard rms > 0, rms.isFinite else { return silenceFloorDBFS }
        let decibels = 20 * log10(rms)
        if decibels.isNaN || decibels < silenceFloorDBFS {
            return silenceFloorDBFS
        }
        return min(0, decibels)
    }

    static func approximateDecibels(
        dbfs: Double,
        fullScaleOffset: Double = fullScaleOffsetDecibels
    ) -> Double {
        let clamped = min(0, max(silenceFloorDBFS, dbfs.isFinite ? dbfs : silenceFloorDBFS))
        return clamped + fullScaleOffset
    }
}

/// Energy average (Leq-style) of displayed decibel samples, plus min and max.
nonisolated struct SoundAggregate: Equatable, Sendable {
    private(set) var minimum: Double
    private(set) var maximum: Double
    private(set) var energyAverage: Double
    private(set) var sampleCount: Int
    private var meanPower: Double

    init(sample: Double) {
        minimum = sample
        maximum = sample
        energyAverage = sample
        sampleCount = 1
        meanPower = Self.power(of: sample)
    }

    mutating func add(_ decibels: Double) {
        let power = Self.power(of: decibels)
        sampleCount += 1
        minimum = min(minimum, decibels)
        maximum = max(maximum, decibels)
        meanPower += (power - meanPower) / Double(sampleCount)
        energyAverage = 10 * log10(max(meanPower, 1e-12))
    }

    private static func power(of decibels: Double) -> Double {
        pow(10, decibels / 10)
    }
}
