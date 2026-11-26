import Foundation

// Pure measurement math. No sensors, UI, or localization, so unit tests can
// cover the Qibla formula, the level angles, the sound-level conversion, and
// the ruler, angle, barometer, speed, light, and AR conversions without hardware.

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

// MARK: - Screen ruler

nonisolated enum ScreenRulerMath {
    /// International inch, in centimeters.
    static let centimetersPerInch = 2.54

    /// Physical pixels per inch for panels that are not the scale-based fallback.
    /// Unknown iPhones use 163 / 326 / 460 for @1x / @2x / @3x. Unknown iPads use 264.
    static func pixelsPerInch(modelIdentifier: String, screenScale: Double) -> Double {
        if let known = knownPixelsPerInch[modelIdentifier] {
            return known
        }
        if modelIdentifier.hasPrefix("iPad") {
            return 264
        }
        let scale = screenScale.isFinite && screenScale > 0 ? screenScale : 3
        if scale < 1.5 { return 163 }
        if scale < 2.5 { return 326 }
        return 460
    }

    /// Points per inch. `screenScale` is the screen's native pixel scale, so a
    /// rendered point matches a physical inch on that panel.
    static func pointsPerInch(pixelsPerInch: Double, screenScale: Double) -> Double? {
        guard pixelsPerInch.isFinite, screenScale.isFinite, pixelsPerInch > 0, screenScale > 0 else { return nil }
        return pixelsPerInch / screenScale
    }

    static func inches(points: Double, pointsPerInch: Double) -> Double? {
        guard points.isFinite, pointsPerInch.isFinite, pointsPerInch > 0 else { return nil }
        return points / pointsPerInch
    }

    static func centimeters(points: Double, pointsPerInch: Double) -> Double? {
        guard let inches = inches(points: points, pointsPerInch: pointsPerInch) else { return nil }
        return inches * centimetersPerInch
    }

    static func points(inches: Double, pointsPerInch: Double) -> Double? {
        guard inches.isFinite, pointsPerInch.isFinite, pointsPerInch > 0 else { return nil }
        return inches * pointsPerInch
    }

    static func points(centimeters: Double, pointsPerInch: Double) -> Double? {
        guard centimeters.isFinite else { return nil }
        return points(inches: centimeters / centimetersPerInch, pointsPerInch: pointsPerInch)
    }

    private static let knownPixelsPerInch: [String: Double] = {
        var map: [String: Double] = [:]
        func add(_ ppi: Double, _ identifiers: [String]) {
            for identifier in identifiers {
                map[identifier] = ppi
            }
        }
        add(163, [
            "iPhone1,1", "iPhone1,2", "iPhone2,1",
            "iPad2,5", "iPad2,6", "iPad2,7"
        ])
        add(326, [
            "iPhone3,1", "iPhone3,2", "iPhone3,3", "iPhone4,1",
            "iPhone5,1", "iPhone5,2", "iPhone5,3", "iPhone5,4",
            "iPhone6,1", "iPhone6,2", "iPhone7,2", "iPhone8,1", "iPhone8,4",
            "iPhone9,1", "iPhone9,3", "iPhone10,1", "iPhone10,4",
            "iPhone11,8", "iPhone12,1", "iPhone12,8", "iPhone14,6",
            "iPad4,4", "iPad4,5", "iPad4,6", "iPad4,7", "iPad4,8", "iPad4,9",
            "iPad5,1", "iPad5,2", "iPad11,1", "iPad11,2",
            "iPad14,1", "iPad14,2", "iPad16,1", "iPad16,2"
        ])
        add(401, [
            "iPhone7,1", "iPhone8,2", "iPhone9,2", "iPhone9,4",
            "iPhone10,2", "iPhone10,5"
        ])
        add(458, [
            "iPhone10,3", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6",
            "iPhone12,3", "iPhone12,5", "iPhone13,4", "iPhone14,3", "iPhone14,8"
        ])
        add(476, ["iPhone13,1", "iPhone14,4"])
        add(460, [
            "iPhone13,2", "iPhone13,3", "iPhone14,2", "iPhone14,5", "iPhone14,7",
            "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4", "iPhone17,5",
            "iPhone18,1", "iPhone18,2", "iPhone18,3", "iPhone18,4", "iPhone18,5",
            "iPhone19,2", "iPhone19,3", "iPhone19,7"
        ])
        return map
    }()
}

// MARK: - Protractor

