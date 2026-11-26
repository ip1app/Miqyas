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
                label: measurementLabel,
                lineOptions: settings.measureLineOptions,
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
                measurementLabelPlate(
                    value: distanceText,
                    unit: lengthUnit,
                    caption: settings.l10n.arDistanceMode
                )
            } else {
                measurementLabelPlate(
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

    private var measurementLabel: String {
        if mode == .distance {
            guard distanceText != "—" else { return "" }
            return distanceText + " " + lengthUnit
        }
        guard areaText != "—" else { return "" }
        return areaText + " " + areaUnit
    }

    private func measurementLabelPlate(value: String, unit: String, caption: String) -> some View {
        ToolValueReadout(value: value, unit: unit, caption: caption, tint: .yellow)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
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
    var label: String
    var lineOptions: MeasureLineOptions
}

private struct MeasureCamera: UIViewRepresentable {
    var running: Bool
    var markers: [WorldPoint]
    var corners: [WorldPoint]
    var label: String
    var lineOptions: MeasureLineOptions
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
        context.coordinator.render(
            MeasureSnapshot(markers: markers, corners: corners, label: label, lineOptions: lineOptions)
        )
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
            let color = snapshot.lineOptions.color.uiColor
            let width = snapshot.lineOptions.thickness.widthMeters
            let radius = snapshot.lineOptions.thickness.endpointRadiusMeters
            for point in drawn {
                anchors.append(makeSphere(at: point, radius: radius, color: color))
            }
            if drawn.count >= 2 {
                for index in 0..<(drawn.count - 1) {
                    anchors.append(contentsOf: makeLine(from: drawn[index], to: drawn[index + 1], width: width, color: color))
                }
                if drawn.count >= 4 {
                    anchors.append(contentsOf: makeLine(from: drawn[3], to: drawn[0], width: width, color: color))
                }
            }
            if !snapshot.label.isEmpty, let center = average(of: drawn) {
                let camera = view.cameraTransform.translation
                if let labelAnchor = makeLabel(snapshot.label, at: center, facing: camera, color: color) {
                    anchors.append(labelAnchor)
                }
            }
            for anchor in anchors {
                view.scene.addAnchor(anchor)
            }
        }

        private func makeSphere(at point: WorldPoint, radius: Float, color: UIColor) -> AnchorEntity {
            let sphere = ModelEntity(
                mesh: .generateSphere(radius: radius),
                materials: [unlit(color)]
            )
            let anchor = AnchorEntity(world: point.vector)
            anchor.addChild(sphere)
            return anchor
        }

        /// A dark tube slightly wider than the colored core, so the line stays readable on any surface.
        private func makeLine(from start: WorldPoint, to end: WorldPoint, width: Float, color: UIColor) -> [AnchorEntity] {
            let outline = width * 1.85
            return [
                tube(from: start, to: end, width: outline, color: UIColor.black.withAlphaComponent(0.92)),
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

        private func makeLabel(_ text: String, at point: WorldPoint, facing camera: SIMD3<Float>, color: UIColor) -> AnchorEntity? {
            let font = UIFont.systemFont(ofSize: 0.06, weight: .heavy)
            guard let mesh = try? MeshResource.generateText(
                text,
                extrusionDepth: 0.002,
                font: font,
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byClipping
            ) else { return nil }

            let bounds = mesh.bounds
            let textEntity = ModelEntity(mesh: mesh, materials: [unlit(color)])
            textEntity.position = SIMD3(
                -(bounds.center.x),
                -(bounds.center.y),
                0.006
            )

            let pad: Float = 0.016
            let plate = ModelEntity(
                mesh: .generateBox(
                    width: max(bounds.extents.x + pad * 2, 0.08),
                    height: max(bounds.extents.y + pad * 2, 0.045),
                    depth: 0.004,
                    cornerRadius: 0.01
                ),
                materials: [unlit(UIColor.black.withAlphaComponent(0.88))]
            )
            let anchor = AnchorEntity(world: point.vector)
            let toCamera = camera - point.vector
            if simd_length(toCamera) > 0.05 {
                anchor.orientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: simd_normalize(toCamera))
            }
            anchor.addChild(plate)
            anchor.addChild(textEntity)
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
        case .blue: return UIColor(red: 0.2, green: 0.55, blue: 1, alpha: 1)
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
