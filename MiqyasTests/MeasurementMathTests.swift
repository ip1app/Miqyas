import Foundation
import XCTest
@testable import Miqyas

final class MeasurementMathTests: XCTestCase {

    // MARK: - Qibla

    func testQiblaFromKuwaitCity() {
        // Published city-centre figures for Kuwait City are about 224.6° and 1,204 km.
        let qibla = qibla(latitude: 29.3759, longitude: 47.9774)
        XCTAssertEqual(qibla.bearingDegrees, 224.6197, accuracy: 0.05)
        XCTAssertEqual(qibla.distanceKilometers, 1204.36, accuracy: 0.5)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: qibla.bearingDegrees), .southWest)
        XCTAssertFalse(QiblaMath.isAtKaaba(distanceKilometers: qibla.distanceKilometers))
    }

    func testQiblaFromCairo() {
        let qibla = qibla(latitude: 30.0444, longitude: 31.2357)
        XCTAssertEqual(qibla.bearingDegrees, 136.1373, accuracy: 0.05)
        XCTAssertEqual(qibla.distanceKilometers, 1287.22, accuracy: 0.5)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: qibla.bearingDegrees), .southEast)
    }

    func testQiblaFromJakartaIsNorthwest() {
        let qibla = qibla(latitude: -6.2088, longitude: 106.8456)
        XCTAssertEqual(qibla.bearingDegrees, 295.1517, accuracy: 0.05)
        XCTAssertEqual(qibla.distanceKilometers, 7920.13, accuracy: 0.5)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: qibla.bearingDegrees), .northWest)
    }

    func testQiblaFromNewYorkFollowsTheGreatCircle() {
        // A flat map sends New York southeast. The great-circle bearing leaves northeast.
        let qibla = qibla(latitude: 40.7128, longitude: -74.0060)
        XCTAssertEqual(qibla.bearingDegrees, 58.4817, accuracy: 0.05)
        XCTAssertEqual(qibla.distanceKilometers, 10306.31, accuracy: 0.5)
        XCTAssertGreaterThan(qibla.bearingDegrees, 45)
        XCTAssertLessThan(qibla.bearingDegrees, 90)
    }

    func testQiblaFromLondon() {
        let qibla = qibla(latitude: 51.5074, longitude: -0.1278)
        XCTAssertEqual(qibla.bearingDegrees, 118.9872, accuracy: 0.05)
        XCTAssertEqual(qibla.distanceKilometers, 4793.78, accuracy: 0.5)
    }

    func testDistanceIsSymmetricAndKaabaIsZero() {
        let forward = QiblaMath.distanceKilometers(
            fromLatitude: 29.3759,
            fromLongitude: 47.9774,
            toLatitude: QiblaMath.kaabaLatitude,
            toLongitude: QiblaMath.kaabaLongitude
        )
        let backward = QiblaMath.distanceKilometers(
            fromLatitude: QiblaMath.kaabaLatitude,
            fromLongitude: QiblaMath.kaabaLongitude,
            toLatitude: 29.3759,
            toLongitude: 47.9774
        )
        XCTAssertEqual(forward, backward, accuracy: 0.001)

        let here = qibla(latitude: QiblaMath.kaabaLatitude, longitude: QiblaMath.kaabaLongitude)
        XCTAssertEqual(here.distanceKilometers, 0, accuracy: 0.001)
        XCTAssertEqual(here.bearingDegrees, 0, accuracy: 0.001)
        XCTAssertTrue(QiblaMath.isAtKaaba(distanceKilometers: here.distanceKilometers))
        XCTAssertFalse(QiblaMath.isAtKaaba(distanceKilometers: 0.05))
    }

    func testQiblaRejectsInvalidCoordinates() {
        XCTAssertNil(QiblaMath.qibla(fromLatitude: 91, longitude: 0))
        XCTAssertNil(QiblaMath.qibla(fromLatitude: 0, longitude: 181))
        XCTAssertNil(QiblaMath.qibla(fromLatitude: .nan, longitude: 39))
        XCTAssertNil(QiblaMath.qibla(fromLatitude: 21, longitude: .infinity))
    }

    // MARK: - Compass heading

    func testPositiveDegreesAndSignedTurn() {
        XCTAssertEqual(CompassMath.positiveDegrees(0), 0, accuracy: 0.001)
        XCTAssertEqual(CompassMath.positiveDegrees(360), 0, accuracy: 0.001)
        XCTAssertEqual(CompassMath.positiveDegrees(-90), 270, accuracy: 0.001)
        XCTAssertEqual(CompassMath.positiveDegrees(720.5), 0.5, accuracy: 0.001)
        XCTAssertEqual(CompassMath.positiveDegrees(-360), 0, accuracy: 0.001)

        XCTAssertEqual(CompassMath.signedDelta(from: 10, to: 350), -20, accuracy: 0.001)
        XCTAssertEqual(CompassMath.signedDelta(from: 350, to: 10), 20, accuracy: 0.001)
        XCTAssertEqual(CompassMath.signedDelta(from: 0, to: 180), 180, accuracy: 0.001)
        XCTAssertEqual(CompassMath.signedDelta(from: 224.6, to: 224.6), 0, accuracy: 0.001)
    }

    func testCardinalSectors() {
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 0), .north)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 22.4), .north)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 22.5), .northEast)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 45), .northEast)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 180), .south)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 224.6), .southWest)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 337.4), .northWest)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 337.5), .north)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: 359), .north)
        XCTAssertEqual(CompassMath.cardinal(forDegrees: -10), .north)
    }

    func testHeadingResolutionAndCalibrationHint() {
        let trueNorth = CompassMath.resolvedHeading(trueHeading: 10, magneticHeading: 20, accuracy: 5)
        XCTAssertEqual(trueNorth?.degrees, 10, accuracy: 0.001)
        XCTAssertEqual(trueNorth?.isTrueNorth, true)

        let magnetic = CompassMath.resolvedHeading(trueHeading: -1, magneticHeading: 20, accuracy: 5)
        XCTAssertEqual(magnetic?.degrees, 20, accuracy: 0.001)
        XCTAssertEqual(magnetic?.isTrueNorth, false)

        XCTAssertNil(CompassMath.resolvedHeading(trueHeading: 10, magneticHeading: 10, accuracy: -1))
        XCTAssertNil(CompassMath.resolvedHeading(trueHeading: -1, magneticHeading: -1, accuracy: 5))

        let wrapped = CompassMath.resolvedHeading(trueHeading: 370, magneticHeading: 0, accuracy: 4)
        XCTAssertEqual(wrapped?.degrees, 10, accuracy: 0.001)

        XCTAssertFalse(CompassMath.needsCalibration(headingAccuracy: 0))
        XCTAssertFalse(CompassMath.needsCalibration(headingAccuracy: 25))
        XCTAssertTrue(CompassMath.needsCalibration(headingAccuracy: 25.1))
        XCTAssertTrue(CompassMath.needsCalibration(headingAccuracy: -1))
    }

    // MARK: - Level

    func testFlatOrientationsAreLevel() {
        let faceUp = LevelMath.reading(gravity: GravityVector(x: 0, y: 0, z: -1))
        XCTAssertEqual(faceUp.tiltDegrees, 0, accuracy: 0.001)
        XCTAssertEqual(faceUp.edgeAngleDegrees, 0, accuracy: 0.001)
        XCTAssertEqual(faceUp.bubbleX, 0, accuracy: 0.001)
        XCTAssertEqual(faceUp.bubbleY, 0, accuracy: 0.001)
        XCTAssertTrue(faceUp.isSurfaceLevel)
        XCTAssertTrue(faceUp.isEdgeLevel)

        let faceDown = LevelMath.reading(gravity: GravityVector(x: 0, y: 0, z: 1))
        XCTAssertEqual(faceDown.tiltDegrees, 0, accuracy: 0.001)
        XCTAssertTrue(faceDown.isSurfaceLevel)
    }

    func testSurfaceTiltMovesTheBubbleUphill() {
        let thirty = 30.0 * .pi / 180
        let topDown = LevelMath.reading(
            gravity: GravityVector(x: 0, y: sin(thirty), z: -cos(thirty))
        )
        XCTAssertEqual(topDown.tiltDegrees, 30, accuracy: 0.02)
        XCTAssertEqual(topDown.edgeAngleDegrees, -30, accuracy: 0.02)
        XCTAssertEqual(topDown.bubbleX, 0, accuracy: 0.001)
        XCTAssertEqual(topDown.bubbleY, -1, accuracy: 0.001)
        XCTAssertFalse(topDown.isSurfaceLevel)

        let three = 3.0 * .pi / 180
        let slight = LevelMath.reading(
            gravity: GravityVector(x: 0, y: sin(three), z: -cos(three))
        )
        XCTAssertEqual(slight.tiltDegrees, 3, accuracy: 0.02)
        XCTAssertEqual(slight.bubbleY, -0.2517, accuracy: 0.002)
        XCTAssertFalse(slight.isSurfaceLevel)

        let fortyFive = 45.0 * .pi / 180
        let rightDown = LevelMath.reading(
            gravity: GravityVector(x: sin(fortyFive), y: 0, z: -cos(fortyFive))
        )
        XCTAssertEqual(rightDown.tiltDegrees, 45, accuracy: 0.02)
        XCTAssertEqual(rightDown.edgeAngleDegrees, 0, accuracy: 0.02)
        XCTAssertLessThan(rightDown.bubbleX, 0)
        XCTAssertEqual(rightDown.bubbleX, -1, accuracy: 0.001)
    }

    func testEdgeAngleOnTheSideAndUpright() {
        let upright = LevelMath.reading(gravity: GravityVector(x: 0, y: -1, z: 0))
        XCTAssertEqual(upright.edgeAngleDegrees, 90, accuracy: 0.02)
        XCTAssertEqual(upright.tiltDegrees, 90, accuracy: 0.02)
        XCTAssertFalse(upright.isEdgeLevel)

        let sideLevel = LevelMath.reading(gravity: GravityVector(x: 1, y: 0, z: 0))
        XCTAssertEqual(sideLevel.edgeAngleDegrees, 0, accuracy: 0.02)
        XCTAssertTrue(sideLevel.isEdgeLevel)
        XCTAssertFalse(sideLevel.isSurfaceLevel)

        let thirty = 30.0 * .pi / 180
        let sideRaised = LevelMath.reading(
            gravity: GravityVector(x: cos(thirty), y: -sin(thirty), z: 0)
        )
        XCTAssertEqual(sideRaised.edgeAngleDegrees, 30, accuracy: 0.02)
        XCTAssertFalse(sideRaised.isEdgeLevel)
    }

    func testZeroCalibration() {
        let thirty = 30.0 * .pi / 180
        let tilted = GravityVector(x: 0, y: sin(thirty), z: -cos(thirty))

        let zeroed = LevelMath.reading(gravity: tilted, reference: tilted)
        XCTAssertEqual(zeroed.tiltDegrees, 0, accuracy: 0.05)
        XCTAssertEqual(zeroed.edgeAngleDegrees, 0, accuracy: 0.05)
        XCTAssertTrue(zeroed.isSurfaceLevel)

        let backToFlat = LevelMath.reading(
            gravity: GravityVector(x: 0, y: 0, z: -1),
            reference: tilted
        )
        XCTAssertEqual(backToFlat.tiltDegrees, 30, accuracy: 0.05)
        XCTAssertEqual(backToFlat.edgeAngleDegrees, 30, accuracy: 0.05)

        let unchanged = LevelMath.reading(
            gravity: tilted,
            reference: LevelMath.screenUpGravity
        )
        XCTAssertEqual(unchanged.tiltDegrees, 30, accuracy: 0.05)

        let faceDown = GravityVector(x: 0, y: 0, z: 1)
        let flipped = LevelMath.calibratedGravity(current: faceDown, reference: faceDown)
        XCTAssertEqual(flipped.x, 0, accuracy: 0.001)
        XCTAssertEqual(flipped.y, 0, accuracy: 0.001)
        XCTAssertEqual(flipped.z, -1, accuracy: 0.001)
    }

    func testLevelHysteresis() {
        XCTAssertTrue(LevelMath.latchedLevel(angleDegrees: 0.5, wasLevel: false))
        XCTAssertFalse(LevelMath.latchedLevel(angleDegrees: 0.7, wasLevel: false))
        XCTAssertTrue(LevelMath.latchedLevel(angleDegrees: 1.0, wasLevel: true))
        XCTAssertFalse(LevelMath.latchedLevel(angleDegrees: 1.3, wasLevel: true))
        XCTAssertTrue(LevelMath.latchedLevel(angleDegrees: -0.4, wasLevel: false))
        XCTAssertFalse(LevelMath.latchedLevel(angleDegrees: -1.3, wasLevel: true))
    }

    func testScreenOffsetFollowsInterfaceOrientation() {
        let right = LevelMath.screenOffset(deviceX: 1, deviceY: 0, orientation: .portrait)
        XCTAssertEqual(right, ScreenOffset(x: 1, y: 0))
        let top = LevelMath.screenOffset(deviceX: 0, deviceY: 1, orientation: .portrait)
        XCTAssertEqual(top, ScreenOffset(x: 0, y: -1))

        let upsideRight = LevelMath.screenOffset(deviceX: 1, deviceY: 0, orientation: .portraitUpsideDown)
        XCTAssertEqual(upsideRight, ScreenOffset(x: -1, y: 0))

        let topLeftDeviceTop = LevelMath.screenOffset(deviceX: 0, deviceY: 1, orientation: .landscapeDeviceTopLeft)
        XCTAssertEqual(topLeftDeviceTop, ScreenOffset(x: -1, y: 0))
        let topLeftDeviceRight = LevelMath.screenOffset(deviceX: 1, deviceY: 0, orientation: .landscapeDeviceTopLeft)
        XCTAssertEqual(topLeftDeviceRight, ScreenOffset(x: 0, y: -1))

        let topRightDeviceTop = LevelMath.screenOffset(deviceX: 0, deviceY: 1, orientation: .landscapeDeviceTopRight)
        XCTAssertEqual(topRightDeviceTop, ScreenOffset(x: 1, y: 0))
        let topRightDeviceRight = LevelMath.screenOffset(deviceX: 1, deviceY: 0, orientation: .landscapeDeviceTopRight)
        XCTAssertEqual(topRightDeviceRight, ScreenOffset(x: 0, y: 1))
    }

    func testZeroGravityDoesNotProduceNaN() {
        let reading = LevelMath.reading(gravity: GravityVector(x: 0, y: 0, z: 0))
        XCTAssertEqual(reading, .flat)
        XCTAssertEqual(LevelMath.edgeAngleDegrees(x: 0, y: 0, z: 0), 0, accuracy: 0.001)
    }

    // MARK: - Sound level

    func testDecibelConversion() {
        XCTAssertEqual(SoundLevelMath.rootMeanSquare([Float]()), 0, accuracy: 0.0001)
        XCTAssertEqual(SoundLevelMath.decibelsFullScale(rms: 0), SoundLevelMath.silenceFloorDBFS, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.decibelsFullScale(rms: 1), 0, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.decibelsFullScale(rms: 0.1), -20, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.decibelsFullScale(rms: 0.5), -6.0206, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.decibelsFullScale(rms: 2), 0, accuracy: 0.001)

        let alternating: [Float] = [0.5, -0.5, 0.5, -0.5]
        XCTAssertEqual(SoundLevelMath.rootMeanSquare(alternating), 0.5, accuracy: 0.0001)

        let quiet = SoundLevelMath.approximateDecibels(dbfs: -20)
        XCTAssertEqual(quiet, 80, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.approximateDecibels(dbfs: 0), 100, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.approximateDecibels(dbfs: 5), 100, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.approximateDecibels(dbfs: -200), -60, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.approximateDecibels(dbfs: .nan), -60, accuracy: 0.001)
    }

    func testInt16RootMeanSquare() {
        let samples: [Int16] = [16384, -16384]
        XCTAssertEqual(SoundLevelMath.rootMeanSquare(int16: samples), 0.5, accuracy: 0.001)
        XCTAssertEqual(SoundLevelMath.rootMeanSquare(int16: [Int16]()), 0, accuracy: 0.0001)
    }

    func testSoundAggregateMinAverageMax() {
        var stats = SoundAggregate(sample: 50)
        stats.add(60)
        XCTAssertEqual(stats.minimum, 50, accuracy: 0.001)
        XCTAssertEqual(stats.maximum, 60, accuracy: 0.001)
        XCTAssertEqual(stats.sampleCount, 2)
        XCTAssertEqual(stats.energyAverage, 57.4036, accuracy: 0.02)

        stats.add(70)
        XCTAssertEqual(stats.minimum, 50, accuracy: 0.001)
        XCTAssertEqual(stats.maximum, 70, accuracy: 0.001)
        XCTAssertEqual(stats.energyAverage, 65.682, accuracy: 0.02)

        var flat = SoundAggregate(sample: 60)
        flat.add(60)
        XCTAssertEqual(flat.energyAverage, 60, accuracy: 0.001)
        XCTAssertEqual(flat.minimum, 60, accuracy: 0.001)
        XCTAssertEqual(flat.maximum, 60, accuracy: 0.001)
    }

    // MARK: - Screen ruler

    func testKnownPanelsUseTheirRealPixelDensity() {
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone15,2", screenScale: 3), 460)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone14,6", screenScale: 2), 326)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone14,4", screenScale: 3), 476)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone10,2", screenScale: 3), 401)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone10,3", screenScale: 3), 458)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPad14,1", screenScale: 2), 326)
    }

    func testUnknownModelsFallBackFromTheScreenScale() {
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone99,1", screenScale: 3), 460)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone99,1", screenScale: 2), 326)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPhone99,1", screenScale: 1), 163)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "iPad99,1", screenScale: 2), 264)
        XCTAssertEqual(ScreenRulerMath.pixelsPerInch(modelIdentifier: "arm64", screenScale: 3), 460)
    }

    func testPointsMatchPhysicalInchesAndCentimeters() {
        let pointsPerInch = ScreenRulerMath.pointsPerInch(pixelsPerInch: 460, screenScale: 3)
        XCTAssertEqual(pointsPerInch ?? 0, 460.0 / 3.0, accuracy: 0.0001)
        let points = pointsPerInch ?? 0
        XCTAssertEqual(ScreenRulerMath.inches(points: points, pointsPerInch: points) ?? 0, 1, accuracy: 0.0001)
        XCTAssertEqual(ScreenRulerMath.centimeters(points: points, pointsPerInch: points) ?? 0, 2.54, accuracy: 0.0001)
        XCTAssertEqual(ScreenRulerMath.points(inches: 1, pointsPerInch: points) ?? 0, points, accuracy: 0.0001)
        XCTAssertEqual(ScreenRulerMath.points(centimeters: 2.54, pointsPerInch: points) ?? 0, points, accuracy: 0.0001)
        XCTAssertNil(ScreenRulerMath.pointsPerInch(pixelsPerInch: 460, screenScale: 0))
        XCTAssertNil(ScreenRulerMath.inches(points: 10, pointsPerInch: 0))
        XCTAssertNil(ScreenRulerMath.centimeters(points: .nan, pointsPerInch: points))
    }

    // MARK: - Protractor

    func testTiltAndAngleBetweenOrientations() {
        let flat = GravityVector(x: 0, y: 0, z: -1)
        let edge = GravityVector(x: 0, y: -1, z: 0)
        XCTAssertEqual(AngleMath.tiltFromFlatDegrees(gravity: flat) ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(AngleMath.tiltFromFlatDegrees(gravity: edge) ?? -1, 90, accuracy: 0.001)
        XCTAssertEqual(AngleMath.angleDegrees(between: flat, and: edge) ?? -1, 90, accuracy: 0.001)
        XCTAssertEqual(AngleMath.angleDegrees(between: flat, and: flat) ?? -1, 0, accuracy: 0.001)
        XCTAssertNil(AngleMath.tiltFromFlatDegrees(gravity: GravityVector(x: 0, y: 0, z: 0)))

        let identity = UnitQuaternion.identity
        XCTAssertEqual(identity.rotationDegrees ?? -1, 0, accuracy: 0.001)
        let half = (2.0).squareRoot() / 2
        let quarterTurn = UnitQuaternion(x: 0, y: 0, z: half, w: half)
        XCTAssertEqual(identity.angleDegrees(to: quarterTurn) ?? -1, 90, accuracy: 0.001)
        XCTAssertEqual(quarterTurn.angleDegrees(to: identity) ?? -1, 90, accuracy: 0.001)
        let sameRotation = UnitQuaternion(x: 0, y: 0, z: -half, w: -half)
        XCTAssertEqual(quarterTurn.angleDegrees(to: sameRotation) ?? -1, 0, accuracy: 0.001)
        XCTAssertNil(UnitQuaternion(x: 0, y: 0, z: 0, w: 0).rotationDegrees)
    }

    // MARK: - Barometer

    func testStandardPressureIsSeaLevel() {
        let altitude = BarometricMath.altitudeMeters(pressureHectopascals: BarometricMath.seaLevelPressureHectopascals)
        XCTAssertEqual(altitude ?? -1, 0, accuracy: 0.0001)
    }

    func testBarometricAltitudeRoundTripsAndKnownPressures() {
        let pressure = BarometricMath.pressureHectopascals(atAltitudeMeters: 1000)
        XCTAssertEqual(pressure ?? 0, 898.7476, accuracy: 0.001)
        XCTAssertEqual(BarometricMath.altitudeMeters(pressureHectopascals: pressure ?? 0) ?? 0, 1000, accuracy: 0.001)
        XCTAssertEqual(BarometricMath.altitudeMeters(pressureHectopascals: 900) ?? 0, 988.518, accuracy: 0.01)
        XCTAssertEqual(
            BarometricMath.relativeAltitudeMeters(pressureHectopascals: 1000, referenceHectopascals: 1013.25) ?? 0,
            110.886,
            accuracy: 0.01
        )
    }

    func testBarometerRejectsInvalidPressure() {
        XCTAssertNil(BarometricMath.altitudeMeters(pressureHectopascals: 0))
        XCTAssertNil(BarometricMath.altitudeMeters(pressureHectopascals: -5))
        XCTAssertNil(BarometricMath.altitudeMeters(pressureHectopascals: .nan))
        XCTAssertNil(BarometricMath.pressureHectopascals(atAltitudeMeters: 50_000))
        XCTAssertNil(BarometricMath.hectopascals(fromKilopascals: .infinity))
        XCTAssertEqual(BarometricMath.hectopascals(fromKilopascals: 101.325) ?? 0, 1013.25, accuracy: 0.0001)
    }

    // MARK: - Speed

    func testSpeedConversionAndInvalidFixes() {
        XCTAssertEqual(SpeedMath.convert(metersPerSecond: 10, to: .kilometersPerHour) ?? 0, 36, accuracy: 0.0001)
        XCTAssertEqual(
            SpeedMath.convert(metersPerSecond: 10, to: .milesPerHour) ?? 0,
            10 * 3600 / 1609.344,
            accuracy: 0.0000001
        )
        XCTAssertEqual(SpeedMath.convert(metersPerSecond: 10, to: .metersPerSecond) ?? 0, 10, accuracy: 0.0001)
        XCTAssertEqual(SpeedMath.convert(metersPerSecond: 0, to: .kilometersPerHour) ?? -1, 0, accuracy: 0.0001)
        XCTAssertNil(SpeedMath.convert(metersPerSecond: -1, to: .kilometersPerHour))
        XCTAssertFalse(SpeedMath.isValid(metersPerSecond: .nan))
        XCTAssertTrue(SpeedMath.isValid(metersPerSecond: 0))
    }

    // MARK: - Lux

    func testLuxEstimateFromExposure() {
        XCTAssertEqual(LuxMath.approximateLux(aperture: 2, exposureSeconds: 0.01, iso: 100) ?? 0, 1000, accuracy: 0.001)
        XCTAssertEqual(LuxMath.approximateLux(aperture: 4, exposureSeconds: 1.0 / 60, iso: 200) ?? 0, 1200, accuracy: 0.001)
        XCTAssertNil(LuxMath.approximateLux(aperture: 0, exposureSeconds: 0.01, iso: 100))
        XCTAssertNil(LuxMath.approximateLux(aperture: 2, exposureSeconds: 0, iso: 100))
        XCTAssertNil(LuxMath.approximateLux(aperture: 2, exposureSeconds: 0.01, iso: -10))
        XCTAssertNil(LuxMath.approximateLux(aperture: .infinity, exposureSeconds: 0.01, iso: 100))
    }

    func testMagneticSpikeAndAccelerationMagnitude() {
        XCTAssertEqual(MagneticMath.magnitudeMicrotesla(x: 3, y: 4, z: 0) ?? 0, 5, accuracy: 0.0001)
        XCTAssertTrue(MagneticMath.isSpike(from: 40, to: 56))
        XCTAssertFalse(MagneticMath.isSpike(from: 40, to: 50))
        XCTAssertFalse(MagneticMath.isSpike(from: nil, to: 80))
        XCTAssertNil(MagneticMath.magnitudeMicrotesla(x: .nan, y: 0, z: 0))
        XCTAssertEqual(AccelerationMath.magnitude(x: 0, y: 3, z: 4) ?? 0, 5, accuracy: 0.0001)
    }

    // MARK: - AR measure

    func testARDistanceAndRectangleArea() {
        let origin = WorldPoint(x: 0, y: 0, z: 0)
        XCTAssertEqual(MeasureMath.distanceMeters(origin, WorldPoint(x: 3, y: 4, z: 0)) ?? 0, 5, accuracy: 0.0001)

        let rectangle = MeasureMath.rectangle(
            origin: origin,
            alongWidth: WorldPoint(x: 2, y: 0, z: 0),
            third: WorldPoint(x: 0, y: 3, z: 0)
        )
        XCTAssertEqual(rectangle?.widthMeters ?? 0, 2, accuracy: 0.0001)
        XCTAssertEqual(rectangle?.heightMeters ?? 0, 3, accuracy: 0.0001)
        XCTAssertEqual(rectangle?.areaSquareMeters ?? 0, 6, accuracy: 0.0001)
        XCTAssertEqual(rectangle?.corners.count, 4)

        let skewed = MeasureMath.rectangle(
            origin: origin,
            alongWidth: WorldPoint(x: 4, y: 0, z: 0),
            third: WorldPoint(x: 1, y: 3, z: 0)
        )
        XCTAssertEqual(skewed?.widthMeters ?? 0, 4, accuracy: 0.0001)
        XCTAssertEqual(skewed?.heightMeters ?? 0, 3, accuracy: 0.0001)
        XCTAssertEqual(skewed?.areaSquareMeters ?? 0, 12, accuracy: 0.0001)
        XCTAssertNil(MeasureMath.rectangle(origin: origin, alongWidth: origin, third: WorldPoint(x: 0, y: 1, z: 0)))
        XCTAssertNil(MeasureMath.distanceMeters(origin, WorldPoint(x: .nan, y: 0, z: 0)))
    }

    func testARUnitConversions() {
        XCTAssertEqual(MeasureDisplayUnit.centimeters.length(fromMeters: 1.5) ?? 0, 150, accuracy: 0.0001)
        XCTAssertEqual(MeasureDisplayUnit.meters.length(fromMeters: 1.5) ?? 0, 1.5, accuracy: 0.0001)
        XCTAssertEqual(MeasureDisplayUnit.inches.length(fromMeters: 0.0254) ?? 0, 1, accuracy: 0.0001)
        XCTAssertEqual(MeasureDisplayUnit.feet.length(fromMeters: 0.3048) ?? 0, 1, accuracy: 0.0001)
        XCTAssertEqual(MeasureDisplayUnit.centimeters.area(fromSquareMeters: 1) ?? 0, 10_000, accuracy: 0.0001)
        XCTAssertEqual(MeasureDisplayUnit.meters.area(fromSquareMeters: 2) ?? 0, 2, accuracy: 0.0001)
        XCTAssertEqual(MeasureDisplayUnit.feet.area(fromSquareMeters: 0.3048 * 0.3048) ?? 0, 1, accuracy: 0.0001)
        XCTAssertNil(MeasureDisplayUnit.meters.length(fromMeters: .nan))
    }

    // MARK: - Helpers

    private func qibla(latitude: Double, longitude: Double) -> Qibla {
        guard let value = QiblaMath.qibla(fromLatitude: latitude, longitude: longitude) else {
            XCTFail("Expected a Qibla result")
            return Qibla(bearingDegrees: .nan, distanceKilometers: .nan)
        }
        return value
    }
}
