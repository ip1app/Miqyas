import SwiftUI
import CoreMotion
import Combine

// MARK: - Barometer

fileprivate enum BarometerAccess: Equatable {
    case needsPermission
    case denied
    case unavailable
    case ready
}

@MainActor
fileprivate final class BarometerModel: ObservableObject {
    @Published fileprivate var access: BarometerAccess = .needsPermission
    @Published fileprivate var pressureHectopascals: Double?
    @Published fileprivate var relativeMeters: Double?
    @Published fileprivate var absoluteMeters: Double?
    @Published fileprivate var estimatedMeters: Double?
    @Published fileprivate var usesAbsoluteAltitude = false

    /// Absolute updates replace relative updates on the same altimeter, so pressure
    /// and absolute altitude are read from two objects.
    private let relativeAltimeter = CMAltimeter()
    private let absoluteAltimeter = CMAltimeter()
    private var wantsRunning = false
    private var isRunning = false

    func start() {
        wantsRunning = true
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            access = .unavailable
            return
        }
        switch MotionAuthorization.current {
        case .denied:
            stopUpdates()
            access = .denied
            return
        case .needsPrompt:
            if pressureHectopascals == nil { access = .needsPermission }
        case .allowed:
            if pressureHectopascals == nil { access = .ready }
        }
        guard !isRunning else { return }
        isRunning = true
        let model = self
        let absoluteAvailable = CMAltimeter.isAbsoluteAltitudeAvailable()
        usesAbsoluteAltitude = absoluteAvailable

        relativeAltimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
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
            let kilopascals = data.pressure.doubleValue
            let relative = data.relativeAltitude.doubleValue
            Task { @MainActor in
                model.applyRelative(kilopascals: kilopascals, relativeMeters: relative)
            }
        }

        guard absoluteAvailable else { return }
        absoluteAltimeter.startAbsoluteAltitudeUpdates(to: .main) { data, error in
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
            let altitude = data.altitude
            Task { @MainActor in
                model.applyAbsolute(altitude)
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
        relativeAltimeter.stopRelativeAltitudeUpdates()
        absoluteAltimeter.stopAbsoluteAltitudeUpdates()
    }

    private func applyRelative(kilopascals: Double, relativeMeters: Double) {
        guard wantsRunning else { return }
        access = .ready
        if let hectopascals = BarometricMath.hectopascals(fromKilopascals: kilopascals) {
            pressureHectopascals = hectopascals
            estimatedMeters = BarometricMath.altitudeMeters(pressureHectopascals: hectopascals)
        }
        if relativeMeters.isFinite {
            self.relativeMeters = relativeMeters
        }
    }

    private func applyAbsolute(_ meters: Double) {
        guard wantsRunning, meters.isFinite else { return }
        access = .ready
        absoluteMeters = meters
    }
}

struct BarometerToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = BarometerModel()

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
        .navigationTitle(settings.l10n.toolBarometerTitle)
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
                systemImage: "barometer",
                title: settings.l10n.toolBarometerTitle,
                message: settings.l10n.motionDeniedMessage,
                actionTitle: settings.l10n.openSettings,
                action: openSettings
            )
        case .unavailable:
            SensorStatusCard(
                systemImage: "barometer",
                title: settings.l10n.toolBarometerTitle,
                message: settings.l10n.barometerUnavailable
            )
        case .needsPermission:
            SensorStatusCard(
                systemImage: "barometer",
                title: settings.l10n.toolBarometerTitle,
                message: settings.l10n.motionPromptMessage
            )
            ProgressView()
        case .ready:
            readings
        }
    }

    private var readings: some View {
        VStack(spacing: 16) {
            ToolValueReadout(
                value: number(model.pressureHectopascals, digits: 1),
                unit: settings.l10n.barometerHpa,
                caption: settings.l10n.barometerPressure
            )
            Text(settings.l10n.approximateReading)
                .font(.footnote.weight(.bold))
                .foregroundColor(.orange)

            if model.usesAbsoluteAltitude, model.absoluteMeters != nil {
                altitudeCard(
                    title: settings.l10n.barometerAltitude,
                    value: number(model.absoluteMeters, digits: 1),
                    caption: settings.l10n.barometerAbsoluteCaption
                )
            } else {
                altitudeCard(
                    title: settings.l10n.barometerChange,
                    value: number(model.relativeMeters, digits: 2),
                    caption: settings.l10n.barometerRelativeCaption
                )
                altitudeCard(
                    title: settings.l10n.barometerEstimate,
                    value: number(model.estimatedMeters, digits: 0),
                    caption: settings.l10n.barometerEstimateCaption
                )
            }
            ToolHintText(text: settings.l10n.barometerHint)
        }
    }

    private func altitudeCard(title: String, value: String, caption: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                Text(settings.l10n.unitMeter)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .environment(\.layoutDirection, .leftToRight)
            Text(caption)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .toolGlass(cornerRadius: 20)
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
