import SwiftUI
import ARKit
import AVFoundation
import Combine
import RealityKit
import simd
import UIKit

// MARK: - AR measure

fileprivate enum ARAccess: Equatable {
    case needsPermission
    case cameraDenied
    case motionDenied
    case unavailable
    case ready
}

fileprivate enum ARMeasureMode: String, CaseIterable, Identifiable {
    case distance
    case area

    var id: String { rawValue }

    var pointLimit: Int {
        switch self {
        case .distance: return 2
        case .area: return 3
        }
    }
}

@MainActor
fileprivate final class ARMeasureModel: ObservableObject {
    @Published fileprivate var access: ARAccess = .needsPermission

    private var wantsRunning = false
    private var permissionRequestInFlight = false

    var sessionRunning: Bool {
        wantsRunning && access == .ready
    }

    func start() {
        wantsRunning = true
        guard ARWorldTrackingConfiguration.isSupported else {
            access = .unavailable
            return
        }
        if MotionAuthorization.current == .denied {
            access = .motionDenied
            return
        }
        switch CameraAuthorization.current {
        case .denied:
            access = .cameraDenied
        case .needsPrompt:
            access = .needsPermission
            requestCamera()
        case .allowed:
            access = .ready
        }
    }

    func stop() {
        wantsRunning = false
    }

    private func requestCamera() {
        guard !permissionRequestInFlight else { return }
        permissionRequestInFlight = true
        let model = self
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                model.finishCamera(granted)
            }
        }
    }

    private func finishCamera(_ granted: Bool) {
        permissionRequestInFlight = false
        guard wantsRunning else { return }
        access = granted ? .ready : .cameraDenied
    }
}

