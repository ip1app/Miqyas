import SwiftUI

// MARK: - Favorites Screen

struct FavoritesView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabNavigationRouter
    @State private var selectedCategory: UnitCategory?

    var favoriteCategories: [UnitCategory] {
        settings.orderedCategories.filter { settings.isFavorite($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if favoriteCategories.isEmpty {
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
                } else {
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
            .onChange(of: router.favoritesPopToken) { _, _ in
                selectedCategory = nil
            }
        }
    }
}
