import Foundation

/// Which tools the measuring-tools page shows for All, Popular, and Favorites,
/// including a search across Arabic and English names.
nonisolated enum ToolBrowse {
    enum Filter: Int, Equatable, Sendable {
        case all = 0
        case popular = 1
        case favorites = 2
    }

    /// Popular tools, in the default catalog order.
    static let popularIDs = ["compass", "ar", "light", "speedometer", "level", "ruler"]

    struct Name: Equatable, Sendable {
        var arabicTitle: String
        var englishTitle: String
        var arabicSubtitle: String
        var englishSubtitle: String

        func matches(_ query: String) -> Bool {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return true }
            return [arabicTitle, englishTitle, arabicSubtitle, englishSubtitle]
                .contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    /// `orderedVisible` is the saved order with hidden and unavailable tools already removed.
    /// Popular stays in `popularIDs` order. Favorites stay in the saved order.
    static func matchingIDs(
        orderedVisible: [String],
        filter: Filter,
        favorites: [String],
        query: String,
        names: [String: Name]
    ) -> [String] {
        let base: [String]
        switch filter {
        case .all:
            base = orderedVisible
        case .popular:
            let visible = Set(orderedVisible)
            base = popularIDs.filter { visible.contains($0) }
        case .favorites:
            let favorite = Set(favorites)
            base = orderedVisible.filter { favorite.contains($0) }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        return base.filter { names[$0]?.matches(trimmed) ?? false }
    }
}

/// Saved measuring-tool favorites. Unknown ids are dropped and duplicates collapse.
nonisolated enum ToolFavorites {
    static let defaultsKey = "measuring_tools_favorites"

    static func toggling(_ current: [String], id: String) -> [String] {
        if let index = current.firstIndex(of: id) {
            var next = current
            next.remove(at: index)
            return next
        }
        return current + [id]
    }

    static func sanitized(_ saved: [String], catalog: [String]) -> [String] {
        let allowed = Set(catalog)
        var result: [String] = []
        var seen = Set<String>()
        for id in saved where allowed.contains(id) && seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    static func load(from defaults: UserDefaults, catalog: [String]) -> [String] {
        sanitized(defaults.stringArray(forKey: defaultsKey) ?? [], catalog: catalog)
    }

    static func save(_ ids: [String], to defaults: UserDefaults) {
        defaults.set(ids, forKey: defaultsKey)
    }
}