struct ARMeasureToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = ARMeasureModel()
    @State private var mode: ARMeasureMode = .distance
    @State private var unit: MeasureDisplayUnit = .centimeters
    @State private var points: [WorldPoint] = []
    @State private var missedSurface = false
    @State private var showingLineOptions = false
    @State private var labelPoint: CGPoint?
    @State private var hintVisible = true
    @State private var hintTask: Task<Void, Never>?

    private var locale: Locale { Locale(identifier: settings.appLanguage.rawValue) }

    private var rectangle: RectangleMeasure? {
        guard mode == .area, points.count >= 3 else { return nil }
        return MeasureMath.rectangle(origin: points[0], alongWidth: points[1], third: points[2])
    }

    var body: some View {
        Group {
            switch model.access {
            case .cameraDenied:
                permissionCard(message: settings.l10n.cameraDeniedMessage, systemImage: "camera.fill")
            case .motionDenied:
                permissionCard(message: settings.l10n.motionDeniedMessage, systemImage: "figure.walk")
            case .unavailable:
                SensorStatusCard(
                    systemImage: "viewfinder",
                    title: settings.l10n.toolARTitle,
                    message: settings.l10n.arUnsupported
                )
                .padding(16)
            case .needsPermission:
                SensorStatusCard(
                    systemImage: "viewfinder",
                    title: settings.l10n.toolARTitle,
                    message: settings.l10n.cameraPromptMessage
                )
                .padding(16)
            case .ready:
                measureScene
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NeonAmbientBackground())
        .navigationTitle(settings.l10n.toolARTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingLineOptions = true
                } label: {
                    Image(systemName: "lineweight")
                        .font(.body.bold())
                }
                .accessibilityLabel(settings.l10n.arLineOptions)
            }
        }
        .sheet(isPresented: $showingLineOptions) {
            MeasureLineOptionsSheet()
                .environmentObject(settings)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            model.start()
            showHintBriefly()
        }
        .onDisappear {
            model.stop()
            hintTask?.cancel()
        }
        .onChange(of: hint) { _, _ in
            showHintBriefly()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.start()
            } else {
                model.stop()
                points = []
                missedSurface = false
            }
        }
    }

    private var measureScene: some View {
        ZStack(alignment: .bottom) {
            MeasureCamera(
                running: model.sessionRunning,
                markers: points,
                corners: rectangle?.corners ?? [],
                hasLabel: !measurementLabel.isEmpty,
                lineOptions: settings.measureLineOptions,
                onPoint: addPoint,
                onMiss: { missedSurface = true },
                onLabelPoint: { labelPoint = $0 }
            )
            .ignoresSafeArea()
            .overlay {
                if let labelPoint, !measurementLabel.isEmpty {
                    Text(measurementLabel)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 3)
                        .position(labelPoint)
                        .allowsHitTesting(false)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }

            controls
                .padding(.horizontal, 16)
                .padding(.bottom, 108)
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            if hintVisible {
                Text(hint)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1))
                    .transition(.opacity)
            }

            Picker(settings.l10n.toolARTitle, selection: $mode) {
                Text(settings.l10n.arDistanceMode).tag(ARMeasureMode.distance)
                Text(settings.l10n.arAreaMode).tag(ARMeasureMode.area)
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(maxWidth: 210)
            .onChange(of: mode) { _, _ in
                points = []
                missedSurface = false
                labelPoint = nil
            }

            HStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(readoutValue)
                        .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .environment(\.layoutDirection, .leftToRight)
                    unitMenu
                }
                Spacer(minLength: 8)
                Button {
                    settings.triggerFeedback()
                    points = []
                    missedSurface = false
                    labelPoint = nil
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.l10n.arClear)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .toolGlass(cornerRadius: 22)
        }
    }

    private var unitMenu: some View {
        Menu {
            ForEach(MeasureDisplayUnit.allCases, id: \.rawValue) { choice in
                Button(unitTitle(choice)) {
                    unit = choice
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(readoutUnit)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.blue)
        }
        .accessibilityLabel(readoutUnit)
    }

    private func showHintBriefly() {
        hintTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            hintVisible = true
        }
        hintTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                hintVisible = false
            }
        }
    }

    private var hint: String {
        if missedSurface { return settings.l10n.arNeedSurface }
        switch (mode, points.count) {
        case (.distance, 0), (.area, 0):
            return settings.l10n.arTapFirst
        case (.distance, 1):
            return settings.l10n.arTapSecond
        case (.area, 1):
            return settings.l10n.arTapWidth
        case (.area, 2):
            return settings.l10n.arTapHeight
        default:
            return settings.l10n.arDone
        }
    }

    private var readoutValue: String {
        mode == .distance ? distanceText : areaText
    }

    private var readoutUnit: String {
        mode == .distance ? lengthUnit : areaUnit
    }

    private var measurementLabel: String {
        guard readoutValue != "—" else { return "" }
        return readoutValue + " " + readoutUnit
    }

    private func unitTitle(_ choice: MeasureDisplayUnit) -> String {
        switch mode {
        case .distance:
            switch choice {
            case .centimeters: return settings.l10n.unitCentimeter
            case .meters: return settings.l10n.unitMeter
            case .inches: return settings.l10n.unitInch
            case .feet: return settings.l10n.unitFoot
            }
        case .area:
            switch choice {
            case .centimeters: return settings.l10n.unitSquareCentimeter
            case .meters: return settings.l10n.unitSquareMeter
            case .inches: return settings.l10n.unitSquareInch
            case .feet: return settings.l10n.unitSquareFoot
            }
        }
    }

    private var distanceText: String {
        guard points.count >= 2, let meters = MeasureMath.distanceMeters(points[0], points[1]) else { return "—" }
        return lengthText(meters)
    }

    private var areaText: String {
        guard let rectangle,
              let area = unit.area(fromSquareMeters: rectangle.areaSquareMeters) else { return "—" }
        return MeasurementFormat.fixed(area, fractionDigits: areaDigits, locale: locale)
    }

    private func lengthText(_ meters: Double) -> String {
        guard let converted = unit.length(fromMeters: meters) else { return "—" }
        return MeasurementFormat.fixed(converted, fractionDigits: lengthDigits, locale: locale)
    }

    private var lengthUnit: String {
        switch unit {
        case .centimeters: return settings.l10n.unitCentimeter
        case .meters: return settings.l10n.unitMeter
        case .inches: return settings.l10n.unitInch
        case .feet: return settings.l10n.unitFoot
        }
    }

    private var areaUnit: String {
        switch unit {
        case .centimeters: return settings.l10n.unitSquareCentimeter
        case .meters: return settings.l10n.unitSquareMeter
        case .inches: return settings.l10n.unitSquareInch
        case .feet: return settings.l10n.unitSquareFoot
        }
    }

    private var lengthDigits: Int {
        switch unit {
        case .centimeters: return 1
        case .meters: return 3
        case .inches, .feet: return 2
        }
    }

    private var areaDigits: Int {
        switch unit {
        case .centimeters: return 1
        case .meters: return 3
        case .inches: return 1
        case .feet: return 2
        }
    }

    private func addPoint(_ point: WorldPoint) {
        guard points.count < mode.pointLimit else { return }
        missedSurface = false
        points.append(point)
        settings.triggerFeedback(impact: .light)
    }

    private func permissionCard(message: String, systemImage: String) -> some View {
        SensorStatusCard(
            systemImage: systemImage,
            title: settings.l10n.toolARTitle,
            message: message,
            actionTitle: settings.l10n.openSettings,
            action: {
                settings.triggerFeedback()
                openAppSettings()
            }
        )
        .padding(16)
    }
}

// MARK: - Camera

private struct MeasureSnapshot: Equatable {
    var markers: [WorldPoint]
    var corners: [WorldPoint]
    var lineOptions: MeasureLineOptions
}

