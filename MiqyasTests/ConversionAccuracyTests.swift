import UIKit
import XCTest
@testable import Miqyas

/// Reads the app catalog from the main actor, where `unitCategories` lives.
@MainActor
private func convert(_ value: Double, from source: String, to destination: String, in categoryId: String) -> Double {
    let units = unitCategories.first { $0.id == categoryId }?.units ?? []
    guard let fromUnit = units.first(where: { $0.abbreviation == source }),
          let toUnit = units.first(where: { $0.abbreviation == destination }) else {
        XCTFail("Missing \(source) or \(destination) in \(categoryId)")
        return .nan
    }
    return toUnit.fromBase(fromUnit.toBase(value))
}

private func expectClose(
    _ actual: Double,
    _ expected: Double,
    relative: Double = 1e-9,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(actual.isFinite, "Non-finite result \(actual)", file: file, line: line)
    let scale = max(abs(expected), 1e-30)
    XCTAssertEqual(actual, expected, accuracy: scale * relative, file: file, line: line)
}

final class ConversionAccuracyTests: XCTestCase {

    // MARK: Catalog

    func testCatalogShapeNamesAndIcons() async {
        let snapshot = await MainActor.run { () -> (ids: [String], counts: [String: Int], problems: [String], icons: [String]) in
            var problems: [String] = []
            var counts: [String: Int] = [:]
            var seenUnitIDs = Set<String>()
            let ids = unitCategories.map(\.id)
            if Set(ids).count != ids.count {
                problems.append("duplicate category id")
            }
            let expectedCounts = [
                "length": 14, "weight": 17, "temperature": 4, "volume": 20,
                "speed": 7, "time": 12, "area": 14, "digital": 10,
                "energy": 10, "pressure": 11, "power": 8, "fuel": 7,
                "angle": 7, "frequency": 7, "force": 5, "torque": 4,
                "density": 4, "data-rate": 9
            ]
            for category in unitCategories {
                counts[category.id] = category.units.count
                if category.titleAr.isEmpty || category.titleEn.isEmpty || category.icon.isEmpty {
                    problems.append("blank category text \(category.id)")
                }
                if !category.titleAr.contains(where: { ("\u{0600}"..."\u{06FF}").contains($0) }) {
                    problems.append("category \(category.id) title is not Arabic")
                }
                var abbreviations = Set<String>()
                for unit in category.units {
                    if !abbreviations.insert(unit.abbreviation).inserted {
                        problems.append("duplicate abbreviation \(unit.abbreviation) in \(category.id)")
                    }
                    if !seenUnitIDs.insert(unit.id).inserted {
                        problems.append("duplicate unit id \(unit.id)")
                    }
                    if unit.nameAr.isEmpty || unit.nameEn.isEmpty || unit.abbreviation.isEmpty {
                        problems.append("blank unit in \(category.id)")
                    }
                    if !unit.nameAr.contains(where: { ("\u{0600}"..."\u{06FF}").contains($0) }) {
                        problems.append("\(category.id)/\(unit.abbreviation) has no Arabic name")
                    }
                    if !unit.nameEn.contains(where: { $0.isASCII && $0.isLetter }) {
                        problems.append("\(category.id)/\(unit.abbreviation) has no English name")
                    }
                }
            }
            if counts != expectedCounts {
                problems.append("unexpected unit counts \(counts)")
            }
            let icons = unitCategories.map(\.icon)
            return (ids, counts, problems, icons)
        }

        XCTAssertEqual(snapshot.problems, [])
        XCTAssertEqual(snapshot.ids.count, 18)
        XCTAssertEqual(snapshot.counts.values.reduce(0, +), 170)
        for id in ["length", "weight", "temperature", "volume", "speed", "time", "area", "digital", "energy", "pressure", "power", "fuel", "angle", "frequency"] {
            XCTAssertTrue(snapshot.ids.contains(id), "removed existing category \(id)")
        }
        for id in ["force", "torque", "density", "data-rate"] {
            XCTAssertTrue(snapshot.ids.contains(id), "missing new category \(id)")
        }

        let missingIcons = await MainActor.run {
            snapshot.icons.filter { UIImage(systemName: $0) == nil }
        }
        XCTAssertEqual(missingIcons, [])
    }

