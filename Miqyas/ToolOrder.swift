import Foundation

/// Saved order of measuring-tool cards.
/// Known ids keep their saved sequence. Ids that are no longer in the catalog are dropped.
/// Catalog ids that are not in the saved order are appended, so a future tool stays at the end.
nonisolated enum ToolOrder {
    static let defaultsKey = "measuring_tools_order"

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
}
