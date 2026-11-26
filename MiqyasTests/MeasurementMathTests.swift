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

    // MARK: - Helpers

    private func qibla(latitude: Double, longitude: Double) -> Qibla {
        guard let value = QiblaMath.qibla(fromLatitude: latitude, longitude: longitude) else {
            XCTFail("Expected a Qibla result")
            return Qibla(bearingDegrees: .nan, distanceKilometers: .nan)
        }
        return value
    }
}
