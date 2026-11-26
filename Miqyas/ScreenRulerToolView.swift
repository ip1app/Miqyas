import SwiftUI
import Darwin

// MARK: - Screen ruler

fileprivate enum RulerUnit: String, CaseIterable, Identifiable {
    case centimeters
    case inches

    var id: String { rawValue }
}

fileprivate enum RulerAxis: String, CaseIterable, Identifiable {
    case horizontal
    case vertical

    var id: String { rawValue }
}

enum DeviceMachine {
    static func identifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}

struct ScreenRulerToolView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var unit: RulerUnit = .centimeters
    @State private var axis: RulerAxis = .horizontal
    @State private var markerPoints: CGFloat = 0
    @State private var didPlaceMarker = false
    @State private var pointsPerInch: Double = 460 / 3

    private var locale: Locale { Locale(identifier: settings.appLanguage.rawValue) }

    var body: some View {
        VStack(spacing: 14) {
            Picker(settings.l10n.toolRulerTitle, selection: $unit) {
                Text(settings.l10n.rulerCentimeters).tag(RulerUnit.centimeters)
                Text(settings.l10n.rulerInches).tag(RulerUnit.inches)
            }
            .pickerStyle(.segmented)

            Picker(settings.l10n.rulerHorizontal, selection: $axis) {
                Text(settings.l10n.rulerHorizontal).tag(RulerAxis.horizontal)
                Text(settings.l10n.rulerVertical).tag(RulerAxis.vertical)
            }
            .pickerStyle(.segmented)

            ToolValueReadout(
                value: lengthText(points: markerPoints),
                unit: unit == .centimeters ? settings.l10n.unitCentimeter : settings.l10n.unitInch,
                caption: settings.l10n.rulerMarker
            )

            Text(screenSizeText)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .environment(\.layoutDirection, .leftToRight)

            GeometryReader { geo in
                let vertical = axis == .vertical
                let span = vertical ? geo.size.height : geo.size.width
                ruler(span: span, vertical: vertical)
                    .onAppear { placeMarkerIfNeeded(span: span) }
                    .onChange(of: span) { _, newSpan in
                        markerPoints = min(max(0, markerPoints), measuredSpan(newSpan))
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ToolHintText(text: settings.l10n.rulerHint)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 110)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NeonAmbientBackground())
        .navigationTitle(settings.l10n.toolRulerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { pointsPerInch = resolvedPointsPerInch() }
        .onChange(of: axis) { _, _ in
            didPlaceMarker = false
            settings.triggerFeedback(impact: .light)
        }
        .onChange(of: unit) { _, _ in
            settings.triggerFeedback(impact: .light)
        }
    }

    private func ruler(span: CGFloat, vertical: Bool) -> some View {
        let origin = RulerDrawing.origin
        let pointsPerUnit = CGFloat(points(for: unit == .centimeters ? 1 : 2.54) ?? 60)
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
            RulerDrawing(
                vertical: vertical,
                pointsPerUnit: max(pointsPerUnit, 1),
                subdivisions: unit == .centimeters ? 10 : 8
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)

            Rectangle()
                .fill(Color.orange)
                .frame(width: vertical ? nil : 3, height: vertical ? 3 : nil)
                .frame(maxWidth: vertical ? .infinity : 3, maxHeight: vertical ? 3 : .infinity)
                .offset(
                    x: vertical ? 0 : origin + markerPoints - 1.5,
                    y: vertical ? origin + markerPoints - 1.5 : 0
                )
                .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let location = vertical ? value.location.y : value.location.x
                    let measured = location - origin
                    markerPoints = min(max(0, measured), measuredSpan(span))
                }
        )
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.l10n.toolRulerTitle)
        .accessibilityValue(lengthText(points: markerPoints))
    }

    private func placeMarkerIfNeeded(span: CGFloat) {
        guard !didPlaceMarker, span > 1 else { return }
        didPlaceMarker = true
        let fiveCentimeters = CGFloat(points(for: 5) ?? 80)
        markerPoints = min(fiveCentimeters, measuredSpan(span))
    }

    private func measuredSpan(_ span: CGFloat) -> CGFloat {
        max(0, span - RulerDrawing.origin - 16)
    }

    /// Centimeters along the screen, converted from the ruler's point length.
    private func points(for centimeters: Double) -> Double? {
        ScreenRulerMath.points(centimeters: centimeters, pointsPerInch: pointsPerInch)
    }

    private func lengthText(points: CGFloat) -> String {
        let value: Double?
        let digits: Int
        if unit == .centimeters {
            value = ScreenRulerMath.centimeters(points: Double(points), pointsPerInch: pointsPerInch)
            digits = 1
        } else {
            value = ScreenRulerMath.inches(points: Double(points), pointsPerInch: pointsPerInch)
            digits = 2
        }
        guard let value else { return "—" }
        return MeasurementFormat.fixed(value, fractionDigits: digits, locale: locale)
    }

    private var screenSizeText: String {
        let bounds = activeScreen()?.bounds ?? CGRect(x: 0, y: 0, width: 0, height: 0)
        let width = lengthText(points: bounds.width)
        let height = lengthText(points: bounds.height)
        let symbol = unit == .centimeters ? settings.l10n.unitCentimeter : settings.l10n.unitInch
        return "\(settings.l10n.rulerScreenSize) \(width) × \(height) \(symbol)"
    }

    private func resolvedPointsPerInch() -> Double {
        let scale = activeScreen()?.nativeScale ?? 3
        let pixels = ScreenRulerMath.pixelsPerInch(
            modelIdentifier: DeviceMachine.identifier(),
            screenScale: scale
        )
        return ScreenRulerMath.pointsPerInch(pixelsPerInch: pixels, screenScale: scale) ?? (pixels / max(scale, 1))
    }
}

private func activeScreen() -> UIScreen? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let active = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    return active?.screen
}

private struct RulerDrawing: View {
    static let origin: CGFloat = 18

    var vertical: Bool
    var pointsPerUnit: CGFloat
    var subdivisions: Int

    var body: some View {
        Canvas { context, size in
            let limit = (vertical ? size.height : size.width) - 16
            var step = 0
            var position = Self.origin
            while position <= limit + 0.5 {
                let isMajor = step % subdivisions == 0
                let isHalf = !isMajor && subdivisions % 2 == 0 && step % (subdivisions / 2) == 0
                let tick = tickLength(major: isMajor, half: isHalf)
                var path = Path()
                if vertical {
                    path.move(to: CGPoint(x: 16, y: position))
                    path.addLine(to: CGPoint(x: 16 + tick, y: position))
                } else {
                    path.move(to: CGPoint(x: position, y: 16))
                    path.addLine(to: CGPoint(x: position, y: 16 + tick))
                }
                context.stroke(
                    path,
                    with: .color(Color.primary.opacity(isMajor ? 0.85 : 0.45)),
                    style: StrokeStyle(lineWidth: isMajor ? 2 : 1, lineCap: .round)
                )
                if isMajor {
                    let majorIndex = step / subdivisions
                    let label = Text("\(majorIndex)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    let resolved = context.resolve(label)
                    let point = vertical
                        ? CGPoint(x: 16 + tick + 8, y: position)
                        : CGPoint(x: position, y: 16 + tick + 8)
                    context.draw(resolved, at: point, anchor: vertical ? .leading : .top)
                }
                step += 1
                position = Self.origin + CGFloat(step) * pointsPerUnit / CGFloat(subdivisions)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    private func tickLength(major: Bool, half: Bool) -> CGFloat {
        if major { return 34 }
        if half { return 22 }
        return 12
    }
}
