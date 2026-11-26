import SwiftUI
@preconcurrency import AVFoundation
import Combine

// MARK: - Light meter

fileprivate struct ExposureReading: Equatable, Sendable {
    var lux: Double
    var iso: Double
    var aperture: Double
    var exposureSeconds: Double
}

nonisolated fileprivate final class ExposureSink: @unchecked Sendable {
    private let lock = NSLock()
    private var reading: ExposureReading?

    func set(_ reading: ExposureReading) {
        lock.lock()
        self.reading = reading
        lock.unlock()
    }

    func snapshot() -> ExposureReading? {
        lock.lock()
        defer { lock.unlock() }
        return reading
    }
}

/// Reads exposure on the camera queue. The main actor only polls the sink.
nonisolated fileprivate final class ExposureReader: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let device: AVCaptureDevice
    let sink: ExposureSink

    init(device: AVCaptureDevice, sink: ExposureSink) {
        self.device = device
        self.sink = sink
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let iso = Double(device.iso)
        let aperture = Double(device.lensAperture)
        let seconds = device.exposureDuration.seconds
        guard let lux = LuxMath.approximateLux(aperture: aperture, exposureSeconds: seconds, iso: iso) else { return }
        sink.set(ExposureReading(lux: lux, iso: iso, aperture: aperture, exposureSeconds: seconds))
    }
}

nonisolated fileprivate final class LightCapture {
    let session = AVCaptureSession()
    let sink = ExposureSink()
    private let sessionQueue = DispatchQueue(label: "miqyas.light.session")
    private let sampleQueue = DispatchQueue(label: "miqyas.light.samples")
    private var reader: ExposureReader?
    private var configured = false

    func start() throws {
        if !configured {
            try configure()
            configured = true
        }
        let session = self.session
        sessionQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    func stop() {
        let session = self.session
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(for: .video) else {
            throw LightCaptureError.unavailable
        }
        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        }
        guard session.canAddInput(input) else {
            throw LightCaptureError.unavailable
        }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        let reader = ExposureReader(device: device, sink: sink)
        self.reader = reader
        output.setSampleBufferDelegate(reader, queue: sampleQueue)
        guard session.canAddOutput(output) else {
            session.removeInput(input)
            throw LightCaptureError.unavailable
        }
        session.addOutput(output)
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            // The session can still report the current exposure if the lock fails.
        }
    }
}

fileprivate enum LightCaptureError: Error {
    case unavailable
}

fileprivate enum LightAccess: Equatable {
    case needsPermission
    case denied
    case unavailable
    case failed
    case measuring
}