nonisolated struct UnitQuaternion: Equatable, Sendable {
    var x: Double
    var y: Double
    var z: Double
    var w: Double

    static let identity = UnitQuaternion(x: 0, y: 0, z: 0, w: 1)

    var magnitude: Double {
        (x * x + y * y + z * z + w * w).squareRoot()
    }

    func normalized() -> UnitQuaternion? {
        let length = magnitude
        guard length.isFinite, length > 1e-8 else { return nil }
        return UnitQuaternion(x: x / length, y: y / length, z: z / length, w: w / length)
    }

    func inverse() -> UnitQuaternion? {
        guard let unit = normalized() else { return nil }
        return UnitQuaternion(x: -unit.x, y: -unit.y, z: -unit.z, w: unit.w)
    }

    func multiplied(by rhs: UnitQuaternion) -> UnitQuaternion {
        UnitQuaternion(
            x: w * rhs.x + x * rhs.w + y * rhs.z - z * rhs.y,
            y: w * rhs.y - x * rhs.z + y * rhs.w + z * rhs.x,
            z: w * rhs.z + x * rhs.y - y * rhs.x + z * rhs.w,
            w: w * rhs.w - x * rhs.x - y * rhs.y - z * rhs.z
        )
    }

    /// Smallest rotation this quaternion represents, in degrees, from 0 to 180.
    /// Opposite quaternions are the same rotation, so the sign of `w` is ignored.
    var rotationDegrees: Double? {
        guard let unit = normalized() else { return nil }
        let cosineHalf = min(1, max(-1, abs(unit.w)))
        return 2 * acos(cosineHalf) * 180 / .pi
    }

    /// Angle required to turn `self` onto `other`, in degrees, from 0 to 180.
    func angleDegrees(to other: UnitQuaternion) -> Double? {
        guard let inverse else { return nil }
        return other.multiplied(by: inverse).rotationDegrees
    }
}

nonisolated enum AngleMath {
    /// Tilt away from a flat, screen-up pose. Zero is flat and 90 is on edge.
    static func tiltFromFlatDegrees(gravity: GravityVector) -> Double? {
        guard gravity.normalized() != nil else { return nil }
        let tilt = LevelMath.surfaceTiltDegrees(x: gravity.x, y: gravity.y, z: gravity.z)
        guard tilt.isFinite else { return nil }
        return tilt
    }

    /// Angle between two device orientations, using gravity only, from 0 to 180.
    static func angleDegrees(between first: GravityVector, and second: GravityVector) -> Double? {
        guard let left = first.normalized(), let right = second.normalized() else { return nil }
        let cosine = min(1, max(-1, GravityVector.dot(left, right)))
        let degrees = acos(cosine) * 180 / .pi
        guard degrees.isFinite else { return nil }
        return degrees
    }
}

// MARK: - Barometer

/// International Standard Atmosphere troposphere (0–11 km).
/// Height is approximate: the phone does not know the real sea-level pressure or temperature.
nonisolated enum BarometricMath {
    static let gasConstant = 8.314462618
    static let molarMass = 0.0289644
    static let gravity = 9.80665
    static let seaLevelTemperatureKelvin = 288.15
    static let lapseRateKelvinPerMeter = 0.0065
    static let seaLevelPressureHectopascals = 1013.25

    static func hectopascals(fromKilopascals kilopascals: Double) -> Double? {
        guard kilopascals.isFinite else { return nil }
        return kilopascals * 10
    }

    /// Meters above the standard sea-level pressure. Negative means below that level.
    static func altitudeMeters(
        pressureHectopascals pressure: Double,
        seaLevelHectopascals seaLevel: Double = seaLevelPressureHectopascals
    ) -> Double? {
        guard pressure.isFinite, seaLevel.isFinite, pressure > 0, seaLevel > 0 else { return nil }
        let powered = pow(pressure / seaLevel, troposphereExponent)
        guard powered.isFinite else { return nil }
        let altitude = (seaLevelTemperatureKelvin / lapseRateKelvinPerMeter) * (1 - powered)
        guard altitude.isFinite else { return nil }
        return altitude
    }

    static func pressureHectopascals(
        atAltitudeMeters altitude: Double,
        seaLevelHectopascals seaLevel: Double = seaLevelPressureHectopascals
    ) -> Double? {
        guard altitude.isFinite, seaLevel.isFinite, seaLevel > 0 else { return nil }
        let scaled = lapseRateKelvinPerMeter * altitude / seaLevelTemperatureKelvin
        guard scaled < 1 else { return nil }
        let pressure = seaLevel * pow(1 - scaled, 1 / troposphereExponent)
        guard pressure.isFinite, pressure > 0 else { return nil }
        return pressure
    }

    static func relativeAltitudeMeters(
        pressureHectopascals pressure: Double,
        referenceHectopascals reference: Double
    ) -> Double? {
        guard let current = altitudeMeters(pressureHectopascals: pressure),
              let baseline = altitudeMeters(pressureHectopascals: reference) else { return nil }
        return current - baseline
    }

    private static var troposphereExponent: Double {
        (gasConstant * lapseRateKelvinPerMeter) / (gravity * molarMass)
    }
}

// MARK: - Speed

nonisolated enum SpeedUnit: String, CaseIterable, Equatable, Sendable {
    case metersPerSecond
    case kilometersPerHour
    case milesPerHour
}

