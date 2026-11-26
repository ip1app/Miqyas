import SwiftUI
import AVFoundation
import Combine

// MARK: - Sound meter

private enum SoundAccess: Equatable {
    case idle
    case denied
    case unavailable
    case failed
    case measuring
}

private enum SoundMeterError: Error {
    case unavailable
}

/// Lock-protected samples. The audio tap writes here; the main actor reads.
nonisolated final class SoundAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var aggregate: SoundAggregate?
    private var latest: Double?

    func add(_ decibels: Double) {
        guard decibels.isFinite else { return }
        lock.lock()
        if var current = aggregate {
            current.add(decibels)
            aggregate = current
        } else {
            aggregate = SoundAggregate(sample: decibels)
        }
        latest = decibels
        lock.unlock()
    }

    func snapshot() -> (current: Double, aggregate: SoundAggregate)? {
        lock.lock()
        defer { lock.unlock() }
        guard let latest, let aggregate else { return nil }
        return (latest, aggregate)
    }

    func reset() {
        lock.lock()
        aggregate = nil
        latest = nil
        lock.unlock()
    }
}

@MainActor
final class SoundMeterEngine {
    let accumulator = SoundAccumulator()
    private let engine = AVAudioEngine()
    private var tapInstalled = false
    private var sessionActive = false

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .defaultToSpeaker])
        try session.setActive(true)
        sessionActive = true
        try? session.setAllowHapticsAndSystemSoundsDuringRecording(true)
        guard session.isInputAvailable else { throw SoundMeterError.unavailable }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw SoundMeterError.unavailable
        }

        if tapInstalled {
            input.removeTap(onBus: 0)
            tapInstalled = false
        }

        let sink = accumulator
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
            guard let decibels = meterDecibels(from: buffer) else { return }
            sink.add(SoundLevelMath.approximateDecibels(dbfs: decibels))
        }
        tapInstalled = true
        engine.prepare()
        do {
            try engine.start()
        } catch {
            if tapInstalled {
                input.removeTap(onBus: 0)
                tapInstalled = false
            }
            throw error
        }
    }

    func stop() {
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        if engine.isRunning {
            engine.stop()
        }
        if sessionActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            sessionActive = false
        }
    }
}

nonisolated func meterDecibels(from buffer: AVAudioPCMBuffer) -> Double? {
    let count = Int(buffer.frameLength)
    guard count > 0 else { return nil }
    if let channels = buffer.floatChannelData {
        let samples = UnsafeBufferPointer(start: channels[0], count: count)
        return SoundLevelMath.decibelsFullScale(rms: SoundLevelMath.rootMeanSquare(samples))
    }
    if let channels = buffer.int16ChannelData {
        let samples = UnsafeBufferPointer(start: channels[0], count: count)
        return SoundLevelMath.decibelsFullScale(rms: SoundLevelMath.rootMeanSquare(int16: samples))
    }
    return nil
}

@MainActor
final class SoundMeterModel: ObservableObject {
    @Published private(set) var access: SoundAccess = .idle
    @Published private(set) var current: Double?
    @Published private(set) var aggregate: SoundAggregate?

    private let engine = SoundMeterEngine()
    private var pullTask: Task<Void, Never>?
    private var wantsRunning = false
    private var engineRunning = false
    private var permissionRequestInFlight = false
    private var smoothed: Double?

    init() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            // Show the gauge immediately; samples arrive once the engine starts.
            access = .measuring
        case .denied:
            access = .denied
        case .undetermined:
            access = .idle
        @unknown default:
            access = .denied
        }
    }

    func start() {
        wantsRunning = true
        resume()
    }

    func stop() {
        wantsRunning = false
        tearDownEngine()
    }

    func reset() {
        engine.accumulator.reset()
        smoothed = nil
        current = nil
        aggregate = nil
    }

    private func resume() {
        guard wantsRunning else { return }
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            beginEngine()
        case .denied:
            tearDownEngine()
            access = .denied
        case .undetermined:
            requestPermission()
        @unknown default:
            tearDownEngine()
            access = .denied
        }
    }

    private func requestPermission() {
        guard !permissionRequestInFlight else { return }
        permissionRequestInFlight = true
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                self.permissionRequestInFlight = false
                guard self.wantsRunning else { return }
                if granted {
                    self.beginEngine()
                } else {
                    self.tearDownEngine()
                    self.access = .denied
                }
            }
        }
    }

    private func beginEngine() {
        guard wantsRunning, !engineRunning else { return }
        do {
            try engine.start()
            engineRunning = true
            access = .measuring
            startPull()
        } catch SoundMeterError.unavailable {
            tearDownEngine()
            access = .unavailable
        } catch {
            tearDownEngine()
            access = .failed
        }
    }

    private func tearDownEngine() {
        pullTask?.cancel()
        pullTask = nil
        engine.stop()
        engineRunning = false
    }

    private func startPull() {
        pullTask?.cancel()
        pullTask = Task { @MainActor in
            while !Task.isCancelled {
                if let snapshot = self.engine.accumulator.snapshot() {
                    if let smoothed = self.smoothed {
                        self.smoothed = smoothed * 0.65 + snapshot.current * 0.35
                    } else {
                        self.smoothed = snapshot.current
                    }
                    self.current = self.smoothed
                    self.aggregate = snapshot.aggregate
                }
                try? await Task.sleep(nanoseconds: 66_000_000)
            }
        }
    }
}

