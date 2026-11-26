import SwiftUI

// MARK: - Favorites Screen

struct FavoritesView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabNavigationRouter
    @State private var selectedCategory: UnitCategory?
    @State private var selectedTool: MeasuringTool?

    private var favoriteCategories: [UnitCategory] {
        settings.orderedCategories.filter { settings.isFavorite($0.id) }
    }

    private var favoriteTools: [MeasuringTool] {
        settings.favoriteMeasuringTools
    }

    private var showsEmptyState: Bool {
        favoriteCategories.isEmpty && favoriteTools.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if showsEmptyState {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 22) {
                        if !favoriteCategories.isEmpty {
                            favoritesSection(title: settings.l10n.favoritesUnitsSection) {
                                categoryGrid
                            }
                        }
                        if !favoriteTools.isEmpty {
                            favoritesSection(title: settings.l10n.favoritesToolsSection) {
                                toolGrid
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                Color.clear.frame(height: 100)
            }
            .background(NeonAmbientBackground())
            .navigationTitle(settings.l10n.favoritesTitle)
            .navigationDestination(item: $selectedCategory) { category in
                ConverterView(category: category)
                    .environmentObject(settings)
            }
            .navigationDestination(item: $selectedTool) { tool in
                measuringToolScreen(tool)
                    .toolFavoriteStar(tool.id)
            }
            .onChange(of: router.favoritesPopToken) { _, _ in
                selectedCategory = nil
                selectedTool = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash.fill")
                .font(.system(size: 64))
                .foregroundColor(.yellow.opacity(0.6))
                .padding(.top, 60)

            Text(settings.l10n.emptyFavoritesTitle)
                .font(.title3.bold())

            Text(settings.l10n.emptyFavoritesMsg)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    private func favoritesSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
            content()
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            ForEach(favoriteCategories) { category in
                HomeCategoryCard(
                    category: category,
                    isEditing: false,
                    isDragging: false,
                    onOpen: { selectedCategory = category },
                    onLongPress: { },
                    onHide: { }
                )
            }
        }
    }

    private var toolGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            ForEach(favoriteTools) { tool in
                Button {
                    selectedTool = tool
                } label: {
                    FeatureGridCard(
                        title: tool.title(using: settings.l10n),
                        subtitle: tool.subtitle(using: settings.l10n),
                        icon: tool.icon,
                        gradient: tool.gradient,
                        badge: tool.badge(using: settings.l10n),
                        arrowSystemName: settings.appLanguage.arrowIcon,
                        showsFavoriteStar: true
                    )
                }
                .buttonStyle(ScaleCardButtonStyle())
            }
        }
    }
}
