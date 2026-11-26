import SwiftUI
import CoreMotion
import Combine

// MARK: - Protractor

fileprivate enum ProtractorAccess: Equatable {
    case needsPermission
    case denied
    case unavailable
    case ready
}

@MainActor
fileprivate final class ProtractorModel: ObservableObject {
    @Published fileprivate var access: ProtractorAccess = .needsPermission
    @Published fileprivate var tiltDegrees: Double?
    @Published fileprivate var angleDegrees: Double?
    @Published fileprivate var hasReference = false

    private let motion = CMMotionManager()
    private var wantsRunning = false
    private var isRunning = false
    private var smoothedTilt: Double?
    private var latest: UnitQuaternion?
    private var reference: UnitQuaternion?

    func start() {
        wantsRunning = true
        guard motion.isDeviceMotionAvailable else {
            access = .unavailable
            return
        }
        switch MotionAuthorization.current {
        case .denied:
            stopUpdates()
            access = .denied
            return
        case .needsPrompt:
            if tiltDegrees == nil { access = .needsPermission }
        case .allowed:
            if tiltDegrees == nil { access = .ready }
        }
        guard !isRunning else { return }
        guard let frame = preferredReferenceFrame() else {
            access = .unavailable
            return
        }
        isRunning = true
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        let model = self
        motion.startDeviceMotionUpdates(using: frame, to: .main) { data, error in
            if let error {
                let denied = MotionFailure.isAuthorizationDenied(error)
                Task { @MainActor in
                    if denied {
                        model.fail(denied: true)
                    }
                }
                return
            }
            guard let data else { return }
            let gravity = GravityVector(x: data.gravity.x, y: data.gravity.y, z: data.gravity.z)
            let quaternion = data.attitude.quaternion
            let attitude = UnitQuaternion(x: quaternion.x, y: quaternion.y, z: quaternion.z, w: quaternion.w)
            Task { @MainActor in
                model.consume(gravity: gravity, attitude: attitude)
            }
        }
    }

    func stop() {
        wantsRunning = false
        stopUpdates()
    }

    func capture() {
        guard let latest else { return }
        reference = latest
        hasReference = true
        angleDegrees = 0
    }

    func clearReference() {
        reference = nil
        hasReference = false
        angleDegrees = nil
    }

    private func fail(denied: Bool) {
        guard wantsRunning else { return }
        stopUpdates()
        access = denied ? .denied : .unavailable
    }

    private func stopUpdates() {
        isRunning = false
        motion.stopDeviceMotionUpdates()
    }

    private func preferredReferenceFrame() -> CMAttitudeReferenceFrame? {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        if available.contains(.xArbitraryZVertical) { return .xArbitraryZVertical }
        if available.contains(.xArbitraryCorrectedZVertical) { return .xArbitraryCorrectedZVertical }
        if available.contains(.xMagneticNorthZVertical) { return .xMagneticNorthZVertical }
        return nil
    }

    private func consume(gravity: GravityVector, attitude: UnitQuaternion) {
        guard wantsRunning else { return }
        access = .ready
        latest = attitude
        guard let tilt = AngleMath.tiltFromFlatDegrees(gravity: gravity) else { return }
        let filtered: Double
        if let smoothedTilt {
            filtered = smoothedTilt * 0.7 + tilt * 0.3
        } else {
            filtered = tilt
        }
        smoothedTilt = filtered
        tiltDegrees = filtered
        if let reference {
            angleDegrees = reference.angleDegrees(to: attitude)
        }
    }
}

struct ProtractorToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = ProtractorModel()

    private var locale: Locale { Locale(identifier: settings.appLanguage.rawValue) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                content
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(NeonAmbientBackground())
        .navigationTitle(settings.l10n.toolProtractorTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.start()
            } else {
                model.stop()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.access {
        case .denied:
            SensorStatusCard(
                systemImage: "angle",
                title: settings.l10n.toolProtractorTitle,
                message: settings.l10n.motionDeniedMessage,
                actionTitle: settings.l10n.openSettings,
                action: openSettings
            )
        case .unavailable:
            SensorStatusCard(
                systemImage: "angle",
                title: settings.l10n.toolProtractorTitle,
                message: settings.l10n.motionUnavailableMessage
            )
        case .needsPermission:
            SensorStatusCard(
                systemImage: "angle",
                title: settings.l10n.toolProtractorTitle,
                message: settings.l10n.motionPromptMessage
            )
            ProgressView()
        case .ready:
            readout
        }
    }

    private var readout: some View {
        VStack(spacing: 18) {
            ToolValueReadout(
                value: degreeText(model.tiltDegrees),
                unit: "°",
                caption: settings.l10n.protractorFromFlat
            )
            tiltMeter
            VStack(spacing: 8) {
                Text(settings.l10n.protractorBetween)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(model.hasReference ? degreeText(model.angleDegrees) + "°" : settings.l10n.protractorNoStart)
                    .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .toolGlass(cornerRadius: 20)
            HStack(spacing: 10) {
                ToolActionButton(title: settings.l10n.protractorCapture, systemImage: "scope") {
                    settings.triggerFeedback()
                    model.capture()
                }
                if model.hasReference {
                    ToolActionButton(
                        title: settings.l10n.protractorClear,
                        systemImage: "arrow.counterclockwise",
                        prominent: false
                    ) {
                        settings.triggerFeedback()
                        model.clearReference()
                    }
                }
            }
            ToolHintText(text: settings.l10n.protractorHint)
        }
    }

    private var tiltMeter: some View {
        let fraction = min(1, max(0, (model.tiltDegrees ?? 0) / 90))
        return VStack(alignment: .leading, spacing: 8) {
            Text(settings.l10n.protractorTilt)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: accentGradientColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * fraction))
                }
            }
            .frame(height: 14)
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(16)
        .toolGlass(cornerRadius: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.l10n.protractorTilt)
        .accessibilityValue(degreeText(model.tiltDegrees))
    }

    private func degreeText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return MeasurementFormat.fixed(value, fractionDigits: 1, locale: locale)
    }

    private func openSettings() {
        settings.triggerFeedback()
        openAppSettings()
    }
}
