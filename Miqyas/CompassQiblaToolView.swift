import SwiftUI
import CoreLocation
import Combine

// MARK: - Compass + Qibla

enum CompassAccess: Equatable {
    case needsPermission
    case denied
    case authorized
}

/// UIInterfaceOrientation's landscape cases are swapped compared with CLDeviceOrientation.
func headingDeviceOrientation(for interface: UIInterfaceOrientation) -> CLDeviceOrientation {
    switch interface {
    case .portrait:
        return .portrait
    case .portraitUpsideDown:
        return .portraitUpsideDown
    case .landscapeLeft:
        return .landscapeRight
    case .landscapeRight:
        return .landscapeLeft
    default:
        return .portrait
    }
}

@MainActor
final class CompassQiblaModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var access: CompassAccess = .needsPermission
    @Published private(set) var headingHardwareAvailable = true
    @Published private(set) var heading: HeadingFix?
    @Published private(set) var headingAccuracy: Double?
    @Published private(set) var latitude: Double?
    @Published private(set) var longitude: Double?

    private let manager: CLLocationManager
    private var wantsRunning = false
    private var updatesRunning = false
    private var headingOrientation: CLDeviceOrientation = .portrait

    override init() {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 20
        manager.headingFilter = 1
        manager.pausesLocationUpdatesAutomatically = false
        self.manager = manager
        super.init()
        self.headingHardwareAvailable = CLLocationManager.headingAvailable()
        self.access = Self.mapAuth(manager.authorizationStatus)
        manager.delegate = self
    }

    func start() {
        wantsRunning = true
        headingHardwareAvailable = CLLocationManager.headingAvailable()
        applyAuthorization(Self.mapAuth(manager.authorizationStatus))
    }

    func stop() {
        wantsRunning = false
        stopUpdates()
    }

    func updateInterfaceOrientation(_ orientation: UIInterfaceOrientation) {
        headingOrientation = headingDeviceOrientation(for: orientation)
        manager.headingOrientation = headingOrientation
    }

    private func applyAuthorization(_ access: CompassAccess) {
        self.access = access
        guard wantsRunning else { return }
        switch access {
        case .needsPermission:
            manager.requestWhenInUseAuthorization()
        case .denied:
            stopUpdates()
        case .authorized:
            beginUpdates()
        }
    }

    private func beginUpdates() {
        manager.headingOrientation = headingOrientation
        guard !updatesRunning else { return }
        updatesRunning = true
        if headingHardwareAvailable {
            manager.startUpdatingHeading()
        }
        manager.startUpdatingLocation()
    }

    private func stopUpdates() {
        updatesRunning = false
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    private func applyLocation(latitude: Double, longitude: Double, horizontalAccuracy: Double) {
        guard wantsRunning, horizontalAccuracy >= 0 else { return }
        self.latitude = latitude
        self.longitude = longitude
    }

    private func applyHeading(trueHeading: Double, magneticHeading: Double, accuracy: Double) {
        guard wantsRunning else { return }
        headingAccuracy = accuracy
        if let resolved = CompassMath.resolvedHeading(
            trueHeading: trueHeading,
            magneticHeading: magneticHeading,
            accuracy: accuracy
        ) {
            heading = resolved
        }
    }

    nonisolated private static func mapAuth(_ status: CLAuthorizationStatus) -> CompassAccess {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
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
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let accuracy = location.horizontalAccuracy
        Task { @MainActor in
            self.applyLocation(latitude: latitude, longitude: longitude, horizontalAccuracy: accuracy)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let trueHeading = newHeading.trueHeading
        let magneticHeading = newHeading.magneticHeading
        let accuracy = newHeading.headingAccuracy
        Task { @MainActor in
            self.applyHeading(trueHeading: trueHeading, magneticHeading: magneticHeading, accuracy: accuracy)
        }
    }
}

struct CompassQiblaToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = CompassQiblaModel()

    private var locale: Locale { Locale(identifier: settings.appLanguage.rawValue) }

    private var qibla: Qibla? {
        guard let latitude = model.latitude, let longitude = model.longitude else { return nil }
        return QiblaMath.qibla(fromLatitude: latitude, longitude: longitude)
    }

    private var needsCalibration: Bool {
        guard let accuracy = model.headingAccuracy ?? model.heading?.accuracy else { return false }
        return CompassMath.needsCalibration(headingAccuracy: accuracy)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                switch model.access {
                case .denied:
                    SensorStatusCard(
                        systemImage: "location.slash.fill",
                        title: settings.l10n.toolCompassTitle,
                        message: settings.l10n.locationDeniedMessage,
                        actionTitle: settings.l10n.openSettings,
                        action: {
                            settings.triggerFeedback()
                            openAppSettings()
                        }
                    )
                case .needsPermission:
                    SensorStatusCard(
                        systemImage: "location.fill",
                        title: settings.l10n.toolCompassTitle,
                        message: settings.l10n.locationPromptMessage
                    )
                case .authorized:
                    authorizedContent
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(NeonAmbientBackground())
        .navigationTitle(settings.l10n.toolCompassTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        model.updateInterfaceOrientation(currentInterfaceOrientation())
                    }
                    .onChange(of: proxy.size) { _, _ in
                        model.updateInterfaceOrientation(currentInterfaceOrientation())
                    }
            }
        }
        .onAppear {
            model.updateInterfaceOrientation(currentInterfaceOrientation())
            model.start()
        }
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.updateInterfaceOrientation(currentInterfaceOrientation())
                model.start()
            } else {
                model.stop()
            }
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        if !model.headingHardwareAvailable {
            banner(
                systemImage: "location.slash",
                text: settings.l10n.compassHardwareUnavailable,
                tint: .secondary
            )
        }

        if model.headingHardwareAvailable {
            compassDial
        }

        if needsCalibration && model.headingHardwareAvailable {
            banner(
                systemImage: "arrow.triangle.2.circlepath",
                text: settings.l10n.compassCalibrateHint,
                tint: .orange
            )
        }

        qiblaCard
    }

    private var compassDial: some View {
        let heading = model.heading
        let bearing = qibla?.bearingDegrees

        return ZStack {
            Circle()
                .fill(.ultraThinMaterial)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.7), Color.teal.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )

            rose(heading: heading?.degrees ?? 0, qiblaBearing: bearing)
                .opacity(heading == nil ? 0.35 : 1)
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(headingText)
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.primary)
                    .environment(\.layoutDirection, .leftToRight)
                if let heading {
                    Text(settings.l10n.cardinalName(CompassMath.cardinal(forDegrees: heading.degrees)))
                        .font(.subheadline.weight(.semibold))
                    Text(heading.isTrueNorth ? settings.l10n.compassTrueNorth : settings.l10n.compassMagneticNorth)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Circle().fill(.ultraThinMaterial))

            VStack {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: accentGradientColors, startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: Color.cyan.opacity(0.4), radius: 3, y: 1)
                    .padding(.top, 10)
                Spacer()
            }
        }
        .frame(width: 290, height: 290)
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func rose(heading: Double, qiblaBearing: Double?) -> some View {
        ZStack {
            ForEach(0..<72, id: \.self) { index in
                let major = index % 18 == 0
                let mid = index % 6 == 0
                Capsule()
                    .fill(major ? Color.primary : Color.secondary.opacity(0.45))
                    .frame(width: major ? 2.5 : 1, height: major ? 16 : (mid ? 10 : 6))
                    .offset(y: -124)
                    .rotationEffect(.degrees(Double(index) * 5))
            }

            dialLetter(settings.l10n.cardinalNorthShort, degrees: 0, emphasis: true)
            dialLetter(settings.l10n.cardinalEastShort, degrees: 90, emphasis: false)
            dialLetter(settings.l10n.cardinalSouthShort, degrees: 180, emphasis: false)
            dialLetter(settings.l10n.cardinalWestShort, degrees: 270, emphasis: false)

            if let qiblaBearing, let qibla, !QiblaMath.isAtKaaba(distanceKilometers: qibla.distanceKilometers) {
                qiblaMarker
                    .offset(y: -108)
                    .rotationEffect(.degrees(qiblaBearing))
            }
        }
        .rotationEffect(.degrees(-heading))
        .environment(\.layoutDirection, .leftToRight)
    }

    private func dialLetter(_ text: String, degrees: Double, emphasis: Bool) -> some View {
        Text(text)
            .font(.system(size: emphasis ? 18 : 15, weight: .heavy, design: .rounded))
            .foregroundColor(emphasis ? .red : .primary)
            .rotationEffect(.degrees(-degrees))
            .offset(y: -100)
            .rotationEffect(.degrees(degrees))
    }

    private var qiblaMarker: some View {
        VStack(spacing: 0) {
            Image(systemName: "location.north.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.05, green: 0.28, blue: 0.2))
                .frame(width: 14, height: 16)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.yellow.opacity(0.9))
                        .frame(height: 3)
                        .padding(.top, 4)
                }
                .shadow(color: Color.green.opacity(0.35), radius: 3, y: 1)
        }
        .accessibilityLabel(settings.l10n.qiblaBearingLabel)
    }

    private var qiblaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let qibla {
                if QiblaMath.isAtKaaba(distanceKilometers: qibla.distanceKilometers) {
                    Label(settings.l10n.atKaabaMessage, systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    infoRow(
                        title: settings.l10n.qiblaBearingLabel,
                        value: MeasurementFormat.degrees(qibla.bearingDegrees, fractionDigits: 1, locale: locale)
                    )
                    if let heading = model.heading {
                        Text(turnInstruction(heading: heading.degrees, bearing: qibla.bearingDegrees))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.teal)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Divider()
                    HStack {
                        Text(settings.l10n.distanceToMakkah)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer(minLength: 12)
                        Text(distanceNumber(qibla.distanceKilometers))
                            .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundColor(.primary)
                            .environment(\.layoutDirection, .leftToRight)
                        Text(settings.l10n.kilometersUnit)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(settings.l10n.locatingMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .toolGlass()
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundColor(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func banner(systemImage: String, text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundColor(tint)
            Text(text)
                .font(.footnote)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }

    private var headingText: String {
        guard let heading = model.heading else { return "—" }
        return MeasurementFormat.degrees(heading.degrees, fractionDigits: 0, locale: locale)
    }

    private func distanceNumber(_ kilometers: Double) -> String {
        let digits = kilometers >= 100 ? 0 : 1
        return MeasurementFormat.grouped(kilometers, fractionDigits: digits, locale: locale)
    }

    private func turnInstruction(heading: Double, bearing: Double) -> String {
        let delta = CompassMath.signedDelta(from: heading, to: bearing)
        if abs(delta) < 3 {
            return settings.l10n.facingQibla
        }
        let amount = MeasurementFormat.fixed(abs(delta), fractionDigits: 0, locale: locale)
        return delta > 0 ? settings.l10n.turnRight(amount) : settings.l10n.turnLeft(amount)
    }
}