    func testNoTwoUnitsInACategoryShareAFactor() async {
        let probes = [0.0, 1.0, -1.0, 2.0, 10.0, 32.0, 100.0, 0.25, 1_000.0]
        let duplicates = await MainActor.run { () -> [String] in
            var found: [String] = []
            for category in unitCategories {
                let units = category.units
                for leftIndex in units.indices {
                    for rightIndex in units.indices where rightIndex > leftIndex {
                        let left = units[leftIndex]
                        let right = units[rightIndex]
                        let sameFactor = probes.allSatisfy { sample in
                            left.toBase(sample) == right.toBase(sample)
                                && left.fromBase(sample) == right.fromBase(sample)
                        }
                        if sameFactor {
                            found.append("\(category.id): \(left.abbreviation) == \(right.abbreviation)")
                        }
                    }
                }
            }
            return found
        }
        XCTAssertEqual(duplicates, [])
    }

    func testBinaryAndDecimalNamesStayExplicit() async {
        let names = await MainActor.run { () -> [String: (ar: String, en: String)] in
            var map: [String: (ar: String, en: String)] = [:]
            for category in unitCategories where category.id == "digital" || category.id == "data-rate" {
                for unit in category.units {
                    map["\(category.id)/\(unit.abbreviation)"] = (unit.nameAr, unit.nameEn)
                }
            }
            return map
        }
        func expectLabel(_ key: String, english: String, arabic: String, file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertTrue(names[key]?.en.contains(english) == true, key, file: file, line: line)
            XCTAssertTrue(names[key]?.ar.contains(arabic) == true, key, file: file, line: line)
        }
        for abbreviation in ["KB", "MB", "GB", "TB", "PB"] {
            expectLabel("digital/\(abbreviation)", english: "Binary", arabic: "ثنائي")
        }
        for abbreviation in ["MB (SI)", "GB (SI)", "TB (SI)"] {
            expectLabel("digital/\(abbreviation)", english: "Decimal", arabic: "عشري")
        }
        for abbreviation in ["kbit/s", "Mbit/s", "Gbit/s", "kB/s", "MB/s"] {
            expectLabel("data-rate/\(abbreviation)", english: "Decimal", arabic: "عشري")
        }
        for abbreviation in ["KiB/s", "MiB/s"] {
            expectLabel("data-rate/\(abbreviation)", english: "Binary", arabic: "ثنائي")
        }
        // Original storage factors stay binary (1024^n).
        expectClose(await convert(1, from: "KB", to: "B", in: "digital"), 1024)
        expectClose(await convert(1, from: "MB", to: "B", in: "digital"), 1_048_576)
        expectClose(await convert(1, from: "GB", to: "B", in: "digital"), 1_073_741_824)
        expectClose(await convert(1, from: "TB", to: "B", in: "digital"), 1_099_511_627_776)
    }

    func testEveryUnitRoundTrips() async {
        let failures = await MainActor.run { () -> [String] in
            var failures: [String] = []
            for category in unitCategories {
                let anchor = category.units[0]
                for unit in category.units {
                    for sample in [1.0, 12.5, 0.25] {
                        let back = unit.fromBase(unit.toBase(sample))
                        if !back.isFinite || abs(back - sample) > max(abs(sample) * 1e-9, 1e-9) {
                            failures.append("\(category.id) \(unit.abbreviation) round-trip \(sample) -> \(back)")
                        }
                        let viaAnchor = unit.fromBase(anchor.toBase(anchor.fromBase(unit.toBase(sample))))
                        if !viaAnchor.isFinite || abs(viaAnchor - sample) > max(abs(sample) * 1e-8, 1e-8) {
                            failures.append("\(category.id) \(unit.abbreviation) via \(anchor.abbreviation) \(sample) -> \(viaAnchor)")
                        }
                    }
                }
            }
            return failures
        }
        XCTAssertEqual(failures, [])
    }

    // MARK: Existing anchors (must not drift)

    func testExistingLengthMassAndTemperature() async {
        expectClose(await convert(1, from: "km", to: "m", in: "length"), 1000)
        expectClose(await convert(1, from: "lb", to: "kg", in: "weight"), 0.45359237)
        expectClose(await convert(0, from: "°C", to: "°F", in: "temperature"), 32)
        expectClose(await convert(100, from: "°C", to: "°F", in: "temperature"), 212)
        expectClose(await convert(-40, from: "°C", to: "°F", in: "temperature"), -40)
        expectClose(await convert(0, from: "°C", to: "K", in: "temperature"), 273.15)
        expectClose(await convert(1, from: "kWh", to: "J", in: "energy"), 3_600_000)
        expectClose(await convert(10, from: "L/100km", to: "km/L", in: "fuel"), 10)
        expectClose(await convert(235.215, from: "L/100km", to: "mpg US", in: "fuel"), 1)
    }

    // MARK: Length, mass, time

