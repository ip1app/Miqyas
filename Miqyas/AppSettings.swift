import SwiftUI
import Combine
import AudioToolbox

// MARK: - App Settings

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var appLanguage: AppLanguage = .arabic {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "app_language")
        }
    }

    @Published var favorites: [String] = [] {
        didSet {
            UserDefaults.standard.set(favorites, forKey: "favorites_ids")
        }
    }

    @Published var categoryOrder: [String] = [] {
        didSet {
            UserDefaults.standard.set(categoryOrder, forKey: "home_category_order")
        }
    }

    /// Saved measuring-tool card order. Empty means the catalog order.
    /// New tools missing from a saved order are appended when the grid is built.
    @Published var toolOrder: [String] = [] {
        didSet {
            UserDefaults.standard.set(toolOrder, forKey: ToolOrder.defaultsKey)
        }
    }

    @Published var hiddenMeasuringToolIds: [String] = [] {
        didSet {
            UserDefaults.standard.set(hiddenMeasuringToolIds, forKey: ToolOrder.hiddenDefaultsKey)
        }
    }

    @Published var hiddenCategoryIds: [String] = [] {
        didSet {
            UserDefaults.standard.set(hiddenCategoryIds, forKey: "home_hidden_categories")
        }
    }

    @Published var history: [ConversionRecord] = [] {
        didSet {
            saveHistory()
        }
    }

    @Published var maxDecimalDigits: Int = 4 {
        didSet { UserDefaults.standard.set(maxDecimalDigits, forKey: "maxDecimalDigits") }
    }

    @Published var useScientificNotation: Bool = true {
        didSet { UserDefaults.standard.set(useScientificNotation, forKey: "useScientificNotation") }
    }

    @Published var useThousandsSeparator: Bool = true {
        didSet { UserDefaults.standard.set(useThousandsSeparator, forKey: "useThousandsSeparator") }
    }

    @Published var soundEffects: Bool = true {
        didSet { UserDefaults.standard.set(soundEffects, forKey: "soundEffects") }
    }

    @Published var hapticFeedback: Bool = true {
        didSet { UserDefaults.standard.set(hapticFeedback, forKey: "hapticFeedback") }
    }

    @Published var showConversionHistory: Bool = true {
        didSet { UserDefaults.standard.set(showConversionHistory, forKey: "showConversionHistory") }
    }

    @Published var appColorScheme: AppColorScheme = .system {
        didSet { UserDefaults.standard.set(appColorScheme.rawValue, forKey: "appColorScheme") }
    }

    /// In-memory review counter. The successful-conversion total and the last
    /// prompted version are persisted; the on-screen signature is not.
    private var reviewTracker = ReviewPromptTracker()

    /// Hardware that is missing on this device. These ids stay in the saved order
    /// and are not written into the hidden-tools list.
    private let unavailableMeasuringToolIDs: Set<String>

    var l10n: L10n {
        L10n(lang: appLanguage)
    }

    static var marketingVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let version, !version.isEmpty {
            return version
        }
        return "1.0"
    }

    // MARK: - Home Layout (Card Order & Visibility)

    /// All categories in the user's custom order, including hidden ones.
    /// New categories coming from app updates are appended at the end.
    var allCategoriesInOrder: [UnitCategory] {
        let byId = Dictionary(uniqueKeysWithValues: unitCategories.map { ($0.id, $0) })
        var ordered = categoryOrder.compactMap { byId[$0] }
        let missing = unitCategories.filter { !categoryOrder.contains($0.id) }
        ordered.append(contentsOf: missing)
        return ordered
    }

    /// Categories shown on the home grid (custom order, hidden cards removed).
    var orderedCategories: [UnitCategory] {
        allCategoriesInOrder.filter { !hiddenCategoryIds.contains($0.id) }
    }

    /// Categories currently hidden from the home grid.
    var hiddenCategories: [UnitCategory] {
        allCategoriesInOrder.filter { hiddenCategoryIds.contains($0.id) }
    }

    var canHideMoreCategories: Bool {
        orderedCategories.count > 1
    }

    /// Live reorder while dragging a card over another one.
    func moveCategory(_ draggedId: String, to targetId: String) {
        guard draggedId != targetId else { return }
        var order = allCategoriesInOrder.map(\.id)
        guard let from = order.firstIndex(of: draggedId),
              let to = order.firstIndex(of: targetId) else { return }
        let item = order.remove(at: from)
        order.insert(item, at: min(to, order.count))
        categoryOrder = order
        triggerDragFeedback()
    }

    func moveCategoryEarlier(_ id: String) {
        var order = allCategoriesInOrder.map(\.id)
        guard let idx = order.firstIndex(of: id), idx > 0 else { return }
        order.swapAt(idx, idx - 1)
        categoryOrder = order
        triggerDragFeedback()
    }

    func moveCategoryLater(_ id: String) {
        var order = allCategoriesInOrder.map(\.id)
        guard let idx = order.firstIndex(of: id), idx < order.count - 1 else { return }
        order.swapAt(idx, idx + 1)
        categoryOrder = order
        triggerDragFeedback()
    }

    /// Subtle haptic only (no repeated sound) while reordering cards.
    private func triggerDragFeedback() {
        guard hapticFeedback else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    func toggleCategoryHidden(_ id: String) {
        if hiddenCategoryIds.contains(id) {
            hiddenCategoryIds.removeAll { $0 == id }
            triggerFeedback()
        } else {
            guard canHideMoreCategories else { return }
            hiddenCategoryIds.append(id)
            triggerFeedback()
        }
    }

    func showAllCategories() {
        guard !hiddenCategoryIds.isEmpty else { return }
        hiddenCategoryIds.removeAll()
        triggerFeedback()
    }

    func resetHomeLayout() {
        categoryOrder = unitCategories.map(\.id)
        hiddenCategoryIds.removeAll()
        triggerFeedback()
    }

    // MARK: - Measuring Tool Order

    private var measuringToolCatalog: [String] {
        MeasuringTool.allCases.map(\.rawValue)
    }

    /// Every tool in the saved order, including hidden ones. New tools are appended.
    var allMeasuringToolsInOrder: [MeasuringTool] {
        ToolOrder.merged(saved: toolOrder, catalog: measuringToolCatalog).compactMap(MeasuringTool.init(rawValue:))
    }

    /// Tools shown on the grid. User-hidden and hardware-unavailable tools are omitted.
    var orderedMeasuringTools: [MeasuringTool] {
        tools(withIDs: ToolOrder.displayedIDs(measuringToolLayout, unavailable: unavailableMeasuringToolIDs))
    }

    /// Tools the user hid that this device can still show, in the saved order.
    var hiddenMeasuringTools: [MeasuringTool] {
        let hidden = Set(measuringToolLayout.hidden.filter { !unavailableMeasuringToolIDs.contains($0) })
        return allMeasuringToolsInOrder.filter { hidden.contains($0.id) }
    }

    var canHideMoreMeasuringTools: Bool {
        orderedMeasuringTools.count > 1
    }

    private var measuringToolLayout: ToolOrder.Layout {
        ToolOrder.layout(
            savedOrder: toolOrder,
            savedHidden: hiddenMeasuringToolIds,
            catalog: measuringToolCatalog
        )
    }

    private func tools(withIDs ids: [String]) -> [MeasuringTool] {
        let byID = Dictionary(uniqueKeysWithValues: MeasuringTool.allCases.map { ($0.rawValue, $0) })
        return ids.compactMap { byID[$0] }
    }

    func moveMeasuringTool(_ draggedId: String, to targetId: String) {
        let current = allMeasuringToolsInOrder.map(\.rawValue)
        guard let updated = ToolOrder.moving(current, dragged: draggedId, to: targetId) else { return }
        toolOrder = updated
        triggerDragFeedback()
    }

    func moveMeasuringToolEarlier(_ id: String) {
        let current = allMeasuringToolsInOrder.map(\.rawValue)
        guard let updated = ToolOrder.movingEarlier(current, id: id) else { return }
        toolOrder = updated
        triggerDragFeedback()
    }

    func moveMeasuringToolLater(_ id: String) {
        let current = allMeasuringToolsInOrder.map(\.rawValue)
        guard let updated = ToolOrder.movingLater(current, id: id) else { return }
        toolOrder = updated
        triggerDragFeedback()
    }

    func toggleMeasuringToolHidden(_ id: String) {
        guard let updated = ToolOrder.togglingHidden(
            measuringToolLayout,
            id: id,
            unavailable: unavailableMeasuringToolIDs
        ) else { return }
        hiddenMeasuringToolIds = updated.hidden
        triggerFeedback()
    }

    func showAllMeasuringTools() {
        guard !hiddenMeasuringToolIds.isEmpty else { return }
        hiddenMeasuringToolIds.removeAll()
        triggerFeedback()
    }

    func resetMeasuringToolOrder() {
        toolOrder = MeasuringTool.allCases.map(\.rawValue)
        hiddenMeasuringToolIds.removeAll()
        triggerFeedback()
    }

    private var historyFileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("conversion_history.json")
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            try? data.write(to: historyFileURL, options: .atomic)
        }
    }

    private func loadHistory() -> [ConversionRecord] {
        if let data = try? Data(contentsOf: historyFileURL),
           let saved = try? JSONDecoder().decode([ConversionRecord].self, from: data) {
            return saved
        }
        // Migrate legacy UserDefaults history
        if let legacyData = UserDefaults.standard.data(forKey: "conversion_history_data"),
           let saved = try? JSONDecoder().decode([ConversionRecord].self, from: legacyData) {
            UserDefaults.standard.removeObject(forKey: "conversion_history_data")
            return saved
        }
        return []
    }

    private init() {
        unavailableMeasuringToolIDs = Set(MeasuringTool.allCases.map(\.rawValue))
            .subtracting(MeasuringToolHardware.availableIDs())

        if let savedLang = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: savedLang) {
            appLanguage = lang
        } else {
            // Detect device language on first launch
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "ar"
            appLanguage = preferred.hasPrefix("ar") ? .arabic : .english
        }

        if let savedFavorites = UserDefaults.standard.stringArray(forKey: "favorites_ids") {
            favorites = savedFavorites
        }

        if let savedOrder = UserDefaults.standard.stringArray(forKey: "home_category_order") {
            categoryOrder = savedOrder
        }
        if let savedHidden = UserDefaults.standard.stringArray(forKey: "home_hidden_categories") {
            hiddenCategoryIds = savedHidden
        }
        if let savedToolOrder = UserDefaults.standard.stringArray(forKey: ToolOrder.defaultsKey) {
            toolOrder = savedToolOrder
        }
        if let savedHiddenTools = UserDefaults.standard.stringArray(forKey: ToolOrder.hiddenDefaultsKey) {
            hiddenMeasuringToolIds = savedHiddenTools
        }

        history = loadHistory()

        if let savedMaxDigits = UserDefaults.standard.object(forKey: "maxDecimalDigits") as? Int {
            maxDecimalDigits = savedMaxDigits
        }
        if let savedScientific = UserDefaults.standard.object(forKey: "useScientificNotation") as? Bool {
            useScientificNotation = savedScientific
        }
        if let savedThousands = UserDefaults.standard.object(forKey: "useThousandsSeparator") as? Bool {
            useThousandsSeparator = savedThousands
        }
        if let savedSound = UserDefaults.standard.object(forKey: "soundEffects") as? Bool {
            soundEffects = savedSound
        }
        if let savedHaptic = UserDefaults.standard.object(forKey: "hapticFeedback") as? Bool {
            hapticFeedback = savedHaptic
        }
        if let savedHistory = UserDefaults.standard.object(forKey: "showConversionHistory") as? Bool {
            showConversionHistory = savedHistory
        }
        if let savedScheme = UserDefaults.standard.string(forKey: "appColorScheme"),
           let scheme = AppColorScheme(rawValue: savedScheme) {
            appColorScheme = scheme
        }

        reviewTracker = ReviewPromptTracker.load(from: .standard)
    }

    /// Records one conversion attempt toward the automatic review prompt.
    /// Reloads and invalid input leave the saved count unchanged.
    @discardableResult
    func registerSuccessfulConversion(
        normalizedInput: String,
        result: Double?,
        signature: String,
        isReload: Bool
    ) -> ReviewPromptTracker.Outcome {
        let outcome = reviewTracker.record(
            normalizedInput: normalizedInput,
            result: result,
            signature: signature,
            isReload: isReload,
            currentVersion: Self.marketingVersion
        )
        if outcome.counted {
            reviewTracker.save(to: .standard)
        }
        return outcome
    }

    /// Call after `requestReview()` so this app version is not asked again.
    func markReviewRequestedForCurrentVersion() {
        reviewTracker.markReviewRequested(version: Self.marketingVersion)
        reviewTracker.save(to: .standard)
    }

    func isFavorite(_ categoryId: String) -> Bool {
        favorites.contains(categoryId)
    }

    func toggleFavorite(_ categoryId: String) {
        if isFavorite(categoryId) {
            favorites.removeAll(where: { $0 == categoryId })
        } else {
            favorites.append(categoryId)
        }
        triggerFeedback()
    }

    func addHistoryRecord(category: UnitCategory, fromVal: String, fromUnit: Unit, toVal: String, toUnit: Unit) {
        guard showConversionHistory, !fromVal.isEmpty, toVal != "—", toVal != l10n.error else { return }

        if let first = history.first,
           first.fromValue == fromVal && first.fromUnitNameAr == fromUnit.nameAr && first.toUnitNameAr == toUnit.nameAr {
            return
        }

        let record = ConversionRecord(
            categoryId: category.id,
            categoryTitleAr: category.titleAr,
            categoryTitleEn: category.titleEn,
            categoryIcon: category.icon,
            fromValue: fromVal,
            fromUnitNameAr: fromUnit.nameAr,
            fromUnitNameEn: fromUnit.nameEn,
            toValue: toVal,
            toUnitNameAr: toUnit.nameAr,
            toUnitNameEn: toUnit.nameEn,
            timestamp: Date()
        )

        history.insert(record, at: 0)
        if history.count > 40 {
            history.removeLast()
        }
    }

    var pinnedRecords: [ConversionRecord] {
        history.filter { $0.isPinned }
    }

    var regularRecords: [ConversionRecord] {
        history.filter { !$0.isPinned }
    }

    func togglePin(_ id: UUID) {
        guard let idx = history.firstIndex(where: { $0.id == id }) else { return }
        var record = history[idx]
        record.isPinned.toggle()
        history[idx] = record
        triggerFeedback()
    }

    func deleteRecord(_ id: UUID) {
        history.removeAll { $0.id == id }
        triggerFeedback()
    }

    func clearHistory() {
        history.removeAll { !$0.isPinned }
        triggerFeedback()
    }

    func triggerFeedback(impact: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: impact)
            generator.prepare()
            generator.impactOccurred()
        }
        if soundEffects {
            AudioServicesPlaySystemSound(1104)
        }
    }
}