private struct MeasureCamera: UIViewRepresentable {
    var running: Bool
    var markers: [WorldPoint]
    var corners: [WorldPoint]
    var hasLabel: Bool
    var lineOptions: MeasureLineOptions
    var onPoint: (WorldPoint) -> Void
    var onMiss: () -> Void
    var onLabelPoint: (CGPoint?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        let coaching = ARCoachingOverlayView()
        coaching.session = view.session
        coaching.goal = .anyPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(coaching)
        let proxy = MeasureTapProxy()
        let tap = UITapGestureRecognizer(target: proxy, action: #selector(MeasureTapProxy.tapped(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.attach(view: view, proxy: proxy)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.onPoint = onPoint
        context.coordinator.onMiss = onMiss
        context.coordinator.onLabelScreenPoint = onLabelPoint
        context.coordinator.reportsLabel = hasLabel
        context.coordinator.render(
            MeasureSnapshot(markers: markers, corners: corners, lineOptions: lineOptions)
        )
        if running {
            context.coordinator.start()
        } else {
            context.coordinator.pause()
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    @MainActor
    final class Coordinator {
        var onPoint: ((WorldPoint) -> Void)?
        var onMiss: (() -> Void)?
        var onLabelScreenPoint: ((CGPoint?) -> Void)?
        var reportsLabel = false
        private var view: ARView?
        private var proxy: MeasureTapProxy?
        private var running = false
        private var rendered: MeasureSnapshot?
        private var anchors: [AnchorEntity] = []
        private var labelWorld: SIMD3<Float>?
        private var lastPublished: CGPoint?
        private var updateSubscription: (any Cancellable)?

        func attach(view: ARView, proxy: MeasureTapProxy) {
            self.view = view
            self.proxy = proxy
            proxy.onPoint = { [weak self] vector in
                let point = WorldPoint(x: Double(vector.x), y: Double(vector.y), z: Double(vector.z))
                self?.onPoint?(point)
            }
            proxy.onMiss = { [weak self] in
                self?.onMiss?()
            }
            updateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                Task { @MainActor in
                    self?.publishLabelPoint()
                }
            }
        }

        func teardown() {
            pause()
            updateSubscription?.cancel()
            updateSubscription = nil
        }

        func start() {
            guard let view, !running else { return }
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            running = true
        }

        func pause() {
            guard running else { return }
            view?.session.pause()
            running = false
        }

        func render(_ snapshot: MeasureSnapshot) {
            guard let view, rendered != snapshot else { return }
            rendered = snapshot
            for anchor in anchors {
                view.scene.removeAnchor(anchor)
            }
            anchors.removeAll()
            let drawn = snapshot.corners.isEmpty ? snapshot.markers : snapshot.corners
            let color = snapshot.lineOptions.color.uiColor
            let width = snapshot.lineOptions.thickness.widthMeters
            let radius = snapshot.lineOptions.thickness.endpointRadiusMeters
            let camera = view.cameraTransform.translation
            for point in drawn {
                anchors.append(makeEndpoint(at: point, radius: radius, camera: camera))
            }
            if drawn.count >= 2 {
                for index in 0..<(drawn.count - 1) {
                    anchors.append(contentsOf: makeLine(from: drawn[index], to: drawn[index + 1], width: width, color: color))
                }
                if drawn.count >= 4 {
                    anchors.append(contentsOf: makeLine(from: drawn[3], to: drawn[0], width: width, color: color))
                }
            }
            if reportsLabel, drawn.count >= 2, let center = average(of: drawn) {
                labelWorld = center.vector
            } else {
                labelWorld = nil
                lastPublished = nil
            }
            for anchor in anchors {
                view.scene.addAnchor(anchor)
            }
            publishLabelPoint()
        }

        func publishLabelPoint() {
            guard let view else { return }
            let point = labelWorld.flatMap { view.project($0) }
            if let point, let lastPublished,
               abs(point.x - lastPublished.x) < 1.5,
               abs(point.y - lastPublished.y) < 1.5 {
                return
            }
            lastPublished = point
            onLabelScreenPoint?(point)
        }

        /// White fill with an accent-blue ring, turned toward the camera.
        private func makeEndpoint(at point: WorldPoint, radius: Float, camera: SIMD3<Float>) -> AnchorEntity {
            let anchor = AnchorEntity(world: point.vector)
            let towardCamera = camera - point.vector
            if simd_length(towardCamera) > 0.05 {
                anchor.orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: simd_normalize(towardCamera))
            }
            let ring = ModelEntity(
                mesh: .generateCylinder(height: 0.0014, radius: radius * 1.42),
                materials: [unlit(.systemBlue)]
            )
            let fill = ModelEntity(
                mesh: .generateCylinder(height: 0.0014, radius: radius),
                materials: [unlit(.white)]
            )
            fill.position.y = 0.0016
            anchor.addChild(ring)
            anchor.addChild(fill)
            return anchor
        }

        /// A thin white edge around the colored core so the line stays visible without a heavy outline.
        private func makeLine(from start: WorldPoint, to end: WorldPoint, width: Float, color: UIColor) -> [AnchorEntity] {
            [
                tube(from: start, to: end, width: width * 1.35, color: .white),
                tube(from: start, to: end, width: width, color: color)
            ].compactMap { $0 }
        }

        private func tube(from start: WorldPoint, to end: WorldPoint, width: Float, color: UIColor) -> AnchorEntity? {
            let delta = end.vector - start.vector
            let length = simd_length(delta)
            guard length > 0.001 else { return nil }
            let box = ModelEntity(
                mesh: .generateBox(width: width, height: width, depth: length),
                materials: [unlit(color)]
            )
            box.orientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: simd_normalize(delta))
            let anchor = AnchorEntity(world: (start.vector + end.vector) / 2)
            anchor.addChild(box)
            return anchor
        }

        private func unlit(_ color: UIColor) -> UnlitMaterial {
            var material = UnlitMaterial()
            material.color = .init(tint: color)
            return material
        }

        private func average(of points: [WorldPoint]) -> WorldPoint? {
            guard !points.isEmpty else { return nil }
            let count = Double(points.count)
            return WorldPoint(
                x: points.reduce(0) { $0 + $1.x } / count,
                y: points.reduce(0) { $0 + $1.y } / count,
                z: points.reduce(0) { $0 + $1.z } / count
            )
        }
    }
}

