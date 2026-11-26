import SwiftUI
import CoreMotion
import Combine

// MARK: - Seismometer

fileprivate enum SeismoAccess: Equatable {
    case needsPermission
    case denied
    case unavailable
    case ready
}

@MainActor
fileprivate final class SeismometerModel: ObservableObject {
    @Published fileprivate var access: SeismoAccess = .needsPermission
    @Published fileprivate var magnitude: Double = 0
    @Published fileprivate var peak: Double = 0
    @Published fileprivate var samples: [Double] = []

    private let motion = CMMotionManager()
    private var wantsRunning = false
    private var isRunning = false
    private let capacity = 160

    func start() {
        wantsRunning = true
        guard motion.isDeviceMotionAvailable || motion.isAccelerometerAvailable else {
            access = .unavailable
            return
        }
        switch MotionAuthorization.current {
        case .denied:
            stopUpdates()
            access = .denied
            return
        case .needsPrompt:
            if samples.isEmpty { access = .needsPermission }
        case .allowed:
            if samples.isEmpty { access = .ready }
        }
        guard !isRunning else { return }
        isRunning = true
        let model = self
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 30.0
            motion.startDeviceMotionUpdates(to: .main) { data, error in
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
                let acceleration = data.userAcceleration
                Task { @MainActor in
                    model.append(x: acceleration.x, y: acceleration.y, z: acceleration.z, removeGravity: false)
                }
            }
        } else {
            motion.accelerometerUpdateInterval = 1.0 / 30.0
            motion.startAccelerometerUpdates(to: .main) { data, error in
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
                let acceleration = data.acceleration
                Task { @MainActor in
                    model.append(x: acceleration.x, y: acceleration.y, z: acceleration.z, removeGravity: true)
                }
            }
        }
    }

    func stop() {
        wantsRunning = false
        stopUpdates()
    }

    func resetPeak() {
        peak = magnitude
    }

    private func fail(denied: Bool) {
        guard wantsRunning else { return }
        stopUpdates()
        access = denied ? .denied : .unavailable
    }

    private func stopUpdates() {
        isRunning = false
        motion.stopDeviceMotionUpdates()
        motion.stopAccelerometerUpdates()
    }

    private func append(x: Double, y: Double, z: Double, removeGravity: Bool) {
        guard wantsRunning, var value = AccelerationMath.magnitude(x: x, y: y, z: z) else { return }
        if removeGravity {
            value = abs(value - 1)
        }
        access = .ready
        magnitude = value
        peak = max(peak, value)
        samples.append(value)
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
    }
}

struct SeismometerToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = SeismometerModel()

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
        .navigationTitle(settings.l10n.toolSeismoTitle)
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
                systemImage: "waveform.path.ecg",
                title: settings.l10n.toolSeismoTitle,
                message: settings.l10n.motionDeniedMessage,
                actionTitle: settings.l10n.openSettings,
                action: openSettings
            )
        case .unavailable:
            SensorStatusCard(
                systemImage: "waveform.path.ecg",
                title: settings.l10n.toolSeismoTitle,
                message: settings.l10n.seismoUnavailable
            )
        case .needsPermission:
            SensorStatusCard(
                systemImage: "waveform.path.ecg",
                title: settings.l10n.toolSeismoTitle,
                message: settings.l10n.motionPromptMessage
            )
            ProgressView()
        case .ready:
            graph
        }
    }

    private var graph: some View {
        VStack(spacing: 16) {
            ToolValueReadout(
                value: number(model.magnitude),
                unit: settings.l10n.seismoUnit,
                caption: settings.l10n.seismoNow
            )
            VibrationGraph(samples: model.samples)
                .frame(height: 180)
                .toolGlass(cornerRadius: 20)
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityLabel(settings.l10n.toolSeismoTitle)
                .accessibilityValue(number(model.magnitude))
            ToolStatPill(title: settings.l10n.seismoPeak, value: number(model.peak) + " " + settings.l10n.seismoUnit)
            ToolActionButton(
                title: settings.l10n.seismoReset,
                systemImage: "arrow.counterclockwise",
                prominent: false
            ) {
                settings.triggerFeedback()
                model.resetPeak()
            }
            ToolHintText(text: settings.l10n.seismoHint)
        }
    }

    private func number(_ value: Double) -> String {
        MeasurementFormat.fixed(value, fractionDigits: 3, locale: locale)
    }

    private func openSettings() {
        settings.triggerFeedback()
        openAppSettings()
    }
}

private struct VibrationGraph: View {
    var samples: [Double]

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 12
            var baseline = Path()
            baseline.move(to: CGPoint(x: inset, y: size.height - inset))
            baseline.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
            context.stroke(baseline, with: .color(Color.primary.opacity(0.15)), lineWidth: 1)
            guard samples.count > 1 else { return }
            let scale = max(samples.max() ?? 0.02, 0.02)
            var path = Path()
            for (index, sample) in samples.enumerated() {
                let x = inset + (size.width - inset * 2) * CGFloat(index) / CGFloat(samples.count - 1)
                let y = size.height - inset - CGFloat(sample / scale) * (size.height - inset * 2)
                let point = CGPoint(x: x, y: y)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            context.stroke(
                path,
                with: .color(Color.cyan),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .padding(8)
        .accessibilityHidden(true)
    }
}
