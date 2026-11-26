import SwiftUI
import UniformTypeIdentifiers

// MARK: - Tools hub

enum MeasuringTool: String, Hashable, CaseIterable, Identifiable {
    case level
    case compass
    case sound
    case ruler
    case protractor
    case barometer
    case pedometer
    case speedometer
    case light
    case magnetometer
    case seismometer
    case ar

    var id: String { rawValue }

    func title(using l10n: L10n) -> String {
        switch self {
        case .level: return l10n.toolLevelTitle
        case .compass: return l10n.toolCompassTitle
        case .sound: return l10n.toolSoundTitle
        case .ruler: return l10n.toolRulerTitle
        case .protractor: return l10n.toolProtractorTitle
        case .barometer: return l10n.toolBarometerTitle
        case .pedometer: return l10n.toolPedometerTitle
        case .speedometer: return l10n.toolSpeedTitle
        case .light: return l10n.toolLightTitle
        case .magnetometer: return l10n.toolMagnetTitle
        case .seismometer: return l10n.toolSeismoTitle
        case .ar: return l10n.toolARTitle
        }
    }

    func subtitle(using l10n: L10n) -> String {
        switch self {
        case .level: return l10n.toolLevelSubtitle
        case .compass: return l10n.toolCompassSubtitle
        case .sound: return l10n.toolSoundSubtitle
        case .ruler: return l10n.toolRulerSubtitle
        case .protractor: return l10n.toolProtractorSubtitle
        case .barometer: return l10n.toolBarometerSubtitle
        case .pedometer: return l10n.toolPedometerSubtitle
        case .speedometer: return l10n.toolSpeedSubtitle
        case .light: return l10n.toolLightSubtitle
        case .magnetometer: return l10n.toolMagnetSubtitle
        case .seismometer: return l10n.toolSeismoSubtitle
        case .ar: return l10n.toolARSubtitle
        }
    }

    func badge(using l10n: L10n) -> String {
        switch self {
        case .level: return l10n.toolLevelBadge
        case .compass: return l10n.toolCompassBadge
        case .sound: return l10n.toolSoundBadge
        case .ruler: return l10n.toolRulerBadge
        case .protractor: return l10n.toolProtractorBadge
        case .barometer: return l10n.toolBarometerBadge
        case .pedometer: return l10n.toolPedometerBadge
        case .speedometer: return l10n.toolSpeedBadge
        case .light: return l10n.toolLightBadge
        case .magnetometer: return l10n.toolMagnetBadge
        case .seismometer: return l10n.toolSeismoBadge
        case .ar: return l10n.toolARBadge
        }
    }

    var icon: String {
        switch self {
        case .level: return "circle.grid.cross.fill"
        case .compass: return "location.north.line.fill"
        case .sound: return "waveform"
        case .ruler: return "ruler.fill"
        case .protractor: return "angle"
        case .barometer: return "barometer"
        case .pedometer: return "figure.walk"
        case .speedometer: return "speedometer"
        case .light: return "sun.max.fill"
        case .magnetometer: return "magnet"
        case .seismometer: return "waveform.path.ecg"
        case .ar: return "viewfinder"
        }
    }

    var gradient: [Color] {
        switch self {
        case .level: return [Color.blue, Color.cyan]
        case .compass: return [Color.teal, Color.green]
        case .sound: return [Color.orange, Color.pink]
        case .ruler: return [Color.indigo, Color.blue]
        case .protractor: return [Color.purple, Color.indigo]
        case .barometer: return [Color.teal, Color.blue]
        case .pedometer: return [Color.green, Color.mint]
        case .speedometer: return [Color.red, Color.orange]
        case .light: return [Color.yellow, Color.orange]
        case .magnetometer: return [Color.pink, Color.purple]
        case .seismometer: return [Color.mint, Color.cyan]
        case .ar: return [Color.blue, Color.purple]
        }
    }
}

