import XCTest
@testable import Miqyas

final class ToolOrderTests: XCTestCase {
    private let catalog = ["level", "compass", "sound"]
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ToolOrderTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testEmptySavedOrderUsesCatalogOrder() {
        XCTAssertEqual(ToolOrder.merged(saved: [], catalog: catalog), catalog)
        XCTAssertEqual(ToolOrder.load(from: defaults, catalog: catalog), catalog)
    }

    func testSavedPermutationIsKept() {
        let saved = ["sound", "level", "compass"]
        XCTAssertEqual(ToolOrder.merged(saved: saved, catalog: catalog), saved)
    }

    func testUnknownIdsAreDroppedAndDuplicatesCollapse() {
        let saved = ["sound", "missing", "sound", "level", "level"]
        XCTAssertEqual(
            ToolOrder.merged(saved: saved, catalog: catalog),
            ["sound", "level", "compass"]
        )
    }

    func testNewToolsAppendAfterTheSavedOrder() {
        let saved = ["sound", "level"]
        let expanded = ["level", "compass", "sound", "ruler"]
        XCTAssertEqual(
            ToolOrder.merged(saved: saved, catalog: expanded),
            ["sound", "level", "compass", "ruler"]
        )
    }

    func testPersistedOrderMergesNewToolsAtTheEnd() {
        let reordered = ToolOrder.moving(catalog, dragged: "sound", to: "level")
        XCTAssertEqual(reordered, ["sound", "level", "compass"] as [String]?)
        ToolOrder.save(reordered ?? [], to: defaults)

        let loaded = ToolOrder.load(from: defaults, catalog: ["level", "compass", "sound", "altimeter"])
        XCTAssertEqual(loaded, ["sound", "level", "compass", "altimeter"])
        XCTAssertEqual(defaults.stringArray(forKey: ToolOrder.defaultsKey), ["sound", "level", "compass"])
    }

    func testMoveEarlierAndLater() {
        XCTAssertEqual(ToolOrder.movingEarlier(catalog, id: "compass"), ["compass", "level", "sound"] as [String]?)
        XCTAssertEqual(ToolOrder.movingLater(catalog, id: "compass"), ["level", "sound", "compass"] as [String]?)
        XCTAssertNil(ToolOrder.movingEarlier(catalog, id: "level"))
        XCTAssertNil(ToolOrder.movingLater(catalog, id: "sound"))
        XCTAssertNil(ToolOrder.moving(catalog, dragged: "level", to: "level"))
        XCTAssertNil(ToolOrder.moving(catalog, dragged: "missing", to: "level"))
    }

    func testHideAndShowPersist() {
        var layout = ToolOrder.layout(savedOrder: catalog, savedHidden: [], catalog: catalog)
        layout = ToolOrder.togglingHidden(layout, id: "compass") ?? layout
        XCTAssertEqual(layout.hidden, ["compass"])
        XCTAssertEqual(layout.visible, ["level", "sound"])
        ToolOrder.saveLayout(layout, to: defaults)

        let loaded = ToolOrder.loadLayout(from: defaults, catalog: catalog)
        XCTAssertEqual(loaded.hidden, ["compass"])
        XCTAssertFalse(loaded.visible.contains("compass"))

        let shown = ToolOrder.togglingHidden(loaded, id: "compass")
        XCTAssertEqual(shown?.hidden, [])
        XCTAssertEqual(shown?.visible, catalog)
        ToolOrder.saveLayout(shown ?? loaded, to: defaults)
        XCTAssertEqual(ToolOrder.loadLayout(from: defaults, catalog: catalog).hidden, [])
    }

    func testNewToolsAreAppendedAndStayVisible() {
        let savedOrder = ["sound", "level"]
        let savedHidden = ["sound", "removed-tool"]
        let expanded = ["level", "compass", "sound", "ruler"]
        let layout = ToolOrder.layout(savedOrder: savedOrder, savedHidden: savedHidden, catalog: expanded)

        XCTAssertEqual(layout.order, ["sound", "level", "compass", "ruler"])
        XCTAssertEqual(layout.hidden, ["sound"])
        XCTAssertEqual(layout.visible, ["level", "compass", "ruler"])
        XCTAssertFalse(layout.hidden.contains("ruler"))
        XCTAssertFalse(layout.hidden.contains("compass"))
    }

