import SwiftUI
import CoreLocation
import Combine

// MARK: - GPS speedometer

fileprivate enum SpeedAccess: Equatable {
    case needsPermission
    case denied
    case unavailable
    case ready
}

@MainActor
fileprivate final class SpeedometerModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published fileprivate var access: SpeedAccess = .needsPermission
    @Published fileprivate var unit: SpeedUnit = .kilometersPerHour
    @Published fileprivate var metersPerSecond: Double?
    @Published fileprivate var maximumMetersPerSecond: Double?

    private let manager: CLLocationManager
    private var wantsRunning = false
    private var updatesRunning = false

    override init() {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .otherNavigation
        manager.pausesLocationUpdatesAutomatically = false
        self.manager = manager
        super.init()
        manager.delegate = self
    }

    func start() {
        wantsRunning = true
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            access = .unavailable
            return
        }
        applyAuthorization(Self.mapAuth(manager.authorizationStatus))
    }

    func stop() {
        wantsRunning = false
        stopUpdates()
    }

    func resetMaximum() {
        maximumMetersPerSecond = metersPerSecond
    }

    func select(_ unit: SpeedUnit) {
        self.unit = unit
    }

    private func applyAuthorization(_ access: SpeedAccess) {
        guard wantsRunning else { return }
        switch access {
        case .needsPermission:
            self.access = .needsPermission
            manager.requestWhenInUseAuthorization()
        case .denied:
            stopUpdates()
            self.access = .denied
        case .unavailable:
            stopUpdates()
            self.access = .unavailable
        case .ready:
            self.access = .ready
            beginUpdates()
        }
    }

    private func beginUpdates() {
        guard !updatesRunning else { return }
        updatesRunning = true
        manager.startUpdatingLocation()
    }

    private func stopUpdates() {
        updatesRunning = false
        manager.stopUpdatingLocation()
    }

    private func applySpeed(metersPerSecond: Double, speedAccuracy: Double) {
        guard wantsRunning, speedAccuracy >= 0, SpeedMath.isValid(metersPerSecond: metersPerSecond) else { return }
        access = .ready
        self.metersPerSecond = metersPerSecond
        if let maximumMetersPerSecond {
            self.maximumMetersPerSecond = max(maximumMetersPerSecond, metersPerSecond)
        } else {
            maximumMetersPerSecond = metersPerSecond
        }
    }

    nonisolated private static func mapAuth(_ status: CLAuthorizationStatus) -> SpeedAccess {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .ready
        case .notDetermined:
            return .needsPermission
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let access = Self.mapAuth(manager.authorizationStatus)
        Task { @MainActor in
            self.applyAuthorization(access)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let speed = location.speed
        let accuracy = location.speedAccuracy
        Task { @MainActor in
            self.applySpeed(metersPerSecond: speed, speedAccuracy: accuracy)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        let denied = nsError.domain == kCLErrorDomain && nsError.code == CLError.denied.rawValue
        Task { @MainActor in
            guard self.wantsRunning, denied else { return }
            self.applyAuthorization(.denied)
        }
    }
}

struct SpeedometerToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = SpeedometerModel()

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
        .navigationTitle(settings.l10n.toolSpeedTitle)
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
                systemImage: "speedometer",
                title: settings.l10n.toolSpeedTitle,
                message: settings.l10n.speedDeniedMessage,
                actionTitle: settings.l10n.openSettings,
                action: openSettings
            )
        case .unavailable:
            SensorStatusCard(
                systemImage: "location.slash",
                title: settings.l10n.toolSpeedTitle,
                message: settings.l10n.speedUnavailable
            )
        case .needsPermission:
            SensorStatusCard(
                systemImage: "location.fill",
                title: settings.l10n.toolSpeedTitle,
                message: settings.l10n.speedPromptMessage
            )
        case .ready:
            readings
        }
    }

    private var readings: some View {
        VStack(spacing: 16) {
            Picker(settings.l10n.speedCurrent, selection: Binding(
                get: { model.unit },
                set: { model.select($0) }
            )) {
                Text(settings.l10n.speedKmh).tag(SpeedUnit.kilometersPerHour)
                Text(settings.l10n.speedMph).tag(SpeedUnit.milesPerHour)
                Text(settings.l10n.speedMs).tag(SpeedUnit.metersPerSecond)
            }
            .pickerStyle(.segmented)

            ToolValueReadout(
                value: speedText(model.metersPerSecond),
                unit: unitLabel,
                caption: model.metersPerSecond == nil ? settings.l10n.speedWaiting : settings.l10n.speedCurrent
            )
            ToolStatPill(title: settings.l10n.speedMax, value: speedText(model.maximumMetersPerSecond) + " " + unitLabel)
            ToolActionButton(
                title: settings.l10n.speedResetMax,
                systemImage: "arrow.counterclockwise",
                prominent: false
            ) {
                settings.triggerFeedback()
                model.resetMaximum()
            }
        }
    }

    private var unitLabel: String {
        switch model.unit {
        case .kilometersPerHour: return settings.l10n.speedKmh
        case .milesPerHour: return settings.l10n.speedMph
        case .metersPerSecond: return settings.l10n.speedMs
        }
    }

    private func speedText(_ metersPerSecond: Double?) -> String {
        guard let metersPerSecond,
              let converted = SpeedMath.convert(metersPerSecond: metersPerSecond, to: model.unit) else {
            return "—"
        }
        return MeasurementFormat.fixed(converted, fractionDigits: 1, locale: locale)
    }

    private func openSettings() {
        settings.triggerFeedback()
        openAppSettings()
    }
}
