import SwiftUI
import CoreMotion
import Combine

// MARK: - Level

private enum LevelMode: String, CaseIterable, Identifiable {
    case surface
    case edge

    var id: String { rawValue }
}

extension LevelInterfaceOrientation {
    init(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            // The status bar sits on the left, so the top of the phone points left.
            self = .landscapeDeviceTopLeft
        case .landscapeRight:
            self = .landscapeDeviceTopRight
        default:
            self = .portrait
        }
    }
}

@MainActor
final class LevelToolModel: ObservableObject {
    @Published private(set) var isAvailable = true
    @Published private(set) var hasSample = false
    @Published private(set) var reading = LevelReading.flat
    @Published private(set) var isCalibrated = false

    private let motion = CMMotionManager()
    private var wantsRunning = false
    private var isRunning = false
    private var smoothed: GravityVector?
    private var reference: GravityVector?
    private var wasSurfaceLevel = false
    private var wasEdgeLevel = false

    func start() {
        wantsRunning = true
        guard motion.isDeviceMotionAvailable || motion.isAccelerometerAvailable else {
            isAvailable = false
            return
        }
        isAvailable = true
        guard !isRunning else { return }

        let model = self
        if motion.isDeviceMotionAvailable, let frame = preferredReferenceFrame() {
            isRunning = true
            motion.deviceMotionUpdateInterval = 1.0 / 20.0
            motion.startDeviceMotionUpdates(using: frame, to: .main) { data, _ in
                guard let data else { return }
                let gravity = GravityVector(x: data.gravity.x, y: data.gravity.y, z: data.gravity.z)
                Task { @MainActor in
                    model.consume(gravity)
                }
            }
        } else if motion.isAccelerometerAvailable {
            isRunning = true
            motion.accelerometerUpdateInterval = 1.0 / 20.0
            motion.startAccelerometerUpdates(to: .main) { data, _ in
                guard let data else { return }
                let gravity = GravityVector(
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z
                )
                Task { @MainActor in
                    model.consume(gravity)
                }
            }
        } else {
            isAvailable = false
        }
    }

    func stop() {
        wantsRunning = false
        isRunning = false
        motion.stopDeviceMotionUpdates()
        motion.stopAccelerometerUpdates()
        smoothed = nil
    }

    func zero() {
        guard let smoothed else { return }
        reference = smoothed
        isCalibrated = true
        publish(smoothed)
    }

    func clearZero() {
        reference = nil
        isCalibrated = false
        if let smoothed {
            publish(smoothed)
        }
    }

    private func preferredReferenceFrame() -> CMAttitudeReferenceFrame? {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        if available.contains(.xArbitraryZVertical) { return .xArbitraryZVertical }
        if available.contains(.xArbitraryCorrectedZVertical) { return .xArbitraryCorrectedZVertical }
        if available.contains(.xMagneticNorthZVertical) { return .xMagneticNorthZVertical }
        return nil
    }

    private func consume(_ raw: GravityVector) {
        guard wantsRunning else { return }
        let filtered: GravityVector
        if let smoothed {
            filtered = GravityVector(
                x: smoothed.x * 0.7 + raw.x * 0.3,
                y: smoothed.y * 0.7 + raw.y * 0.3,
                z: smoothed.z * 0.7 + raw.z * 0.3
            )
        } else {
            filtered = raw
        }
        self.smoothed = filtered
        hasSample = true
        publish(filtered)
    }

    private func publish(_ gravity: GravityVector) {
        let rawReading = LevelMath.reading(gravity: gravity, reference: reference)
        let surface = LevelMath.latchedLevel(
            angleDegrees: rawReading.tiltDegrees,
            wasLevel: wasSurfaceLevel
        )
        let edge = LevelMath.latchedLevel(
            angleDegrees: rawReading.edgeAngleDegrees,
            wasLevel: wasEdgeLevel
        )
        wasSurfaceLevel = surface
        wasEdgeLevel = edge
        reading = LevelReading(
            bubbleX: rawReading.bubbleX,
            bubbleY: rawReading.bubbleY,
            tiltDegrees: rawReading.tiltDegrees,
            edgeAngleDegrees: rawReading.edgeAngleDegrees,
            isSurfaceLevel: surface,
            isEdgeLevel: edge
        )
    }
}

