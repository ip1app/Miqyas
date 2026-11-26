import SwiftUI
import UniformTypeIdentifiers

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabNavigationRouter
    @State private var searchText: String = ""
    @State private var selectedFilterIndex: Int = 0
    @State private var isEditingLayout: Bool = false
    @State private var selectedCategory: UnitCategory?
    @State private var draggingCategory: UnitCategory?
    @State private var lastDropTargetId: String?
    @State private var showCannotHideAlert: Bool = false
    @State private var showingResetLayoutAlert: Bool = false

    var filterOptions: [String] {
        [settings.l10n.filterAll, settings.l10n.filterPopular, settings.l10n.filterFavorites]
    }

    var canEditLayout: Bool {
        selectedFilterIndex == 0 && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredCategories: [UnitCategory] {
        var list = settings.orderedCategories

        switch selectedFilterIndex {
        case 1:
            list = list.filter { ["length", "weight", "temperature", "volume", "time", "digital"].contains($0.id) }
        case 2:
            list = list.filter { settings.isFavorite($0.id) }
        default:
            break
        }

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return list
        }

        return list.filter { cat in
            cat.titleAr.localizedCaseInsensitiveContains(searchText) ||
            cat.titleEn.localizedCaseInsensitiveContains(searchText) ||
            cat.subtitleAr.localizedCaseInsensitiveContains(searchText) ||
            cat.subtitleEn.localizedCaseInsensitiveContains(searchText) ||
            cat.units.contains(where: {
                $0.nameAr.localizedCaseInsensitiveContains(searchText) ||
                $0.nameEn.localizedCaseInsensitiveContains(searchText) ||
                $0.abbreviation.localizedCaseInsensitiveContains(searchText)
            })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerBanner
                            .id("homeTop")

                        if isEditingLayout {
                            editModeBanner
                        } else {
                            searchBar
                            filterChipsView
                        }

                        if !isEditingLayout && selectedFilterIndex == 0 && searchText.isEmpty && !settings.favorites.isEmpty {
                            favoritesQuickRow
                        }

                        if isEditingLayout && !settings.hiddenCategories.isEmpty {
                            hiddenCardsTray
                        }

                        categoryGrid

                        if isEditingLayout {
                            resetLayoutButton
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(NeonAmbientBackground())
                .navigationTitle("")
                .navigationBarHidden(true)
                .navigationDestination(item: $selectedCategory) { category in
                    ConverterView(category: category)
                        .environmentObject(settings)
                }
                .onChange(of: router.homePopToken) { _, _ in
                    handleHomeTabReselect(proxy: proxy)
                }
                .onChange(of: selectedFilterIndex) { _, _ in
                    exitEditModeIfNeeded()
                }
                .onChange(of: searchText) { _, _ in
                    exitEditModeIfNeeded()
                }
                .alert(settings.l10n.cannotHideAll, isPresented: $showCannotHideAlert) {
                    Button(settings.l10n.done, role: .cancel) { }
                } message: {
                    Text(settings.l10n.cannotHideAllMsg)
                }
            }
        }
    }

    // MARK: - Tab Reselect

    private func handleHomeTabReselect(proxy: ScrollViewProxy) {
        if selectedCategory != nil {
            selectedCategory = nil
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo("homeTop", anchor: .top)
            }
        }
        if isEditingLayout {
            exitEditMode()
        }
    }

    // MARK: - Category Grid

    @ViewBuilder
    private var categoryGrid: some View {
        if filteredCategories.isEmpty {
            emptyStateView
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 14
            ) {
                ForEach(filteredCategories) { category in
                    if isEditingLayout {
                        HomeCategoryCard(
                            category: category,
                            isEditing: true,
                            isDragging: draggingCategory?.id == category.id,
                            onOpen: { open(category) },
                            onLongPress: {},
                            onHide: { hide(category) },
                            onMoveEarlier: { settings.moveCategoryEarlier(category.id) },
                            onMoveLater: { settings.moveCategoryLater(category.id) }
                        )
                        .onDrag {
                            draggingCategory = category
                            lastDropTargetId = nil
                            settings.triggerFeedback(impact: .medium)
                            let draggedId = category.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                if draggingCategory?.id == draggedId {
                                    draggingCategory = nil
                                    lastDropTargetId = nil
                                }
                            }
                            return NSItemProvider(object: category.id as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: CategoryDropDelegate(
                                target: category,
                                isEnabled: isEditingLayout,
                                dragging: $draggingCategory,
                                lastTargetId: $lastDropTargetId,
                                onMove: { draggedId, targetId in
                                    settings.moveCategory(draggedId, to: targetId)
                                }
                            )
                        )
                    } else {
                        HomeCategoryCard(
                            category: category,
                            isEditing: false,
                            isDragging: false,
                            onOpen: { open(category) },
                            onLongPress: { enterEditMode() },
                            onHide: {}
                        )
                    }
                }
            }
        }
    }

    private var headerBanner: some View {
        CatalogHeaderView(
            badge: settings.l10n.smartConverter,
            title: settings.l10n.homeHeadline,
            subtitle: settings.l10n.homeSubtitle,
            icon: "arrow.triangle.2.circlepath"
        )
    }

    private var searchBar: some View {
        CatalogSearchField(text: $searchText, placeholder: settings.l10n.searchPlaceholder)
    }

    private var filterChipsView: some View {
        CatalogFilterChips(
            options: filterOptions,
            selectedIndex: $selectedFilterIndex,
            showsEditButton: canEditLayout,
            editLabel: settings.l10n.editCards,
            onSelect: { settings.triggerFeedback() },
            onEdit: { enterEditMode() }
        )
    }

    private var favoritesQuickRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(settings.l10n.quickFavorites)
                    .font(.headline)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(settings.orderedCategories.filter { settings.isFavorite($0.id) }) { cat in
                        Button {
                            open(cat)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: cat.icon)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        LinearGradient(
                                            colors: cat.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())

                                Text(cat.title(for: settings.appLanguage))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Edit Mode UI

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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var hiddenCardsTray: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Text(settings.l10n.hiddenCardsTitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                if !settings.hiddenCategories.isEmpty {
                    Button(settings.l10n.showAllCards) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            settings.showAllCategories()
                        }
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                }
            }

            if settings.hiddenCategories.isEmpty {
                Text(settings.l10n.noHiddenCards)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.hiddenCategories) { cat in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    settings.toggleCategoryHidden(cat.id)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 11, weight: .bold))
                                    Text(cat.title(for: settings.appLanguage))
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .lineLimit(1)
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(cat.gradientColors.first ?? .blue)
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .transition(.opacity)
    }

    private var resetLayoutButton: some View {
        Button(role: .destructive) {
            showingResetLayoutAlert = true
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
            isPresented: $showingResetLayoutAlert,
            titleVisibility: .visible
        ) {
            Button(settings.l10n.resetLayoutBtn, role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    settings.resetHomeLayout()
                }
            }
            Button(settings.l10n.cancel, role: .cancel) { }
        }
    }

    // MARK: - Edit Actions

    private func enterEditMode() {
        guard canEditLayout else { return }
        settings.triggerFeedback(impact: .medium)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isEditingLayout = true
        }
    }

    private func exitEditMode() {
        draggingCategory = nil
        lastDropTargetId = nil
        guard isEditingLayout else { return }
        settings.triggerFeedback()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isEditingLayout = false
        }
    }

    private func exitEditModeIfNeeded() {
        if isEditingLayout && !canEditLayout {
            exitEditMode()
        }
    }

    private func open(_ category: UnitCategory) {
        selectedCategory = category
    }

    private func hide(_ category: UnitCategory) {
        guard settings.canHideMoreCategories else {
            settings.triggerFeedback(impact: .heavy)
            showCannotHideAlert = true
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            settings.toggleCategoryHidden(category.id)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 40)

            Text(settings.l10n.noSearchResults)
                .font(.headline)
                .foregroundColor(.secondary)

            Button(settings.l10n.clearSearch) {
                searchText = ""
                selectedFilterIndex = 0
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}


