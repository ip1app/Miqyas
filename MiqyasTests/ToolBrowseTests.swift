import XCTest
@testable import Miqyas

final class ToolBrowseTests: XCTestCase {
    private let visible = [
        "sound", "level", "compass", "ar", "light", "speedometer",
        "ruler", "protractor", "pedometer", "barometer"
    ]
    private let names: [String: ToolBrowse.Name] = [
        "compass": .init(arabicTitle: "البوصلة والقبلة", englishTitle: "Compass & Qibla", arabicSubtitle: "اتجاه القبلة", englishSubtitle: "Qibla direction"),
        "ar": .init(arabicTitle: "قياس معزّز", englishTitle: "AR Measure", arabicSubtitle: "المسافة والمساحة", englishSubtitle: "Distance and area"),
        "light": .init(arabicTitle: "مقياس الضوء", englishTitle: "Light Meter", arabicSubtitle: "لوكس تقريبي", englishSubtitle: "Approximate lux"),
        "speedometer": .init(arabicTitle: "عداد السرعة", englishTitle: "Speedometer", arabicSubtitle: "سرعة الموقع", englishSubtitle: "GPS speed"),
        "level": .init(arabicTitle: "ميزان استواء", englishTitle: "Level", arabicSubtitle: "فقاعة وزاوية", englishSubtitle: "Bubble and angle"),
        "ruler": .init(arabicTitle: "مسطرة الشاشة", englishTitle: "Screen Ruler", arabicSubtitle: "سنتيمتر وبوصة", englishSubtitle: "Centimeters and inches"),
        "sound": .init(arabicTitle: "مقياس الصوت", englishTitle: "Sound Meter", arabicSubtitle: "مستوى تقريبي", englishSubtitle: "Approximate level"),
        "protractor": .init(arabicTitle: "منقلة", englishTitle: "Protractor", arabicSubtitle: "الميل والزاوية", englishSubtitle: "Tilt and angle"),
        "pedometer": .init(arabicTitle: "عداد الخطوات", englishTitle: "Pedometer", arabicSubtitle: "الخطوات والمسافة", englishSubtitle: "Steps and distance"),
        "barometer": .init(arabicTitle: "مقياس الضغط", englishTitle: "Barometer", arabicSubtitle: "الضغط والارتفاع", englishSubtitle: "Pressure and altitude")
    ]

    func testAllKeepsTheVisibleOrder() {
        let ids = ToolBrowse.matchingIDs(
            orderedVisible: visible,
            filter: .all,
            favorites: ["ar"],
            query: "  ",
            names: names
        )
        XCTAssertEqual(ids, visible)
    }

    func testPopularUsesDefaultOrderAndSkipsHiddenOrUnavailable() {
        let ids = ToolBrowse.matchingIDs(
            orderedVisible: visible,
            filter: .popular,
            favorites: [],
            query: "",
            names: names
        )
        XCTAssertEqual(ids, ["compass", "ar", "light", "speedometer", "level", "ruler"])
        XCTAssertFalse(ids.contains("sound"))
    }

    func testPopularOmitsAToolThatIsNotVisible() {
        let withoutRuler = visible.filter { $0 != "ruler" }
        let ids = ToolBrowse.matchingIDs(
            orderedVisible: withoutRuler,
            filter: .popular,
            favorites: ["ruler"],
            query: "",
            names: names
        )
        XCTAssertEqual(ids, ["compass", "ar", "light", "speedometer", "level"])
    }

    func testFavoritesFollowTheVisibleOrder() {
        let ids = ToolBrowse.matchingIDs(
            orderedVisible: visible,
            filter: .favorites,
            favorites: ["ruler", "compass", "missing"],
            query: "",
            names: names
        )
        XCTAssertEqual(ids, ["compass", "ruler"])
    }

    func testSearchMatchesArabicOrEnglishOnTopOfTheFilter() {
        let english = ToolBrowse.matchingIDs(
            orderedVisible: visible,
            filter: .popular,
            favorites: [],
            query: "light",
            names: names
        )
        XCTAssertEqual(english, ["light"])

        let arabic = ToolBrowse.matchingIDs(
            orderedVisible: visible,
            filter: .all,
            favorites: [],
            query: "مسطرة",
            names: names
        )
        XCTAssertEqual(arabic, ["ruler"])

        let favoritesSearch = ToolBrowse.matchingIDs(
            orderedVisible: visible,
            filter: .favorites,
            favorites: ["level", "sound"],
            query: "BUBBLE",
            names: names
        )
        XCTAssertEqual(favoritesSearch, ["level"])
    }

    func testFavoritesPersistAndDropUnknownIds() {
        let suite = "ToolBrowseTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let catalog = MeasuringTool.allCases.map(\.rawValue)

        var favorites = ToolFavorites.toggling([], id: "compass")
        favorites = ToolFavorites.toggling(favorites, id: "ruler")
        XCTAssertEqual(favorites, ["compass", "ruler"])
        favorites = ToolFavorites.toggling(favorites, id: "compass")
        XCTAssertEqual(favorites, ["ruler"])
        favorites = ToolFavorites.toggling(favorites, id: "compass")

        ToolFavorites.save(favorites + ["missing", "compass"], to: defaults)
        XCTAssertEqual(ToolFavorites.load(from: defaults, catalog: catalog), ["ruler", "compass"])

        ToolFavorites.save([], to: defaults)
        XCTAssertEqual(ToolFavorites.load(from: defaults, catalog: catalog), [])
        XCTAssertEqual(defaults.stringArray(forKey: ToolFavorites.defaultsKey), [])
        defaults.removePersistentDomain(forName: suite)
    }
}