struct LevelToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = LevelToolModel()
    @State private var mode: LevelMode = .surface

    private var locale: Locale { Locale(identifier: settings.appLanguage.rawValue) }

    private var isLevel: Bool {
        mode == .surface ? model.reading.isSurfaceLevel : model.reading.isEdgeLevel
    }

    var body: some View {
        let orientation = LevelInterfaceOrientation(interfaceOrientation: currentInterfaceOrientation())

        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Picker(settings.l10n.toolLevelTitle, selection: $mode) {
                    Text(settings.l10n.levelSurface).tag(LevelMode.surface)
                    Text(settings.l10n.levelEdge).tag(LevelMode.edge)
                }
                .pickerStyle(.segmented)

                if !model.isAvailable {
                    SensorStatusCard(
                        systemImage: "circle.grid.cross",
                        title: settings.l10n.toolLevelTitle,
                        message: settings.l10n.levelMotionUnavailable
                    )
                } else if !model.hasSample {
                    ProgressView()
                        .controlSize(.large)
                        .padding(.vertical, 48)
                    ToolHintText(text: mode == .surface ? settings.l10n.levelHintSurface : settings.l10n.levelHintEdge)
                } else {
                    instrument(orientation: orientation)
                    readout
                    if model.isCalibrated {
                        Text(settings.l10n.levelCalibratedBadge)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.cyan.opacity(0.14)))
                    }
                    ToolHintText(text: mode == .surface ? settings.l10n.levelHintSurface : settings.l10n.levelHintEdge)
                    controls
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(NeonAmbientBackground())
        .navigationTitle(settings.l10n.toolLevelTitle)
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
        .onChange(of: mode) { _, _ in
            settings.triggerFeedback(impact: .light)
        }
        .onChange(of: isLevel) { wasLevel, levelNow in
            guard levelNow, !wasLevel, settings.hapticFeedback, model.hasSample else { return }
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred(intensity: 0.9)
        }
    }

    @ViewBuilder
    private func instrument(orientation: LevelInterfaceOrientation) -> some View {
        if mode == .surface {
            surfaceVial(orientation: orientation)
        } else {
            edgeVial(orientation: orientation)
        }
    }

    private func surfaceVial(orientation: LevelInterfaceOrientation) -> some View {
        let reading = model.reading
        let screen = LevelMath.screenOffset(
            deviceX: reading.bubbleX,
            deviceY: reading.bubbleY,
            orientation: orientation
        )
        let travel: CGFloat = 96
        let level = reading.isSurfaceLevel

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (level ? Color.green : Color.cyan).opacity(0.22),
                            Color.blue.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 140
                    )
                )
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 10)
                .padding(6)
            Rectangle()
                .fill(Color.primary.opacity(0.16))
                .frame(width: 1.5, height: 210)
            Rectangle()
                .fill(Color.primary.opacity(0.16))
                .frame(width: 210, height: 1.5)
            Circle()
                .stroke(level ? Color.green : Color.primary.opacity(0.25), lineWidth: 2)
                .frame(width: 64, height: 64)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            level ? Color.green.opacity(0.95) : Color.cyan.opacity(0.92)
                        ],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 36
                    )
                )
                .frame(width: 44, height: 44)
                .shadow(color: (level ? Color.green : Color.cyan).opacity(0.45), radius: 8, y: 2)
                .offset(x: screen.x * travel, y: screen.y * travel)
        }
        .frame(width: 270, height: 270)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(
                LinearGradient(
                    colors: [Color.white.opacity(0.7), Color.cyan.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.l10n.toolLevelTitle)
        .accessibilityValue(degreeText(reading.tiltDegrees, signed: false))
        .frame(maxWidth: .infinity)
    }

    private func edgeVial(orientation: LevelInterfaceOrientation) -> some View {
        let reading = model.reading
        let axis = LevelMath.screenOffset(deviceX: 0, deviceY: 1, orientation: orientation)
        let angle = atan2(axis.y, axis.x)
        let travel = min(1, max(-1, reading.edgeAngleDegrees / LevelMath.bubbleFullScaleDegrees))
        let level = reading.isEdgeLevel

        return ZStack {
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.08))
                .frame(width: 230, height: 46)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(level ? Color.green.opacity(0.8) : Color.primary.opacity(0.12), lineWidth: 2)
                )
            Circle()
                .fill(Color.primary.opacity(0.18))
                .frame(width: 8, height: 8)
            Circle()
                .fill(level ? Color.green : Color.cyan)
                .frame(width: 32, height: 32)
                .shadow(color: (level ? Color.green : Color.cyan).opacity(0.4), radius: 6, y: 2)
                .offset(x: travel * 90)
        }
        .rotationEffect(.radians(angle))
        .frame(width: 270, height: 270)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.l10n.levelEdge)
        .accessibilityValue(degreeText(reading.edgeAngleDegrees, signed: true))
        .frame(maxWidth: .infinity)
    }

    private var readout: some View {
        let reading = model.reading
        let level = isLevel
        let text = mode == .surface
            ? degreeText(reading.tiltDegrees, signed: false)
            : degreeText(reading.edgeAngleDegrees, signed: true)

        return VStack(spacing: 4) {
            Text(text)
                .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(level ? .green : .primary)
                .environment(\.layoutDirection, .leftToRight)
            Text(mode == .surface ? (level ? settings.l10n.levelIsLevel : settings.l10n.levelSurface) : settings.l10n.levelFromHorizontal)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            ToolActionButton(title: settings.l10n.levelCalibrate, systemImage: "scope") {
                settings.triggerFeedback()
                model.zero()
            }
            if model.isCalibrated {
                ToolActionButton(
                    title: settings.l10n.levelResetCalibration,
                    systemImage: "arrow.counterclockwise",
                    prominent: false
                ) {
                    settings.triggerFeedback()
                    model.clearZero()
                }
            }
        }
    }

    private func degreeText(_ value: Double, signed: Bool) -> String {
        MeasurementFormat.degrees(value, fractionDigits: 1, locale: locale, signed: signed)
    }
}