struct MeasuringToolsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabNavigationRouter
    @State private var path = NavigationPath()
    @State private var isEditingLayout = false
    @State private var draggingToolID: String?
    @State private var lastDropTargetId: String?
    @State private var showingResetOrder = false
    @State private var showCannotHideAlert = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                        .id("toolsTop")

                    if isEditingLayout {
                        editModeBanner
                    } else {
                        editButtonRow
                    }

                    if isEditingLayout && !settings.hiddenMeasuringTools.isEmpty {
                        hiddenToolsTray
                    }

                    toolGrid

                    if isEditingLayout {
                        resetOrderButton
                    }

                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(NeonAmbientBackground())
            .navigationTitle(settings.l10n.toolsHeadline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MeasuringTool.self) { tool in
                toolDestination(tool)
            }
            .alert(settings.l10n.cannotHideAll, isPresented: $showCannotHideAlert) {
                Button(settings.l10n.done, role: .cancel) { }
            } message: {
                Text(settings.l10n.cannotHideAllMsg)
            }
        }
        .onChange(of: router.toolsPopToken) { _, _ in
            if !path.isEmpty {
                path = NavigationPath()
            }
            exitEditMode()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    Text(settings.l10n.smartConverter)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))

                Text(settings.l10n.toolsHeadline)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: accentGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.12), radius: 6, y: 3)

                Text(settings.l10n.toolsSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.35))
                    .frame(width: 56, height: 56)
                    .blur(radius: 10)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 8)
    }

    private var editButtonRow: some View {
        HStack {
            Spacer()
            Button {
                enterEditMode()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.l10n.editCards)
        }
    }

    private var editModeBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.l10n.editModeTitle)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                Text(settings.l10n.reorderHint)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                exitEditMode()
            } label: {
                Text(settings.l10n.done)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: accentGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.blue.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue.opacity(0.15), lineWidth: 1))
    }

    private var toolGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            ForEach(settings.orderedMeasuringTools) { tool in
                if isEditingLayout {
                    ToolGridCard(
                        tool: tool,
                        isEditing: true,
                        isDragging: draggingToolID == tool.id,
                        onOpen: { open(tool) },
                        onLongPress: { },
                        onHide: { hide(tool) },
                        onMoveEarlier: { settings.moveMeasuringToolEarlier(tool.id) },
                        onMoveLater: { settings.moveMeasuringToolLater(tool.id) }
                    )
                    .onDrag {
                        draggingToolID = tool.id
                        lastDropTargetId = nil
                        settings.triggerFeedback(impact: .medium)
                        let draggedId = tool.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            if draggingToolID == draggedId {
                                draggingToolID = nil
                                lastDropTargetId = nil
                            }
                        }
                        return NSItemProvider(object: tool.id as NSString)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: ToolDropDelegate(
                            targetID: tool.id,
                            isEnabled: true,
                            draggingID: $draggingToolID,
                            lastTargetId: $lastDropTargetId,
                            onMove: { dragged, target in
                                settings.moveMeasuringTool(dragged, to: target)
                            }
                        )
                    )
                } else {
                    ToolGridCard(
                        tool: tool,
                        isEditing: false,
                        isDragging: false,
                        onOpen: { open(tool) },
                        onLongPress: { enterEditMode() },
                        onHide: { },
                        onMoveEarlier: { },
                        onMoveLater: { }
                    )
                }
            }
        }
    }

    private var resetOrderButton: some View {
        Button(role: .destructive) {
            showingResetOrder = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                Text(settings.l10n.resetLayoutBtn)
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            settings.l10n.resetLayoutBtn,
            isPresented: $showingResetOrder,
            titleVisibility: .visible
        ) {
            Button(settings.l10n.resetLayoutBtn, role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    settings.resetMeasuringToolOrder()
                }
            }
            Button(settings.l10n.cancel, role: .cancel) { }
        }
    }

    private var hiddenToolsTray: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Text(settings.l10n.hiddenCardsTitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                if !settings.hiddenMeasuringTools.isEmpty {
                    Button(settings.l10n.showAllCards) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            settings.showAllMeasuringTools()
                        }
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                }
            }

            if settings.hiddenMeasuringTools.isEmpty {
                Text(settings.l10n.noHiddenCards)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.hiddenMeasuringTools) { tool in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    settings.toggleMeasuringToolHidden(tool.id)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: tool.icon)
                                        .font(.system(size: 11, weight: .bold))
                                    Text(tool.title(using: settings.l10n))
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .lineLimit(1)
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(tool.gradient.first ?? .blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
        .transition(.opacity)
    }

    private func hide(_ tool: MeasuringTool) {
        guard settings.canHideMoreMeasuringTools else {
            settings.triggerFeedback(impact: .heavy)
            showCannotHideAlert = true
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            settings.toggleMeasuringToolHidden(tool.id)
        }
    }

    private func open(_ tool: MeasuringTool) {
        guard !isEditingLayout else { return }
        path.append(tool)
    }

    private func enterEditMode() {
        guard !isEditingLayout else { return }
        settings.triggerFeedback(impact: .medium)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isEditingLayout = true
        }
    }

    private func exitEditMode() {
        draggingToolID = nil
        lastDropTargetId = nil
        guard isEditingLayout else { return }
        settings.triggerFeedback()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isEditingLayout = false
        }
    }

    @ViewBuilder
    private func toolDestination(_ tool: MeasuringTool) -> some View {
        switch tool {
        case .level:
            LevelToolView()
        case .compass:
            CompassQiblaToolView()
        case .sound:
            SoundMeterToolView()
        case .ruler:
            ScreenRulerToolView()
        case .protractor:
            ProtractorToolView()
        case .barometer:
            BarometerToolView()
        case .pedometer:
            PedometerToolView()
        case .speedometer:
            SpeedometerToolView()
        case .light:
            LightMeterToolView()
        case .magnetometer:
            MagnetometerToolView()
        case .seismometer:
            SeismometerToolView()
        case .ar:
            ARMeasureToolView()
        }
    }
}

