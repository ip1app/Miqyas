import SwiftUI

// MARK: - App Design Tokens

let accentGradientColors: [Color] = [Color.blue, Color.cyan]

// MARK: - Unit Selection Sheet

struct UnitSelectionSheet: View {
    let title: String
    let units: [Unit]
    @Binding var selectedIndex: Int
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    var filteredIndices: [Int] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(units.indices)
        }
        return units.indices.filter { idx in
            units[idx].name(for: settings.appLanguage).localizedCaseInsensitiveContains(searchText) ||
            units[idx].nameAr.localizedCaseInsensitiveContains(searchText) ||
            units[idx].nameEn.localizedCaseInsensitiveContains(searchText) ||
            units[idx].abbreviation.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(settings.l10n.searchUnitPlaceholder, text: $searchText)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Units List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredIndices, id: \.self) { index in
                            let unit = units[index]
                            let isSelected = selectedIndex == index

                            Button {
                                selectedIndex = index
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Text(unit.abbreviation)
                                        .font(.system(.subheadline, design: .monospaced).bold())
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.blue : Color(.systemGray5))
                                        .clipShape(Capsule())

                                    Text(unit.name(for: settings.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isSelected ? Color.blue.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isSelected ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.l10n.done) {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Modern Built-in Keypad

struct ModernNumericKeypad: View {
    @Binding var inputAmount: String
    @EnvironmentObject var settings: AppSettings

    let rows: [[String]] = [
        ["7", "8", "9", "⌫"],
        ["4", "5", "6", "C"],
        ["1", "2", "3", "±"],
        ["0", "00", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleKey(key)
                            settings.triggerFeedback(impact: .light)
                        } label: {
                            Text(key)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(buttonBackground(for: key))
                                .foregroundColor(buttonTextColor(for: key))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
    }

    private func buttonBackground(for key: String) -> Color {
        switch key {
        case "C", "⌫":
            return Color.red.opacity(0.12)
        case "=":
            return Color.blue
        case "±", ".":
            return Color(.systemGray5)
        default:
            return Color(.systemGray6)
        }
    }

    private func buttonTextColor(for key: String) -> Color {
        switch key {
        case "C", "⌫":
            return .red
        case "=":
            return .white
        default:
            return .primary
        }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "C":
            inputAmount = ""
        case "⌫":
            if !inputAmount.isEmpty {
                inputAmount.removeLast()
            }
        case "±":
            if inputAmount.hasPrefix("-") {
                inputAmount.removeFirst()
            } else if !inputAmount.isEmpty && inputAmount != "0" {
                inputAmount = "-" + inputAmount
            }
        case ".":
            if !inputAmount.contains(".") {
                inputAmount += inputAmount.isEmpty ? "0." : "."
            }
        case "00":
            if !inputAmount.isEmpty && inputAmount != "0" {
                inputAmount += "00"
            }
        case "=":
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        default:
            if inputAmount == "0" {
                inputAmount = key
            } else {
                inputAmount += key
            }
        }
    }
}

// MARK: - Animated Neon Mesh Background (Glassmorphism Environment)

struct NeonAmbientBackground: View {
    @State private var animateOrbs: Bool = false

    var body: some View {
        ZStack {
            // Deep base background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // Soft Animated Neon Glowing Orbs
            GeometryReader { geo in
                ZStack {
                    // Top-Leading Electric Blue Orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 220
                            )
                        )
                        .frame(width: 380, height: 380)
                        .offset(
                            x: animateOrbs ? -40 : 20,
                            y: animateOrbs ? -60 : 30
                        )
                        .blur(radius: 60)

                    // Center-Trailing Neon Purple Orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.32), Color.indigo.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 260
                            )
                        )
                        .frame(width: 420, height: 420)
                        .position(x: geo.size.width + (animateOrbs ? 20 : -40), y: geo.size.height * 0.42 + (animateOrbs ? -40 : 30))
                        .blur(radius: 70)

                    // Bottom-Leading Teal Glow Orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.teal.opacity(0.28), Color.mint.opacity(0.10), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 200
                            )
                        )
                        .frame(width: 360, height: 360)
                        .position(x: animateOrbs ? 80 : 30, y: geo.size.height * 0.85 + (animateOrbs ? -30 : 20))
                        .blur(radius: 65)
                }
            }
            .ignoresSafeArea()

            // Ultra-thin frosted glass texture overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.4))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateOrbs.toggle()
            }
        }
    }
}

// MARK: - Category Card Content (shared visuals)

struct CategoryCardContent: View {
    let category: UnitCategory
    @EnvironmentObject var settings: AppSettings

