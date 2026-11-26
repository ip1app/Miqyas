import AVFoundation
import CoreMotion

/// Motion & Fitness permission shared by the pedometer, barometer, and Core Motion tools.
/// Reading the status does not prompt; starting a sensor does.
enum MotionAuthorization: Equatable {
    case needsPrompt
    case denied
    case allowed

    static var current: MotionAuthorization {
        switch CMAltimeter.authorizationStatus() {
        case .notDetermined:
            return .needsPrompt
        case .restricted, .denied:
            return .denied
        case .authorized:
            return .allowed
        @unknown default:
            return .denied
        }
    }
}

enum MotionFailure {
    /// CMErrorMotionActivityNotAuthorized and CMErrorNotAuthorized.
    static func isAuthorizationDenied(_ error: Error?) -> Bool {
        guard let error else { return false }
        let code = (error as NSError).code
        return code == 105 || code == 111
    }
}

enum CameraAuthorization: Equatable {
    case needsPrompt
    case denied
    case allowed

    static var current: CameraAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .needsPrompt
        case .restricted, .denied:
            return .denied
        case .authorized:
            return .allowed
        @unknown default:
            return .denied
        }
    }
}
