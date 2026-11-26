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
        var keywords: [String] = []

        func matches(_ query: String) -> Bool {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return true }
            let fields = [arabicTitle, englishTitle, arabicSubtitle, englishSubtitle] + keywords
            return fields.contains { $0.localizedCaseInsensitiveContains(trimmed) }
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

    /// Favorites in the saved tool order. Unavailable hardware is left out.
    /// A tool the user hid from the grid still appears here.
    static func listed(ordered: [String], favorites: [String], unavailable: Set<String>) -> [String] {
        let favorite = Set(favorites)
        return ordered.filter { favorite.contains($0) && !unavailable.contains($0) }
    }

    static func load(from defaults: UserDefaults, catalog: [String]) -> [String] {
        sanitized(defaults.stringArray(forKey: defaultsKey) ?? [], catalog: catalog)
    }

    static func save(_ ids: [String], to defaults: UserDefaults) {
        defaults.set(ids, forKey: defaultsKey)
    }
}

/// Camera-measure line appearance. Accent blue and medium are the defaults.
nonisolated enum MeasureLineColor: String, CaseIterable, Codable, Equatable, Sendable {
    case yellow
    case white
    case red
    case green
    case blue
}

nonisolated enum MeasureLineThickness: String, CaseIterable, Codable, Equatable, Sendable {
    case thin
    case medium
    case thick

    /// Core tube width, in meters. A thin white edge is drawn just outside this.
    var widthMeters: Float {
        switch self {
        case .thin: return 0.008
        case .medium: return 0.016
        case .thick: return 0.028
        }
    }

    var endpointRadiusMeters: Float {
        switch self {
        case .thin: return 0.014
        case .medium: return 0.024
        case .thick: return 0.036
        }
    }
}

nonisolated struct MeasureLineOptions: Equatable, Codable, Sendable {
    var color: MeasureLineColor
    var thickness: MeasureLineThickness

    static let `default` = MeasureLineOptions(color: .blue, thickness: .medium)
    static let colorDefaultsKey = "ar_measure_line_color"
    static let thicknessDefaultsKey = "ar_measure_line_thickness"

    static func load(from defaults: UserDefaults) -> MeasureLineOptions {
        let color = defaults.string(forKey: colorDefaultsKey).flatMap(MeasureLineColor.init(rawValue:)) ?? .blue
        let thickness = defaults.string(forKey: thicknessDefaultsKey).flatMap(MeasureLineThickness.init(rawValue:)) ?? .medium
        return MeasureLineOptions(color: color, thickness: thickness)
    }

    static func save(_ options: MeasureLineOptions, to defaults: UserDefaults) {
        defaults.set(options.color.rawValue, forKey: colorDefaultsKey)
        defaults.set(options.thickness.rawValue, forKey: thicknessDefaultsKey)
    }

    static func reset(in defaults: UserDefaults) {
        save(.default, to: defaults)
    }
}