private struct ToolGridCard: View {
    let tool: MeasuringTool
    let isEditing: Bool
    let isDragging: Bool
    let onOpen: () -> Void
    let onLongPress: () -> Void
    let onHide: () -> Void
    let onMoveEarlier: () -> Void
    let onMoveLater: () -> Void

    @EnvironmentObject var settings: AppSettings
    @State private var suppressTap = false
    @State private var wiggle = false

    var body: some View {
        cardButton
            .overlay(alignment: .topLeading) {
                if isEditing {
                    Button(action: onHide) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                            Circle()
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .frame(width: 23, height: 23)
                        .shadow(color: Color.black.opacity(0.18), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                    .offset(x: -7, y: -7)
                    .accessibilityLabel(settings.l10n.hideCard)
                    .transition(.scale.combined(with: .opacity))
                }
            }
    }

    private var cardButton: some View {
        Button {
            if suppressTap {
                suppressTap = false
                return
            }
            guard !isEditing else { return }
            onOpen()
        } label: {
            FeatureGridCard(
                title: tool.title(using: settings.l10n),
                subtitle: tool.subtitle(using: settings.l10n),
                icon: tool.icon,
                gradient: tool.gradient,
                badge: tool.badge(using: settings.l10n),
                arrowSystemName: settings.appLanguage.arrowIcon
            )
        }
        .buttonStyle(ScaleCardButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    guard !isEditing else { return }
                    suppressTap = true
                    onLongPress()
                }
        )
        .opacity(isDragging ? 0.4 : 1)
        .scaleEffect(isEditing ? 0.97 : 1)
        .rotationEffect(.degrees(isEditing ? (wiggle ? 0.8 : -0.8) : 0))
        .onAppear { updateWiggle(for: isEditing) }
        .onChange(of: isEditing) { _, editing in
            updateWiggle(for: editing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isEditing ? settings.l10n.reorderHint : "")
        .accessibilityActions {
            if isEditing {
                Button(settings.l10n.hideCard, action: onHide)
                Button(settings.l10n.moveEarlier, action: onMoveEarlier)
                Button(settings.l10n.moveLater, action: onMoveLater)
            }
        }
    }

    private func updateWiggle(for editing: Bool) {
        suppressTap = false
        if editing {
            wiggle = false
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                wiggle = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.12)) {
                wiggle = false
            }
        }
    }
}

private struct ToolDropDelegate: DropDelegate {
    let targetID: String
    let isEnabled: Bool
    @Binding var draggingID: String?
    @Binding var lastTargetId: String?
    let onMove: (String, String) -> Void

    func dropEntered(info: DropInfo) {
        guard isEnabled, let draggingID, draggingID != targetID else { return }
        guard lastTargetId != targetID else { return }
        lastTargetId = targetID
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            onMove(draggingID, targetID)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        lastTargetId = nil
        return true
    }
}

// MARK: - Shared tool chrome

struct ToolGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                Color.primary.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, y: 8)
    }
}

extension View {
    func toolGlass(cornerRadius: CGFloat = 24) -> some View {
        modifier(ToolGlassBackground(cornerRadius: cornerRadius))
    }
}

struct SensorStatusCard: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var actionSystemImage: String = "gearshape.fill"
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: accentGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.blue.opacity(0.12)))

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                ToolActionButton(title: actionTitle, systemImage: actionSystemImage, action: action)
                    .padding(.top, 4)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .toolGlass()
    }
}

struct ToolActionButton: View {
    let title: String
    let systemImage: String
    var prominent: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(prominent ? .white : .blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if prominent {
                    LinearGradient(
                        colors: accentGradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.blue.opacity(0.12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ScaleCardButtonStyle())
    }
}

struct ToolHintText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct ToolValueReadout: View {
    let value: String
    let unit: String
    var caption: String?
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(unit)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .environment(\.layoutDirection, .leftToRight)
            if let caption {
                Text(caption)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ToolStatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .toolGlass(cornerRadius: 16)
    }
}

enum MeasurementFormat {
    static func fixed(_ value: Double, fractionDigits: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.usesGroupingSeparator = false
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(fractionDigits)f", value)
    }

    static func grouped(_ value: Double, fractionDigits: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.usesGroupingSeparator = true
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(fractionDigits)f", value)
    }

    static func degrees(_ value: Double, fractionDigits: Int, locale: Locale, signed: Bool = false) -> String {
        let magnitude = fixed(abs(value), fractionDigits: fractionDigits, locale: locale)
        if signed {
            if value > 0.05 { return "+\(magnitude)°" }
            if value < -0.05 { return "−\(magnitude)°" }
            return "\(magnitude)°"
        }
        return "\(magnitude)°"
    }
}

func currentInterfaceOrientation() -> UIInterfaceOrientation {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let active = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    return active?.interfaceOrientation ?? .portrait
}

func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}

#Preview {
    MeasuringToolsView()
        .environmentObject(AppSettings.shared)
}