private struct MeasureLineOptionsSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                Text(settings.l10n.arLineColor)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 12)], spacing: 12) {
                    ForEach(MeasureLineColor.allCases, id: \.self) { color in
                        Button {
                            settings.measureLineOptions.color = color
                            settings.triggerFeedback(impact: .light)
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color(uiColor: color.uiColor))
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.black.opacity(0.45), lineWidth: 2))
                                    .overlay {
                                        if settings.measureLineOptions.color == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundColor(color == .white || color == .yellow ? .black : .white)
                                        }
                                    }
                                Text(color.title(using: settings.l10n))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.title(using: settings.l10n))
                    }
                }

                Text(settings.l10n.arLineThickness)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Picker(settings.l10n.arLineThickness, selection: thicknessBinding) {
                    Text(settings.l10n.arThicknessThin).tag(MeasureLineThickness.thin)
                    Text(settings.l10n.arThicknessMedium).tag(MeasureLineThickness.medium)
                    Text(settings.l10n.arThicknessThick).tag(MeasureLineThickness.thick)
                }
                .pickerStyle(.segmented)

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(NeonAmbientBackground())
            .navigationTitle(settings.l10n.arLineOptions)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.l10n.done) { dismiss() }
                }
            }
        }
    }

    private var thicknessBinding: Binding<MeasureLineThickness> {
        Binding(
            get: { settings.measureLineOptions.thickness },
            set: { settings.measureLineOptions.thickness = $0 }
        )
    }
}

private extension MeasureLineColor {
    var uiColor: UIColor {
        switch self {
        case .yellow: return UIColor(red: 1, green: 0.92, blue: 0.05, alpha: 1)
        case .white: return .white
        case .red: return UIColor(red: 1, green: 0.16, blue: 0.16, alpha: 1)
        case .green: return UIColor(red: 0.15, green: 0.95, blue: 0.3, alpha: 1)
        case .blue: return .systemBlue
        }
    }

    func title(using l10n: L10n) -> String {
        switch self {
        case .yellow: return l10n.arColorYellow
        case .white: return l10n.arColorWhite
        case .red: return l10n.arColorRed
        case .green: return l10n.arColorGreen
        case .blue: return l10n.arColorBlue
        }
    }
}

@MainActor
private final class MeasureTapProxy: NSObject {
    var onPoint: ((SIMD3<Float>) -> Void)?
    var onMiss: (() -> Void)?

    /// UIKit calls this on the main thread. It stays nonisolated so it can be @objc.
    @objc nonisolated func tapped(_ recognizer: UITapGestureRecognizer) {
        MainActor.assumeIsolated {
            self.handleTap(recognizer)
        }
    }

    private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let view = recognizer.view as? ARView else { return }
        let location = recognizer.location(in: view)
        if let hit = view.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
            ?? view.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any).first {
            let column = hit.worldTransform.columns.3
            onPoint?(SIMD3(column.x, column.y, column.z))
        } else {
            onMiss?()
        }
    }
}

private extension WorldPoint {
    var vector: SIMD3<Float> {
        SIMD3(Float(x), Float(y), Float(z))
    }
}
