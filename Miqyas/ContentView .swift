import SwiftUI
import Combine

// MARK: - Tab Navigation Router
// Lets the floating tab bar pop a tab back to its root when the user taps
// the tab that is already selected.

@MainActor
final class TabNavigationRouter: ObservableObject {
    @Published private(set) var homePopToken: Int = 0
    @Published private(set) var favoritesPopToken: Int = 0

    func popToRoot(for tab: AppTab) {
        switch tab {
        case .home:
            homePopToken += 1
        case .favorites:
            favoritesPopToken += 1
        case .history, .settings:
            break
        }
    }
}

// MARK: - Main ContentView

struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = TabNavigationRouter()
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .favorites:
                    FavoritesView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            DistinctiveFloatingTabBar(selectedTab: $selectedTab) { tab in
                router.popToRoot(for: tab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .environmentObject(settings)
        .environmentObject(router)
        .preferredColorScheme(settings.appColorScheme.colorScheme)
        .environment(\.layoutDirection, settings.appLanguage.layoutDirection)
        .environment(\.locale, Locale(identifier: settings.appLanguage.rawValue))
        .animation(.easeInOut(duration: 0.25), value: settings.appLanguage)
    }
}

// MARK: - Safe Array Extension

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