    func testNewLengthUnits() async {
        expectClose(await convert(1, from: "dm", to: "m", in: "length"), 0.1)
        expectClose(await convert(1, from: "µm", to: "m", in: "length"), 1e-6)
        expectClose(await convert(1, from: "nm", to: "mm", in: "length"), 1e-6)
        // IAU 2012 astronomical unit, exact.
        expectClose(await convert(1, from: "au", to: "m", in: "length"), 149_597_870_700)
        // Julian year × c.
        expectClose(await convert(1, from: "ly", to: "m", in: "length"), 299_792_458 * 365.25 * 86_400, relative: 1e-12)
    }

    func testNewMassUnits() async {
        // NIST grain 64.79891 mg. Troy ounce = 480 gr. Tola = 180 gr.
        expectClose(await convert(1, from: "gr", to: "mg", in: "weight"), 64.79891)
        expectClose(await convert(1, from: "oz t", to: "g", in: "weight"), 31.1034768)
        expectClose(await convert(1, from: "tola", to: "g", in: "weight"), 11.6638038)
        expectClose(await convert(10, from: "tola", to: "g", in: "weight"), 116.638038)
        expectClose(await convert(1, from: "q", to: "kg", in: "weight"), 100)
        expectClose(await convert(1, from: "st", to: "lb", in: "weight"), 14, relative: 1e-8)
        expectClose(await convert(1, from: "sh tn", to: "lb", in: "weight"), 2000, relative: 1e-8)
        expectClose(await convert(1, from: "long tn", to: "lb", in: "weight"), 2240, relative: 1e-8)
        expectClose(await convert(1, from: "mth", to: "g", in: "weight"), 4.25)
        expectClose(await convert(1, from: "drm", to: "g", in: "weight"), 2.975)
        expectClose(await convert(20, from: "mth", to: "drm", in: "weight"), 20 * 4.25 / 2.975)
        expectClose(await convert(1, from: "mth IQ", to: "g", in: "weight"), 5)
    }

    func testRankineAndShortDurations() async {
        expectClose(await convert(0, from: "°C", to: "°R", in: "temperature"), 273.15 * 9 / 5)
        expectClose(await convert(0, from: "°R", to: "°C", in: "temperature"), -273.15)
        expectClose(await convert(100, from: "°C", to: "°R", in: "temperature"), 273.15 * 9 / 5 + 180)
        expectClose(await convert(1, from: "ms", to: "s", in: "time"), 0.001)
        expectClose(await convert(1, from: "µs", to: "ns", in: "time"), 1000)
        expectClose(await convert(1, from: "dec", to: "yr", in: "time"), 10)
        expectClose(await convert(1, from: "cy", to: "yr", in: "time"), 100)
    }

    // MARK: Volume, area, speed

    func testCookingVolumeAndOilBarrel() async {
        expectClose(await convert(1, from: "mL", to: "L", in: "volume"), 0.001)
        expectClose(await convert(1, from: "ft³", to: "L", in: "volume"), 28.316846592, relative: 1e-12)
        expectClose(await convert(1, from: "in³", to: "L", in: "volume"), 0.016387064, relative: 1e-12)
        // US gallon = 3.785411784 L. Teaspoon = gallon / 768.
        expectClose(await convert(1, from: "pt", to: "L", in: "volume"), 3.785411784 / 8)
        expectClose(await convert(1, from: "qt", to: "L", in: "volume"), 3.785411784 / 4)
        expectClose(await convert(1, from: "tsp", to: "L", in: "volume"), 3.785411784 / 768)
        expectClose(await convert(1, from: "gal UK", to: "L", in: "volume"), 4.54609)
        expectClose(await convert(1, from: "pt UK", to: "gal UK", in: "volume"), 0.125)
        expectClose(await convert(1, from: "cup m", to: "mL", in: "volume"), 250)
        expectClose(await convert(1, from: "tbsp m", to: "mL", in: "volume"), 15)
        expectClose(await convert(3, from: "tsp m", to: "tbsp m", in: "volume"), 1)
        // API barrel = 42 exact US gallons.
        expectClose(await convert(1, from: "bbl", to: "L", in: "volume"), 42 * 3.785411784, relative: 1e-12)
        expectClose(await convert(1, from: "sa", to: "L", in: "volume"), 2.75)
        expectClose(await convert(4, from: "mudd", to: "sa", in: "volume"), 1)
    }

