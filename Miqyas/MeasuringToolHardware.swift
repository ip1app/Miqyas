import ARKit
import AVFoundation
import CoreLocation
import CoreMotion

/// Which measuring tools this device can run. Checks are capability flags only:
/// they do not start a sensor and they do not ask for permission.
enum MeasuringToolHardware {
    static func availableIDs() -> Set<String> {
        var available = Set(MeasuringTool.allCases.map(\.rawValue))
        let motion = CMMotionManager()
        if !motion.isDeviceMotionAvailable {
            available.remove(MeasuringTool.protractor.rawValue)
        }
        if !CMAltimeter.isRelativeAltitudeAvailable() {
            available.remove(MeasuringTool.barometer.rawValue)
        }
        if !CMPedometer.isStepCountingAvailable() {
            available.remove(MeasuringTool.pedometer.rawValue)
        }
        if !CLLocationManager.significantLocationChangeMonitoringAvailable() {
            available.remove(MeasuringTool.speedometer.rawValue)
        }
        if AVCaptureDevice.default(for: .video) == nil {
            available.remove(MeasuringTool.light.rawValue)
        }
        if !motion.isMagnetometerAvailable {
            available.remove(MeasuringTool.magnetometer.rawValue)
        }
        if !motion.isAccelerometerAvailable && !motion.isDeviceMotionAvailable {
            available.remove(MeasuringTool.seismometer.rawValue)
        }
        if !ARWorldTrackingConfiguration.isSupported {
            available.remove(MeasuringTool.ar.rawValue)
        }
        return available
    }
}
