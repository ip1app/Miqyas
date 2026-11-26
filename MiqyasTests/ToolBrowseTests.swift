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

    func testFavoriteListSkipsUnavailableToolsAndKeepsOrder() {
        let ordered = ["sound", "level", "compass", "ar", "ruler"]
        let listed = ToolFavorites.listed(
            ordered: ordered,
            favorites: ["ruler", "ar", "sound", "missing"],
            unavailable: ["ar"]
        )
        XCTAssertEqual(listed, ["sound", "ruler"])
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

    func testCameraMeasureStillMatchesTheOldNames() {
        let name = ToolBrowse.Name(
            arabicTitle: "مقياس بالكاميرا",
            englishTitle: "Camera Measure",
            arabicSubtitle: "المسافة والمساحة",
            englishSubtitle: "Distance and area",
            keywords: ["AR", "الواقع المعزز", "measure", "قياس معزّز", "AR Measure"]
        )
        XCTAssertTrue(name.matches("كاميرا"))
        XCTAssertTrue(name.matches("camera"))
        XCTAssertTrue(name.matches("AR"))
        XCTAssertTrue(name.matches("الواقع المعزز"))
        XCTAssertTrue(name.matches("measure"))
        XCTAssertTrue(name.matches("قياس معزّز"))
        XCTAssertFalse(name.matches("بوصلة"))
    }

    func testMeasureLineOptionsDefaultLoadAndReset() {
        let suite = "MeasureLineOptions.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        XCTAssertEqual(MeasureLineOptions.load(from: defaults), .default)
        XCTAssertEqual(MeasureLineOptions.default.color, .blue)
        XCTAssertEqual(MeasureLineOptions.default.thickness, .medium)

        defaults.set("nope", forKey: MeasureLineOptions.colorDefaultsKey)
        defaults.set("huge", forKey: MeasureLineOptions.thicknessDefaultsKey)
        XCTAssertEqual(MeasureLineOptions.load(from: defaults), .default)

        let chosen = MeasureLineOptions(color: .red, thickness: .thick)
        MeasureLineOptions.save(chosen, to: defaults)
        XCTAssertEqual(MeasureLineOptions.load(from: defaults), chosen)

        MeasureLineOptions.reset(in: defaults)
        XCTAssertEqual(MeasureLineOptions.load(from: defaults), .default)
        XCTAssertEqual(defaults.string(forKey: MeasureLineOptions.colorDefaultsKey), MeasureLineColor.blue.rawValue)
        XCTAssertEqual(defaults.string(forKey: MeasureLineOptions.thicknessDefaultsKey), MeasureLineThickness.medium.rawValue)
        defaults.removePersistentDomain(forName: suite)
    }
}