    func testAreaUnitsUsedLocally() async {
        expectClose(await convert(1, from: "ac", to: "m²", in: "area"), 4046.8564224, relative: 1e-12)
        expectClose(await convert(1, from: "mi²", to: "m²", in: "area"), 1609.344 * 1609.344, relative: 1e-12)
        expectClose(await convert(1, from: "yd²", to: "m²", in: "area"), 0.83612736, relative: 1e-12)
        expectClose(await convert(1, from: "in²", to: "cm²", in: "area"), 6.4516, relative: 1e-12)
        // Metric dunam stays 1,000 m². Iraqi donum is 2,500 m².
        expectClose(await convert(1, from: "dunam", to: "m²", in: "area"), 1000)
        expectClose(await convert(1, from: "donum IQ", to: "m²", in: "area"), 2500)
        expectClose(await convert(24, from: "qirat", to: "fed", in: "area"), 1)
        expectClose(await convert(1, from: "cm²", to: "mm²", in: "area"), 100)
    }

    func testSpeedFeetAndKilometresPerSecond() async {
        expectClose(await convert(1, from: "ft/s", to: "m/s", in: "speed"), 0.3048)
        expectClose(await convert(1, from: "km/s", to: "m/s", in: "speed"), 1000)
    }

    // MARK: Storage, energy, pressure, power

    func testStorageAndTransferRate() async {
        expectClose(await convert(8, from: "bit", to: "B", in: "digital"), 1)
        expectClose(await convert(1, from: "PB", to: "TB", in: "digital"), 1024)
        expectClose(await convert(1, from: "GB (SI)", to: "B", in: "digital"), 1_000_000_000)
        // A decimal gigabyte is smaller than the binary gigabyte already in the app.
        let decimal = await convert(1, from: "GB (SI)", to: "B", in: "digital")
        let binary = await convert(1, from: "GB", to: "B", in: "digital")
        XCTAssertLessThan(decimal, binary)

        expectClose(await convert(1, from: "B/s", to: "bit/s", in: "data-rate"), 8)
        expectClose(await convert(1, from: "Mbit/s", to: "bit/s", in: "data-rate"), 1_000_000)
        expectClose(await convert(8, from: "Mbit/s", to: "MB/s", in: "data-rate"), 1)
        expectClose(await convert(1, from: "MiB/s", to: "bit/s", in: "data-rate"), 8 * 1024 * 1024)
        expectClose(await convert(1, from: "KiB/s", to: "bit/s", in: "data-rate"), 8 * 1024)
        expectClose(await convert(1, from: "Gbit/s", to: "Mbit/s", in: "data-rate"), 1000)
    }

    func testEnergyPressureAndPower() async {
        expectClose(await convert(1, from: "Wh", to: "J", in: "energy"), 3600)
        expectClose(await convert(1, from: "kWh", to: "Wh", in: "energy"), 1000)
        expectClose(await convert(1, from: "MWh", to: "kWh", in: "energy"), 1000)
        expectClose(await convert(1, from: "BTU", to: "J", in: "energy"), 1_055.05585262)
        expectClose(await convert(1, from: "ft·lbf", to: "J", in: "energy"), 0.3048 * 0.45359237 * 9.80665)
        expectClose(await convert(1, from: "eV", to: "J", in: "energy"), 1.602176634e-19)

        expectClose(await convert(1, from: "hPa", to: "Pa", in: "pressure"), 100)
        expectClose(await convert(1, from: "MPa", to: "bar", in: "pressure"), 10)
        expectClose(await convert(1, from: "mmHg", to: "Pa", in: "pressure"), 133.322387415)
        expectClose(await convert(760, from: "Torr", to: "atm", in: "pressure"), 1, relative: 1e-12)
        expectClose(await convert(1, from: "inHg", to: "Pa", in: "pressure"), 3386.389)
        expectClose(await convert(1, from: "kgf/cm²", to: "Pa", in: "pressure"), 98_066.5)

        // 1 ton of refrigeration = 12,000 IT BTU/h.
        expectClose(await convert(1, from: "TR", to: "W", in: "power"), 12_000 * 1_055.05585262 / 3_600)
        expectClose(await convert(1, from: "kcal/h", to: "W", in: "power"), 4184.0 / 3600)
    }

    // MARK: Fuel, angle, frequency, force, torque, density

    func testFuelEconomyIsReciprocal() async {
        expectClose(await convert(1, from: "mi/L", to: "L/100km", in: "fuel"), 100 / 1.609344)
        expectClose(await convert(1, from: "km/gal", to: "L/100km", in: "fuel"), 100 * 3.785411784)
        expectClose(await convert(1, from: "km/gal UK", to: "L/100km", in: "fuel"), 100 * 4.54609)
        // Zero stays a finite zero instead of dividing by zero.
        let zero = await convert(0, from: "km/L", to: "mi/L", in: "fuel")
        XCTAssertEqual(zero, 0)
        XCTAssertTrue(zero.isFinite)
        let zeroGallons = await convert(0, from: "L/100km", to: "km/gal", in: "fuel")
        XCTAssertEqual(zeroGallons, 0)
        XCTAssertTrue(zeroGallons.isFinite)
    }