    var isFav: Bool {
        settings.isFavorite(category.id)
    }

    var primaryColor: Color {
        category.gradientColors.first ?? .blue
    }

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 14) {
                // Top Row: 3D Glowing Icon & Star Action
                HStack(alignment: .top) {
                    ZStack {
                        // Ambient colored glow under icon
                        RoundedRectangle(cornerRadius: 18)
                            .fill(primaryColor.opacity(0.35))
                            .frame(width: 54, height: 54)
                            .blur(radius: 8)
                            .offset(y: 4)

                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: category.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )

                        Image(systemName: category.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                    }

                    Spacer()

                    if isFav {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 30, height: 30)
                            Image(systemName: "star.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // Titles with modern typography
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.title(for: settings.appLanguage))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(category.subtitle(for: settings.appLanguage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Bottom Row: Neon Capsule Badge & Glass Indicator
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(primaryColor)
                            .frame(width: 5, height: 5)
                        Text("\(category.units.count) \(settings.l10n.unitsSuffix)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(primaryColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(primaryColor.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(primaryColor.opacity(0.25), lineWidth: 0.8)
                    )

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 24, height: 24)
                        Image(systemName: settings.appLanguage.arrowIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)

                    // Subtle dynamic color sheen in the corner
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [primaryColor.opacity(0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
            .shadow(color: primaryColor.opacity(0.12), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                primaryColor.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
        }
    }
}

// MARK: - Home Category Card (tap, long-press & drag)

struct HomeCategoryCard: View {
    let category: UnitCategory
    let isEditing: Bool
    let isDragging: Bool
    let onOpen: () -> Void
    let onLongPress: () -> Void
    let onHide: () -> Void
    var onMoveEarlier: (() -> Void)? = nil
    var onMoveLater: (() -> Void)? = nil

    @EnvironmentObject var settings: AppSettings
    @State private var suppressTap: Bool = false
    @State private var wiggle: Bool = false

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
            CategoryCardContent(category: category)
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
                if let onMoveEarlier {
                    Button(settings.l10n.moveEarlier, action: onMoveEarlier)
                }
                if let onMoveLater {
                    Button(settings.l10n.moveLater, action: onMoveLater)
                }
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

// MARK: - Grid Drag & Drop Reordering

struct CategoryDropDelegate: DropDelegate {
    let target: UnitCategory
    let isEnabled: Bool
    @Binding var dragging: UnitCategory?
    @Binding var lastTargetId: String?
    let onMove: (String, String) -> Void

    func dropEntered(info: DropInfo) {
        guard isEnabled, let dragging, dragging.id != target.id else { return }
        guard lastTargetId != target.id else { return }
        lastTargetId = target.id
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            onMove(dragging.id, target.id)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        lastTargetId = nil
        return true
    }
}

// Button scale effect
struct ScaleCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Distinctive Floating Glass Tab Bar

enum AppTab: Int, CaseIterable {
    case home = 0
    case tools = 1
    case favorites = 2
    case history = 3
    case settings = 4

    func title(using l10n: L10n) -> String {
        switch self {
        case .home: return l10n.tabHome
        case .tools: return l10n.tabTools
        case .favorites: return l10n.tabFavorites
        case .history: return l10n.tabHistory
        case .settings: return l10n.tabSettings
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .favorites: return "star.fill"
        case .history: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct DistinctiveFloatingTabBar: View {
    @Binding var selectedTab: AppTab
    var onReselect: (AppTab) -> Void = { _ in }
    @EnvironmentObject var settings: AppSettings
    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab

                Button {
                    if isSelected {
                        onReselect(tab)
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                    settings.triggerFeedback(impact: .light)
                } label: {
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: accentGradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .matchedGeometryEffect(id: "activeTabBackground", in: tabAnimation)
                                .frame(width: 46, height: 46)
                                .shadow(color: Color.cyan.opacity(0.45), radius: 9, y: 4)
                        }

                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(isSelected ? Color.white : Color.secondary)
                            .scaleEffect(isSelected ? 1.08 : 1.0)
                    }
                    .frame(width: 46, height: 46)
                    .overlay(alignment: .topTrailing) {
                        if tab == .history && !settings.history.isEmpty {
                            Text(settings.history.count > 99 ? "99+" : "\(settings.history.count)")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title(using: settings.l10n))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityRemoveTraits(isSelected ? [] : .isSelected)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.15),
                            Color.cyan.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 22, y: 10)
        .shadow(color: Color.blue.opacity(0.10), radius: 16, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}




// MARK: - System Share Sheet

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // On iPad the activity controller is presented as a popover and requires an anchor.
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.modalPresentationStyle = .formSheet
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

