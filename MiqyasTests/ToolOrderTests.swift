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
}