    func testAngleFrequencyForceTorqueDensity() async {
        expectClose(await convert(60, from: "arcmin", to: "°", in: "angle"), 1)
        expectClose(await convert(3600, from: "arcsec", to: "°", in: "angle"), 1)
        expectClose(await convert(1000, from: "mrad", to: "rad", in: "angle"), 1, relative: 1e-12)

        expectClose(await convert(60, from: "RPM", to: "Hz", in: "frequency"), 1)
        expectClose(await convert(1, from: "THz", to: "GHz", in: "frequency"), 1000)
        expectClose(await convert(1, from: "mHz", to: "Hz", in: "frequency"), 0.001)

        expectClose(await convert(1, from: "kgf", to: "N", in: "force"), 9.80665)
        expectClose(await convert(1, from: "lbf", to: "N", in: "force"), 0.45359237 * 9.80665)
        expectClose(await convert(1, from: "dyn", to: "N", in: "force"), 1e-5)
        expectClose(await convert(1, from: "kN", to: "N", in: "force"), 1000)

        expectClose(await convert(1, from: "kgf·m", to: "N·m", in: "torque"), 9.80665)
        expectClose(await convert(1, from: "lbf·ft", to: "N·m", in: "torque"), 0.3048 * 0.45359237 * 9.80665)
        expectClose(await convert(12, from: "lbf·in", to: "lbf·ft", in: "torque"), 1)

        expectClose(await convert(1, from: "g/cm³", to: "kg/m³", in: "density"), 1000)
        expectClose(await convert(1, from: "lb/ft³", to: "kg/m³", in: "density"), 0.45359237 / (0.3048 * 0.3048 * 0.3048))
        expectClose(await convert(1, from: "lb/gal", to: "kg/m³", in: "density"), 0.45359237 / 0.003785411784)
    }

    // MARK: Favorites and history keep working

    func testSavedHomeOrderKeepsOldCategoriesAndAppendsNewOnes() async {
        await MainActor.run {
            let settings = AppSettings.shared
            let originalOrder = settings.categoryOrder
            let originalFavorites = settings.favorites
            let originalSound = settings.soundEffects
            let originalHaptic = settings.hapticFeedback
            settings.soundEffects = false
            settings.hapticFeedback = false
            defer {
                settings.categoryOrder = originalOrder
                settings.favorites = originalFavorites
                settings.soundEffects = originalSound
                settings.hapticFeedback = originalHaptic
            }

            settings.categoryOrder = ["temperature", "length", "weight"]
            let ids = settings.allCategoriesInOrder.map(\.id)
            XCTAssertEqual(Array(ids.prefix(3)), ["temperature", "length", "weight"])
            XCTAssertEqual(ids.count, unitCategories.count)
            for id in ["force", "torque", "density", "data-rate", "fuel", "area"] {
                XCTAssertTrue(ids.contains(id))
            }

            let wasFavorite = settings.isFavorite("torque")
            if wasFavorite {
                settings.toggleFavorite("torque")
            }
            XCTAssertFalse(settings.isFavorite("torque"))
            settings.toggleFavorite("torque")
            XCTAssertTrue(settings.isFavorite("torque"))
            settings.toggleFavorite("torque")
            XCTAssertFalse(settings.isFavorite("torque"))
            if wasFavorite {
                settings.toggleFavorite("torque")
            }
        }
    }

    func testHistoryRecordStillRoundTrips() async {
        let restored = await MainActor.run { () -> ConversionRecord in
            let record = ConversionRecord(
                categoryId: "length",
                categoryTitleAr: "الطول والمسافة",
                categoryTitleEn: "Length & Distance",
                categoryIcon: "ruler.fill",
                fromValue: "1",
                fromUnitNameAr: "كيلومتر",
                fromUnitNameEn: "Kilometer",
                toValue: "1000",
                toUnitNameAr: "متر",
                toUnitNameEn: "Meter",
                timestamp: Date(timeIntervalSince1970: 1_700_000_000)
            )
            let data = try! JSONEncoder().encode(record)
            return try! JSONDecoder().decode(ConversionRecord.self, from: data)
        }
        XCTAssertEqual(restored.categoryId, "length")
        XCTAssertEqual(restored.categoryTitle(for: .arabic), "الطول والمسافة")
        XCTAssertEqual(restored.fromUnitName(for: .english), "Kilometer")
        XCTAssertTrue(await MainActor.run { unitCategories.contains { $0.id == restored.categoryId } })
    }
}
