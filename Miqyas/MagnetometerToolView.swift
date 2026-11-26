import SwiftUI
import CoreMotion
import Combine

// MARK: - Magnetometer

fileprivate enum MagnetAccess: Equatable {
    case needsPermission
    case denied
    case unavailable
    case ready
}

@MainActor
fileprivate final class MagnetometerModel: ObservableObject {
    @Published fileprivate var access: MagnetAccess = .needsPermission
    @Published fileprivate var microtesla: Double?
    @Published fileprivate var fieldX: Double?
    @Published fileprivate var fieldY: Double?
    @Published fileprivate var fieldZ: Double?
    @Published fileprivate var needsCalibration = false

    private let motion = CMMotionManager()
    private var wantsRunning = false
    private var isRunning = false

    func start() {
        wantsRunning = true
        guard motion.isMagnetometerAvailable else {
            access = .unavailable
            return
        }
        switch MotionAuthorization.current {
        case .denied:
            stopUpdates()
            access = .denied
            return
        case .needsPrompt:
            if microtesla == nil { access = .needsPermission }
        case .allowed:
            if microtesla == nil { access = .ready }
        }
        guard !isRunning else { return }
        isRunning = true
        motion.deviceMotionUpdateInterval = 1.0 / 20.0
        motion.magnetometerUpdateInterval = 1.0 / 20.0
        let model = self
        if motion.isDeviceMotionAvailable, let frame = magneticFrame() {
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
                let field = data.magneticField.field
                let accuracy = data.magneticField.accuracy
                Task { @MainActor in
                    model.apply(
                        x: field.x,
                        y: field.y,
                        z: field.z,
                        needsCalibration: accuracy == .uncalibrated || accuracy == .low
                    )
                }
            }
        } else {
            motion.startMagnetometerUpdates(to: .main) { data, error in
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
                let field = data.magneticField
                Task { @MainActor in
                    model.apply(x: field.x, y: field.y, z: field.z, needsCalibration: true)
                }
            }
        }
    }

    func stop() {
        wantsRunning = false
        stopUpdates()
    }

    private func fail(denied: Bool) {
        guard wantsRunning else { return }
        stopUpdates()
        access = denied ? .denied : .unavailable
    }

    private func stopUpdates() {
        isRunning = false
        motion.stopDeviceMotionUpdates()
        motion.stopMagnetometerUpdates()
    }

    private func magneticFrame() -> CMAttitudeReferenceFrame? {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        if available.contains(.xArbitraryCorrectedZVertical) { return .xArbitraryCorrectedZVertical }
        if available.contains(.xMagneticNorthZVertical) { return .xMagneticNorthZVertical }
        return nil
    }

    private func apply(x: Double, y: Double, z: Double, needsCalibration: Bool) {
        guard wantsRunning, let magnitude = MagneticMath.magnitudeMicrotesla(x: x, y: y, z: z) else { return }
        access = .ready
        microtesla = magnitude
        fieldX = x
        fieldY = y
        fieldZ = z
        self.needsCalibration = needsCalibration
    }
}

struct MagnetometerToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = MagnetometerModel()
    @State private var hapticsEnabled = true
    @State private var lastSpike = Date.distantPast

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
        .navigationTitle(settings.l10n.toolMagnetTitle)
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
        .onChange(of: model.microtesla) { previous, current in
            guard hapticsEnabled, settings.hapticFeedback, let current else { return }
            guard MagneticMath.isSpike(from: previous, to: current) else { return }
            guard Date().timeIntervalSince(lastSpike) > 0.4 else { return }
            lastSpike = Date()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.access {
        case .denied:
            SensorStatusCard(
                systemImage: "magnet",
                title: settings.l10n.toolMagnetTitle,
                message: settings.l10n.motionDeniedMessage,
                actionTitle: settings.l10n.openSettings,
                action: openSettings
            )
        case .unavailable:
            SensorStatusCard(
                systemImage: "magnet",
                title: settings.l10n.toolMagnetTitle,
                message: settings.l10n.magnetUnavailable
            )
        case .needsPermission:
            SensorStatusCard(
                systemImage: "magnet",
                title: settings.l10n.toolMagnetTitle,
                message: settings.l10n.motionPromptMessage
            )
            ProgressView()
        case .ready:
            meter
        }
    }

    private var meter: some View {
        VStack(spacing: 16) {
            ToolValueReadout(
                value: number(model.microtesla, digits: 1),
                unit: settings.l10n.magnetMicrotesla,
                caption: settings.l10n.approximateReading,
                tint: meterTint
            )
            fieldMeter
            HStack(spacing: 10) {
                ToolStatPill(title: "X", value: number(model.fieldX, digits: 1))
                ToolStatPill(title: "Y", value: number(model.fieldY, digits: 1))
                ToolStatPill(title: "Z", value: number(model.fieldZ, digits: 1))
            }
            Toggle(isOn: $hapticsEnabled) {
                Text(settings.l10n.magnetHaptics)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .tint(.pink)
            .padding(16)
            .toolGlass(cornerRadius: 20)
            if model.needsCalibration {
                ToolHintText(text: settings.l10n.magnetCalibrate)
            }
            ToolHintText(text: settings.l10n.magnetHint)
        }
    }

    private var fieldMeter: some View {
        let fraction = min(1, max(0, (model.microtesla ?? 0) / 120))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(meterTint)
                    .frame(width: max(10, geo.size.width * fraction))
            }
        }
        .frame(height: 18)
        .padding(16)
        .toolGlass(cornerRadius: 20)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    private var meterTint: Color {
        let value = model.microtesla ?? 0
        if value < 70 { return .green }
        if value < 100 { return .orange }
        return .pink
    }

    private func number(_ value: Double?, digits: Int) -> String {
        guard let value else { return "—" }
        return MeasurementFormat.fixed(value, fractionDigits: digits, locale: locale)
    }

    private func openSettings() {
        settings.triggerFeedback()
        openAppSettings()
    }
}