@MainActor
fileprivate final class LightMeterModel: ObservableObject {
    @Published fileprivate var access: LightAccess = .needsPermission
    @Published fileprivate var reading: ExposureReading?

    private let capture = LightCapture()
    private var pullTask: Task<Void, Never>?
    private var wantsRunning = false
    private var engineRunning = false
    private var permissionRequestInFlight = false

    var session: AVCaptureSession { capture.session }

    func start() {
        wantsRunning = true
        guard AVCaptureDevice.default(for: .video) != nil else {
            access = .unavailable
            return
        }
        switch CameraAuthorization.current {
        case .denied:
            tearDown()
            access = .denied
        case .needsPrompt:
            access = .needsPermission
            requestPermission()
        case .allowed:
            beginCapture()
        }
    }

    func stop() {
        wantsRunning = false
        tearDown()
    }

    private func requestPermission() {
        guard !permissionRequestInFlight else { return }
        permissionRequestInFlight = true
        let model = self
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                model.finishPermission(granted)
            }
        }
    }

    private func finishPermission(_ granted: Bool) {
        permissionRequestInFlight = false
        guard wantsRunning else { return }
        if granted {
            beginCapture()
        } else {
            tearDown()
            access = .denied
        }
    }

    private func beginCapture() {
        guard wantsRunning, !engineRunning else { return }
        do {
            try capture.start()
            engineRunning = true
            access = .measuring
            startPull()
        } catch LightCaptureError.unavailable {
            tearDown()
            access = .unavailable
        } catch {
            tearDown()
            access = .failed
        }
    }

    private func tearDown() {
        pullTask?.cancel()
        pullTask = nil
        capture.stop()
        engineRunning = false
    }

    private func startPull() {
        pullTask?.cancel()
        pullTask = Task { @MainActor in
            while !Task.isCancelled {
                if let snapshot = self.capture.sink.snapshot() {
                    self.reading = snapshot
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
}

struct LightMeterToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = LightMeterModel()

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
        .navigationTitle(settings.l10n.toolLightTitle)
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
                systemImage: "camera.fill",
                title: settings.l10n.toolLightTitle,
                message: settings.l10n.cameraDeniedMessage,
                actionTitle: settings.l10n.openSettings,
                action: openSettings
            )
        case .unavailable:
            SensorStatusCard(
                systemImage: "camera.fill",
                title: settings.l10n.toolLightTitle,
                message: settings.l10n.cameraUnavailableMessage
            )
        case .failed:
            SensorStatusCard(
                systemImage: "camera.fill",
                title: settings.l10n.toolLightTitle,
                message: settings.l10n.lightFailed,
                actionTitle: settings.l10n.tryAgain,
                action: {
                    settings.triggerFeedback()
                    model.stop()
                    model.start()
                }
            )
        case .needsPermission:
            SensorStatusCard(
                systemImage: "sun.max.fill",
                title: settings.l10n.toolLightTitle,
                message: settings.l10n.cameraPromptMessage
            )
        case .measuring:
            meter
        }
    }

    private var meter: some View {
        VStack(spacing: 16) {
            CameraPreview(session: model.session, size: previewSize)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
            ToolValueReadout(
                value: luxText,
                unit: settings.l10n.lightLux,
                caption: settings.l10n.approximateReading
            )
            HStack(spacing: 10) {
                ToolStatPill(title: settings.l10n.lightISO, value: whole(model.reading?.iso))
                ToolStatPill(title: settings.l10n.lightShutter, value: shutterText)
                ToolStatPill(title: settings.l10n.lightAperture, value: apertureText)
            }
            ToolHintText(text: settings.l10n.lightHint)
        }
    }

    private var previewSize: CGSize {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let width = (scenes.first?.screen.bounds.width ?? 390) - 32
        return CGSize(width: max(width, 1), height: 220)
    }

    private var luxText: String {
        guard let lux = model.reading?.lux else { return "—" }
        let digits = lux >= 100 ? 0 : 1
        return MeasurementFormat.grouped(lux, fractionDigits: digits, locale: locale)
    }

    private var shutterText: String {
        guard let seconds = model.reading?.exposureSeconds, seconds > 0 else { return "—" }
        if seconds >= 0.1 {
            return MeasurementFormat.fixed(seconds, fractionDigits: 2, locale: locale) + "s"
        }
        let denominator = max(1, Int((1 / seconds).rounded()))
        return "1/\(denominator)"
    }

    private var apertureText: String {
        guard let aperture = model.reading?.aperture, aperture > 0 else { return "—" }
        return "ƒ/" + MeasurementFormat.fixed(aperture, fractionDigits: 1, locale: locale)
    }

    private func whole(_ value: Double?) -> String {
        guard let value else { return "—" }
        return MeasurementFormat.fixed(value, fractionDigits: 0, locale: locale)
    }

    private func openSettings() {
        settings.triggerFeedback()
        openAppSettings()
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var size: CGSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = CGRect(origin: .zero, size: size)
        view.layer.addSublayer(preview)
        context.coordinator.preview = preview
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.preview?.frame = CGRect(origin: .zero, size: size)
    }

    final class Coordinator {
        var preview: AVCaptureVideoPreviewLayer?
    }
}