    func testSettingsResetClearsHiddenToolsAndRestoresOrder() {
        let layout = ToolOrder.layout(savedOrder: ["sound", "level", "compass"], savedHidden: ["level", "sound"], catalog: catalog)
        ToolOrder.saveLayout(layout, to: defaults)
        XCTAssertFalse(ToolOrder.loadLayout(from: defaults, catalog: catalog).hidden.isEmpty)

        let reset = ToolOrder.reset(catalog: catalog)
        ToolOrder.saveLayout(reset, to: defaults)

        let loaded = ToolOrder.loadLayout(from: defaults, catalog: catalog)
        XCTAssertEqual(loaded.order, catalog)
        XCTAssertEqual(loaded.hidden, [])
        XCTAssertEqual(loaded.visible, catalog)
        XCTAssertEqual(defaults.stringArray(forKey: ToolOrder.hiddenDefaultsKey), [])
    }

    func testCannotHideTheLastVisibleTool() {
        let layout = ToolOrder.layout(savedOrder: catalog, savedHidden: ["level", "compass"], catalog: catalog)
        XCTAssertEqual(layout.visible, ["sound"])
        XCTAssertNil(ToolOrder.togglingHidden(layout, id: "sound"))
    }

    func testDefaultCatalogOrderIsTheFreshInstallAndResetOrder() {
        let catalog = MeasuringTool.allCases.map(\.rawValue)
        XCTAssertEqual(
            catalog,
            [
                "compass", "ar", "light", "speedometer", "level", "ruler",
                "protractor", "sound", "pedometer", "barometer", "magnetometer", "seismometer"
            ]
        )
        XCTAssertEqual(ToolOrder.merged(saved: [], catalog: catalog), catalog)
        let reset = ToolOrder.reset(catalog: catalog)
        XCTAssertEqual(reset.order, catalog)
        XCTAssertEqual(reset.hidden, [])
        XCTAssertEqual(reset.visible, catalog)
    }

    func testUpgradeKeepsASavedOrderAndAppendsMissingToolsInCatalogOrder() {
        let saved = ["sound", "level", "compass"]
        let catalog = MeasuringTool.allCases.map(\.rawValue)
        let merged = ToolOrder.merged(saved: saved, catalog: catalog)
        XCTAssertEqual(
            merged,
            [
                "sound", "level", "compass",
                "ar", "light", "speedometer", "ruler", "protractor",
                "pedometer", "barometer", "magnetometer", "seismometer"
            ]
        )
    }

    func testUnavailableToolsStayInTheOrderAndDoNotCountAsTheLastCard() {
        let catalog = ["level", "compass", "sound", "ruler", "barometer"]
        let layout = ToolOrder.layout(savedOrder: ["sound", "level", "compass"], savedHidden: [], catalog: catalog)
        XCTAssertEqual(layout.order, ["sound", "level", "compass", "ruler", "barometer"])

        let unavailable: Set<String> = ["compass", "sound", "ruler", "barometer"]
        XCTAssertEqual(ToolOrder.displayedIDs(layout, unavailable: unavailable), ["level"])
        XCTAssertNil(ToolOrder.togglingHidden(layout, id: "level", unavailable: unavailable))
        XCTAssertNil(ToolOrder.togglingHidden(layout, id: "barometer", unavailable: unavailable))

        let hidden = ToolOrder.togglingHidden(layout, id: "sound", unavailable: ["ruler", "barometer"])
        XCTAssertEqual(hidden?.order, layout.order)
        XCTAssertEqual(hidden?.hidden, ["sound"])
        XCTAssertTrue(hidden?.order.contains("barometer") == true)
        XCTAssertEqual(
            ToolOrder.displayedIDs(hidden ?? layout, unavailable: ["ruler", "barometer"]),
            ["level", "compass"]
        )
    }
}
