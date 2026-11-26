import SwiftUI
import CoreMotion
import Combine

// MARK: - Pedometer

fileprivate enum PedometerAccess: Equatable {
    case needsPermission
    case denied
    case unavailable
    case ready
}

@MainActor
fileprivate final class PedometerModel: ObservableObject {
    @Published fileprivate var access: PedometerAccess = .needsPermission
    @Published fileprivate var steps: Int?
    @Published fileprivate var distanceMeters: Double?
    @Published fileprivate var distanceAvailable = false

    private let pedometer = CMPedometer()
    private var wantsRunning = false
    private var isRunning = false
    private var dayStart = Date.distantPast

    func start() {
        wantsRunning = true
        distanceAvailable = CMPedometer.isDistanceAvailable()
        guard CMPedometer.isStepCountingAvailable() else {
            access = .unavailable
            return
        }
        switch MotionAuthorization.current {
        case .denied:
            stopUpdates()
            access = .denied
            return
        case .needsPrompt:
            if steps == nil { access = .needsPermission }
        case .allowed:
            if steps == nil { access = .ready }
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        if isRunning, startOfDay != dayStart {
            stopUpdates()
        }
        dayStart = startOfDay
        guard !isRunning else { return }
        isRunning = true
        let model = self
        pedometer.startUpdates(from: startOfDay) { data, error in
            if let error {
                let denied = MotionFailure.isAuthorizationDenied(error)
                Task { @MainActor in
                    if denied {
                        model.fail(denied: true)
                    }
                }
                return
            }
            let steps = data?.numberOfSteps.intValue
            let distance = data?.distance?.doubleValue
            Task { @MainActor in
                model.apply(steps: steps, distanceMeters: distance)
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
        guard isRunning else { return }
        isRunning = false
        pedometer.stopUpdates()
    }

    private func apply(steps: Int?, distanceMeters: Double?) {
        guard wantsRunning else { return }
        access = .ready
        if let steps, steps >= 0 {
            self.steps = steps
        }
        if let distanceMeters, distanceMeters.isFinite, distanceMeters >= 0 {
            self.distanceMeters = distanceMeters
        }
    }
}

struct PedometerToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = PedometerModel()

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
        .navigationTitle(settings.l10n.toolPedometerTitle)
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
                systemImage: "figure.walk",
                title: settings.l10n.toolPedometerTitle,
                message: settings.l10n.motionDeniedMessage,
                actionTitle: settings.l10n.openSettings,
                action: openSettings
            )
        case .unavailable:
            SensorStatusCard(
                systemImage: "figure.walk",
                title: settings.l10n.toolPedometerTitle,
                message: settings.l10n.pedometerUnavailable
            )
        case .needsPermission:
            SensorStatusCard(
                systemImage: "figure.walk",
                title: settings.l10n.toolPedometerTitle,
                message: settings.l10n.motionPromptMessage
            )
            ProgressView()
        case .ready:
            readings
        }
    }

    private var readings: some View {
        let distance = distanceReading
        return VStack(spacing: 16) {
            ToolValueReadout(
                value: stepsText,
                unit: "",
                caption: settings.l10n.pedometerSteps
            )
            Text(settings.l10n.pedometerToday)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
            ToolStatPill(
                title: settings.l10n.pedometerDistance,
                value: distance.value == "—" ? "—" : "\(distance.value) \(distance.unit)"
            )
            if !model.distanceAvailable {
                ToolHintText(text: settings.l10n.pedometerNoDistance)
            }
            ToolHintText(text: settings.l10n.pedometerHint)
        }
    }

    private var stepsText: String {
        guard let steps = model.steps else { return "—" }
        return MeasurementFormat.grouped(Double(steps), fractionDigits: 0, locale: locale)
    }

    private var distanceReading: (value: String, unit: String) {
        guard model.distanceAvailable, let meters = model.distanceMeters else {
            return ("—", settings.l10n.unitMeter)
        }
        if meters >= 1000 {
            return (
                MeasurementFormat.fixed(meters / 1000, fractionDigits: 2, locale: locale),
                settings.l10n.kilometersUnit
            )
        }
        return (
            MeasurementFormat.grouped(meters, fractionDigits: 0, locale: locale),
            settings.l10n.unitMeter
        )
    }

    private func openSettings() {
        settings.triggerFeedback()
        openAppSettings()
    }
}
