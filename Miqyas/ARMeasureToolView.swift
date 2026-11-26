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
        .onAppear { model.start() }
        .onDisappear { model.stop() }
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
                onPoint: addPoint,
                onMiss: { missedSurface = true }
            )
            .ignoresSafeArea(edges: .bottom)

            panel
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
        }
    }

    private var panel: some View {
        VStack(spacing: 12) {
            Picker(settings.l10n.toolARTitle, selection: $mode) {
                Text(settings.l10n.arDistanceMode).tag(ARMeasureMode.distance)
                Text(settings.l10n.arAreaMode).tag(ARMeasureMode.area)
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, _ in
                points = []
                missedSurface = false
            }

            Picker(settings.l10n.unitMeter, selection: $unit) {
                Text(settings.l10n.unitCentimeter).tag(MeasureDisplayUnit.centimeters)
                Text(settings.l10n.unitMeter).tag(MeasureDisplayUnit.meters)
                Text(settings.l10n.unitInch).tag(MeasureDisplayUnit.inches)
                Text(settings.l10n.unitFoot).tag(MeasureDisplayUnit.feet)
            }
            .pickerStyle(.segmented)

            if mode == .distance {
                ToolValueReadout(
                    value: distanceText,
                    unit: lengthUnit,
                    caption: settings.l10n.arDistanceMode
                )
            } else {
                ToolValueReadout(
                    value: areaText,
                    unit: areaUnit,
                    caption: settings.l10n.arArea
                )
                if let rectangle {
                    HStack(spacing: 10) {
                        ToolStatPill(title: settings.l10n.arWidth, value: lengthText(rectangle.widthMeters))
                        ToolStatPill(title: settings.l10n.arHeight, value: lengthText(rectangle.heightMeters))
                    }
                }
            }

            Text(hint)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            ToolActionButton(
                title: settings.l10n.arClear,
                systemImage: "arrow.counterclockwise",
                prominent: false
            ) {
                settings.triggerFeedback()
                points = []
                missedSurface = false
            }
        }
        .padding(16)
        .toolGlass(cornerRadius: 24)
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
}

private struct MeasureCamera: UIViewRepresentable {
    var running: Bool
    var markers: [WorldPoint]
    var corners: [WorldPoint]
    var onPoint: (WorldPoint) -> Void
    var onMiss: () -> Void

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
        context.coordinator.render(MeasureSnapshot(markers: markers, corners: corners))
        if running {
            context.coordinator.start()
        } else {
            context.coordinator.pause()
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.pause()
    }

    @MainActor
    final class Coordinator {
        var onPoint: ((WorldPoint) -> Void)?
        var onMiss: (() -> Void)?
        private var view: ARView?
        private var proxy: MeasureTapProxy?
        private var running = false
        private var rendered: MeasureSnapshot?
        private var anchors: [AnchorEntity] = []

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
            let color = snapshot.corners.isEmpty ? UIColor.systemCyan : UIColor.systemGreen
            for point in drawn {
                anchors.append(makeSphere(at: point, color: color))
            }
            if drawn.count >= 2 {
                for index in 0..<(drawn.count - 1) {
                    if let line = makeLine(from: drawn[index], to: drawn[index + 1], color: color) {
                        anchors.append(line)
                    }
                }
                if drawn.count >= 4, let closing = makeLine(from: drawn[3], to: drawn[0], color: color) {
                    anchors.append(closing)
                }
            }
            for anchor in anchors {
                view.scene.addAnchor(anchor)
            }
        }

        private func makeSphere(at point: WorldPoint, color: UIColor) -> AnchorEntity {
            let material = SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.008), materials: [material])
            let anchor = AnchorEntity(world: point.vector)
            anchor.addChild(sphere)
            return anchor
        }

        private func makeLine(from start: WorldPoint, to end: WorldPoint, color: UIColor) -> AnchorEntity? {
            let delta = end.vector - start.vector
            let length = simd_length(delta)
            guard length > 0.001 else { return nil }
            let material = SimpleMaterial(color: color, roughness: 0.4, isMetallic: false)
            let box = ModelEntity(
                mesh: .generateBox(width: 0.004, height: 0.004, depth: length),
                materials: [material]
            )
            box.orientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: simd_normalize(delta))
            let anchor = AnchorEntity(world: (start.vector + end.vector) / 2)
            anchor.addChild(box)
            return anchor
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
