import SwiftUI

// MARK: - Tools hub

enum MeasuringTool: String, Hashable, CaseIterable, Identifiable {
    case level
    case compass
    case sound

    var id: String { rawValue }

    func title(using l10n: L10n) -> String {
        switch self {
        case .level: return l10n.toolLevelTitle
        case .compass: return l10n.toolCompassTitle
        case .sound: return l10n.toolSoundTitle
        }
    }

    func subtitle(using l10n: L10n) -> String {
        switch self {
        case .level: return l10n.toolLevelSubtitle
        case .compass: return l10n.toolCompassSubtitle
        case .sound: return l10n.toolSoundSubtitle
        }
    }

    var icon: String {
        switch self {
        case .level: return "circle.grid.cross.fill"
        case .compass: return "location.north.line.fill"
        case .sound: return "waveform"
        }
    }

    var gradient: [Color] {
        switch self {
        case .level: return [Color.blue, Color.cyan]
        case .compass: return [Color.teal, Color.green]
        case .sound: return [Color.orange, Color.pink]
        }
    }
}

struct MeasuringToolsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabNavigationRouter
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                        .padding(.top, 8)

                    ForEach(MeasuringTool.allCases) { tool in
                        NavigationLink(value: tool) {
                            MeasuringToolCard(tool: tool)
                        }
                        .buttonStyle(ScaleCardButtonStyle())
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
        }
        .onChange(of: router.toolsPopToken) { _, _ in
            if !path.isEmpty {
                path = NavigationPath()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                    Text(settings.l10n.smartConverter)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: accentGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 1))

                Text(settings.l10n.toolsHeadline)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: accentGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(settings.l10n.toolsSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.35))
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
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
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
        }
    }
}

struct MeasuringToolCard: View {
    let tool: MeasuringTool
    @EnvironmentObject var settings: AppSettings

    private var primary: Color { tool.gradient.first ?? .blue }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(primary.opacity(0.35))
                    .frame(width: 54, height: 54)
                    .blur(radius: 8)
                    .offset(y: 4)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: tool.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                Image(systemName: tool.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title(using: settings.l10n))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(tool.subtitle(using: settings.l10n))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: settings.appLanguage.arrowIcon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.primary.opacity(0.05)))
        }
        .padding(16)
        .toolGlass()
        .accessibilityElement(children: .combine)
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