struct SoundMeterToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = SoundMeterModel()

    private var locale: Locale { Locale(identifier: settings.appLanguage.rawValue) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                switch model.access {
                case .denied:
                    SensorStatusCard(
                        systemImage: "mic.slash.fill",
                        title: settings.l10n.toolSoundTitle,
                        message: settings.l10n.soundMicDenied,
                        actionTitle: settings.l10n.openSettings,
                        action: {
                            settings.triggerFeedback()
                            openAppSettings()
                        }
                    )
                case .unavailable:
                    SensorStatusCard(
                        systemImage: "mic.slash",
                        title: settings.l10n.toolSoundTitle,
                        message: settings.l10n.soundMicUnavailable,
                        actionTitle: settings.l10n.tryAgain,
                        actionSystemImage: "arrow.clockwise",
                        action: {
                            settings.triggerFeedback()
                            model.start()
                        }
                    )
                case .failed:
                    SensorStatusCard(
                        systemImage: "exclamationmark.triangle.fill",
                        title: settings.l10n.toolSoundTitle,
                        message: settings.l10n.soundFailed,
                        actionTitle: settings.l10n.tryAgain,
                        actionSystemImage: "arrow.clockwise",
                        action: {
                            settings.triggerFeedback()
                            model.start()
                        }
                    )
                case .idle:
                    SensorStatusCard(
                        systemImage: "mic.fill",
                        title: settings.l10n.toolSoundTitle,
                        message: settings.l10n.soundPromptMessage
                    )
                case .measuring:
                    meter
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(NeonAmbientBackground())
        .navigationTitle(settings.l10n.toolSoundTitle)
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

    private var meter: some View {
        VStack(spacing: 18) {
            SoundGauge(decibels: model.current)
                .frame(height: 180)
                .padding(.horizontal, 12)

            VStack(spacing: 4) {
                Text(currentText)
                    .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.primary)
                    .environment(\.layoutDirection, .leftToRight)
                Text(settings.l10n.soundDecibelUnit)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(settings.l10n.soundApproximateLabel)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                if model.current == nil {
                    Text(settings.l10n.soundMeasuring)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                statPill(title: settings.l10n.soundMin, value: model.aggregate?.minimum)
                statPill(title: settings.l10n.soundAvg, value: model.aggregate?.energyAverage)
                statPill(title: settings.l10n.soundMax, value: model.aggregate?.maximum)
            }

            ToolActionButton(title: settings.l10n.soundReset, systemImage: "arrow.counterclockwise", prominent: false) {
                settings.triggerFeedback()
                model.reset()
            }
        }
    }

    private func statPill(title: String, value: Double?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(valueText(value))
                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundColor(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .toolGlass(cornerRadius: 16)
    }

    private var currentText: String {
        guard let current = model.current else { return "—" }
        return MeasurementFormat.fixed(current, fractionDigits: 0, locale: locale)
    }

    private func valueText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return MeasurementFormat.fixed(value, fractionDigits: 0, locale: locale)
    }
}

private struct SoundGauge: View {
    var decibels: Double?

    /// 0 is the left end of the arc (about 30 dB) and 1 is the right end (about 110 dB).
    private var fraction: Double {
        guard let decibels else { return 0 }
        let clamped = min(110, max(30, decibels))
        return (clamped - 30) / 80
    }

    private var tint: Color {
        guard let decibels else { return .secondary }
        switch decibels {
        case ..<60: return .green
        case ..<80: return .yellow
        case ..<95: return .orange
        default: return .red
        }
    }

    var body: some View {
        Canvas { context, size in
            let radius = min(size.width / 2 - 16, size.height - 24)
            guard radius > 8 else { return }
            let center = CGPoint(x: size.width / 2, y: radius + 14)
            let track = gaugePath(center: center, radius: radius, from: 0, to: 1)
            context.stroke(
                track,
                with: .color(Color.primary.opacity(0.1)),
                style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
            )
            if fraction > 0.002 {
                let level = gaugePath(center: center, radius: radius, from: 0, to: fraction)
                context.stroke(
                    level,
                    with: .color(tint),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                )
            }

            // 0 fraction points left, 1 points right, 0.5 points up.
            let theta = Double.pi * (1 - fraction)
            let needleLength = radius - 26
            let tip = CGPoint(
                x: center.x + CGFloat(cos(theta)) * needleLength,
                y: center.y - CGFloat(sin(theta)) * needleLength
            )
            var needle = Path()
            needle.move(to: center)
            needle.addLine(to: tip)
            context.stroke(needle, with: .color(tint), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            let hub = Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12))
            context.fill(hub, with: .color(Color.primary))
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    /// Upper semicircle. Fraction 0 is left (π) and 1 is right (0), passing through the top.
    private func gaugePath(center: CGPoint, radius: CGFloat, from startFraction: Double, to endFraction: Double) -> Path {
        var path = Path()
        let steps = 48
        let start = Double.pi * (1 - startFraction)
        let end = Double.pi * (1 - endFraction)
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let theta = start + (end - start) * t
            let point = CGPoint(
                x: center.x + CGFloat(cos(theta)) * radius,
                y: center.y - CGFloat(sin(theta)) * radius
            )
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}
