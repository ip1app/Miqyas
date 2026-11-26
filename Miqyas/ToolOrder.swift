import Foundation

/// Saved order of measuring-tool cards.
/// Known ids keep their saved sequence. Ids that are no longer in the catalog are dropped.
/// Catalog ids that are not in the saved order are appended, so a future tool stays at the end.
nonisolated enum ToolOrder {
    static let defaultsKey = "measuring_tools_order"
    static let hiddenDefaultsKey = "measuring_tools_hidden"

    struct Layout: Equatable {
        var order: [String]
        var hidden: [String]

        var visible: [String] {
            order.filter { !hidden.contains($0) }
        }
    }

    static func merged(saved: [String], catalog: [String]) -> [String] {
        let allowed = Set(catalog)
        var result: [String] = []
        var seen = Set<String>()
        for id in saved where allowed.contains(id) && seen.insert(id).inserted {
            result.append(id)
        }
        for id in catalog where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    /// Same index move the home category grid uses.
    static func moving(_ order: [String], dragged: String, to target: String) -> [String]? {
        guard dragged != target else { return nil }
        var order = order
        guard let from = order.firstIndex(of: dragged),
              let to = order.firstIndex(of: target) else { return nil }
        let item = order.remove(at: from)
        order.insert(item, at: min(to, order.count))
        return order
    }

    static func movingEarlier(_ order: [String], id: String) -> [String]? {
        var order = order
        guard let index = order.firstIndex(of: id), index > 0 else { return nil }
        order.swapAt(index, index - 1)
        return order
    }

    static func movingLater(_ order: [String], id: String) -> [String]? {
        var order = order
        guard let index = order.firstIndex(of: id), index < order.count - 1 else { return nil }
        order.swapAt(index, index + 1)
        return order
    }

    static func load(from defaults: UserDefaults, catalog: [String]) -> [String] {
        let saved = defaults.stringArray(forKey: defaultsKey) ?? []
        return merged(saved: saved, catalog: catalog)
    }

    static func save(_ order: [String], to defaults: UserDefaults) {
        defaults.set(order, forKey: defaultsKey)
    }

    /// Hidden ids that still exist. New catalog ids are left out, so they stay visible.
    static func mergedHidden(saved: [String], catalog: [String]) -> [String] {
        let allowed = Set(catalog)
        var result: [String] = []
        var seen = Set<String>()
        for id in saved where allowed.contains(id) && seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    static func layout(savedOrder: [String], savedHidden: [String], catalog: [String]) -> Layout {
        Layout(
            order: merged(saved: savedOrder, catalog: catalog),
            hidden: mergedHidden(saved: savedHidden, catalog: catalog)
        )
    }

    /// Visible cards the device can actually show. Unavailable ids stay in `order`
    /// and are not added to `hidden`; they also do not count as a remaining card.
    static func displayedIDs(_ layout: Layout, unavailable: Set<String> = []) -> [String] {
        layout.visible.filter { !unavailable.contains($0) }
    }

    /// Hides a visible card, or shows it again. Refuses to hide the last card that
    /// is actually visible. `unavailable` ids are not that last card.
    static func togglingHidden(_ layout: Layout, id: String, unavailable: Set<String> = []) -> Layout? {
        if let index = layout.hidden.firstIndex(of: id) {
            var shown = layout
            shown.hidden.remove(at: index)
            return shown
        }
        let availableVisible = displayedIDs(layout, unavailable: unavailable)
        guard availableVisible.contains(id), availableVisible.count > 1 else { return nil }
        var hidden = layout
        hidden.hidden.append(id)
        return hidden
    }

    static func showingAll(_ layout: Layout) -> Layout {
        var shown = layout
        shown.hidden = []
        return shown
    }

    static func reset(catalog: [String]) -> Layout {
        Layout(order: catalog, hidden: [])
    }

    static func loadLayout(from defaults: UserDefaults, catalog: [String]) -> Layout {
        layout(
            savedOrder: defaults.stringArray(forKey: defaultsKey) ?? [],
            savedHidden: defaults.stringArray(forKey: hiddenDefaultsKey) ?? [],
            catalog: catalog
        )
    }

    static func saveLayout(_ layout: Layout, to defaults: UserDefaults) {
        defaults.set(layout.order, forKey: defaultsKey)
        defaults.set(layout.hidden, forKey: hiddenDefaultsKey)
    }
}