nonisolated enum SpeedMath {
    /// Core Location reports a negative speed when the fix is not valid yet.
    static func isValid(metersPerSecond: Double) -> Bool {
        metersPerSecond.isFinite && metersPerSecond >= 0
    }

    static func convert(metersPerSecond: Double, to unit: SpeedUnit) -> Double? {
        guard isValid(metersPerSecond: metersPerSecond) else { return nil }
        switch unit {
        case .metersPerSecond:
            return metersPerSecond
        case .kilometersPerHour:
            return metersPerSecond * 3.6
        case .milesPerHour:
            return metersPerSecond * (3600 / 1609.344)
        }
    }
}

// MARK: - Light

nonisolated enum LuxMath {
    /// Maps a camera exposure to approximate lux.
    /// At ISO 100, EV = log2(N² / t) and lux ≈ 2.5 · 2^EV, which simplifies to
    /// 250 · N² / (t · ISO). A phone camera is not a calibrated illuminance meter.
    static let calibrationConstant = 250.0

    static func approximateLux(aperture: Double, exposureSeconds: Double, iso: Double) -> Double? {
        guard aperture.isFinite, exposureSeconds.isFinite, iso.isFinite,
              aperture > 0, exposureSeconds > 0, iso > 0 else { return nil }
        let lux = calibrationConstant * aperture * aperture / (exposureSeconds * iso)
        guard lux.isFinite, lux >= 0 else { return nil }
        return lux
    }
}

// MARK: - Magnetic field and vibration

nonisolated enum MagneticMath {
    /// A jump of this size, in microteslas, counts as a nearby piece of metal.
    static let spikeThresholdMicrotesla = 15.0

    static func magnitudeMicrotesla(x: Double, y: Double, z: Double) -> Double? {
        guard x.isFinite, y.isFinite, z.isFinite else { return nil }
        return (x * x + y * y + z * z).squareRoot()
    }

    static func isSpike(
        from previous: Double?,
        to current: Double,
        threshold: Double = spikeThresholdMicrotesla
    ) -> Bool {
        guard let previous, previous.isFinite, current.isFinite, threshold.isFinite, threshold > 0 else { return false }
        return abs(current - previous) >= threshold
    }
}

nonisolated enum AccelerationMath {
    static func magnitude(x: Double, y: Double, z: Double) -> Double? {
        guard x.isFinite, y.isFinite, z.isFinite else { return nil }
        return (x * x + y * y + z * z).squareRoot()
    }
}

// MARK: - AR distance and area

nonisolated struct WorldPoint: Equatable, Sendable {
    var x: Double
    var y: Double
    var z: Double

    var length: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    func distance(to other: WorldPoint) -> Double {
        (self - other).length
    }

    static func dot(_ lhs: WorldPoint, _ rhs: WorldPoint) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }

    static func - (lhs: WorldPoint, rhs: WorldPoint) -> WorldPoint {
        WorldPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    static func + (lhs: WorldPoint, rhs: WorldPoint) -> WorldPoint {
        WorldPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    static func * (lhs: WorldPoint, scale: Double) -> WorldPoint {
        WorldPoint(x: lhs.x * scale, y: lhs.y * scale, z: lhs.z * scale)
    }
}

nonisolated struct RectangleMeasure: Equatable, Sendable {
    var widthMeters: Double
    var heightMeters: Double
    var areaSquareMeters: Double
    /// Origin, far end of the width, opposite corner, far end of the height.
    var corners: [WorldPoint]
}

nonisolated enum MeasureDisplayUnit: String, CaseIterable, Equatable, Sendable {
    case centimeters
    case meters
    case inches
    case feet

    var metersFactor: Double {
        switch self {
        case .centimeters: return 100
        case .meters: return 1
        case .inches: return 1 / 0.0254
        case .feet: return 1 / 0.3048
        }
    }

    func length(fromMeters meters: Double) -> Double? {
        guard meters.isFinite else { return nil }
        return meters * metersFactor
    }

    func area(fromSquareMeters squareMeters: Double) -> Double? {
        guard squareMeters.isFinite else { return nil }
        return squareMeters * metersFactor * metersFactor
    }
}

nonisolated enum MeasureMath {
    static func distanceMeters(_ start: WorldPoint, _ end: WorldPoint) -> Double? {
        let distance = start.distance(to: end)
        guard distance.isFinite else { return nil }
        return distance
    }

    /// Rectangle spanned by the first edge and the component of the third point
    /// that is perpendicular to that edge. The area is width times that height.
    static func rectangle(origin: WorldPoint, alongWidth: WorldPoint, third: WorldPoint) -> RectangleMeasure? {
        let widthVector = alongWidth - origin
        let width = widthVector.length
        guard width.isFinite, width > 0.001 else { return nil }
        let toThird = third - origin
        let parallel = WorldPoint.dot(toThird, widthVector) / (width * width)
        guard parallel.isFinite else { return nil }
        let perpendicular = toThird - (widthVector * parallel)
        let height = perpendicular.length
        guard height.isFinite, height > 0.001 else { return nil }
        let area = width * height
        guard area.isFinite else { return nil }
        return RectangleMeasure(
            widthMeters: width,
            heightMeters: height,
            areaSquareMeters: area,
            corners: [origin, alongWidth, origin + widthVector + perpendicular, origin + perpendicular]
        )
    }
}
