import SwiftUI

// MARK: - Rich Unit Categories Data
//
// Linear units convert through one base per category (toBase / fromBase).
// Temperature and fuel economy are not linear: offsets and reciprocals live in
// the closures, including a zero guard so an inverse unit never yields NaN.
//
// Exact factors follow the SI brochure (BIPM) and NIST Special Publication 811
// unless a comment names a different, explicit convention (market gold weights,
// the 2.75 L ṣāʿ, the Iraqi donum). Existing factors are left unchanged.

let unitCategories: [UnitCategory] = [
    UnitCategory(
        id: "length",
        titleAr: "الطول والمسافة",
        titleEn: "Length & Distance",
        subtitleAr: "أمتار، كيلومترات، أميال...",
        subtitleEn: "Meters, Kilometers, Miles...",
        icon: "ruler.fill",
        gradientColors: [Color.blue, Color.cyan],
        units: [
            Unit(nameAr: "متر", nameEn: "Meter", abbreviation: "m", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلومتر", nameEn: "Kilometer", abbreviation: "km", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "سنتيمتر", nameEn: "Centimeter", abbreviation: "cm", toBase: { $0 / 100 }, fromBase: { $0 * 100 }),
            Unit(nameAr: "مليمتر", nameEn: "Millimeter", abbreviation: "mm", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            Unit(nameAr: "ميل", nameEn: "Mile", abbreviation: "mi", toBase: { $0 * 1609.344 }, fromBase: { $0 / 1609.344 }),
            Unit(nameAr: "قدم", nameEn: "Foot", abbreviation: "ft", toBase: { $0 * 0.3048 }, fromBase: { $0 / 0.3048 }),
            Unit(nameAr: "بوصة", nameEn: "Inch", abbreviation: "in", toBase: { $0 * 0.0254 }, fromBase: { $0 / 0.0254 }),
            Unit(nameAr: "ياردة", nameEn: "Yard", abbreviation: "yd", toBase: { $0 * 0.9144 }, fromBase: { $0 / 0.9144 }),
            Unit(nameAr: "ميل بحري", nameEn: "Nautical Mile", abbreviation: "NM", toBase: { $0 * 1852 }, fromBase: { $0 / 1852 }),
            // SI prefixes. The metre is exact (BIPM).
            Unit(nameAr: "ديسيمتر", nameEn: "Decimeter", abbreviation: "dm", toBase: { $0 * 0.1 }, fromBase: { $0 / 0.1 }),
            Unit(nameAr: "ميكرومتر", nameEn: "Micrometer", abbreviation: "µm", toBase: { $0 / 1_000_000 }, fromBase: { $0 * 1_000_000 }),
            Unit(nameAr: "نانومتر", nameEn: "Nanometer", abbreviation: "nm", toBase: { $0 / 1_000_000_000 }, fromBase: { $0 * 1_000_000_000 }),
            // IAU 2012 astronomical unit, exact.
            Unit(nameAr: "وحدة فلكية", nameEn: "Astronomical Unit", abbreviation: "au", toBase: { $0 * 149_597_870_700 }, fromBase: { $0 / 149_597_870_700 }),
            // IAU light-year: Julian year (365.25 d) × c. c = 299792458 m/s exactly (SI).
            Unit(nameAr: "سنة ضوئية", nameEn: "Light-year", abbreviation: "ly", toBase: { $0 * 299_792_458 * 365.25 * 86_400 }, fromBase: { $0 / (299_792_458 * 365.25 * 86_400) })
        ]
    ),
    UnitCategory(
        id: "weight",
        titleAr: "الوزن والكتلة",
        titleEn: "Weight & Mass",
        subtitleAr: "كيلوغرام، تولة، قنطار...",
        subtitleEn: "Kilograms, Tolas, Quintals...",
        icon: "scalemass.fill",
        gradientColors: [Color.orange, Color.yellow],
        units: [
            Unit(nameAr: "كيلوغرام", nameEn: "Kilogram", abbreviation: "kg", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "غرام", nameEn: "Gram", abbreviation: "g", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            Unit(nameAr: "ملغرام", nameEn: "Milligram", abbreviation: "mg", toBase: { $0 / 1_000_000 }, fromBase: { $0 * 1_000_000 }),
            Unit(nameAr: "طن متري", nameEn: "Metric Ton", abbreviation: "t", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "رطل (باوند)", nameEn: "Pound", abbreviation: "lb", toBase: { $0 * 0.45359237 }, fromBase: { $0 / 0.45359237 }),
            Unit(nameAr: "أونصة", nameEn: "Ounce", abbreviation: "oz", toBase: { $0 * 0.02834952 }, fromBase: { $0 / 0.02834952 }),
            Unit(nameAr: "قيراط", nameEn: "Carat", abbreviation: "ct", toBase: { $0 * 0.0002 }, fromBase: { $0 / 0.0002 }),
            // International avoirdupois pound is exact: 0.45359237 kg (NIST).
            Unit(nameAr: "ستون", nameEn: "Stone", abbreviation: "st", toBase: { $0 * 14 * 0.45359237 }, fromBase: { $0 / (14 * 0.45359237) }),
            Unit(nameAr: "طن أمريكي", nameEn: "US Short Ton", abbreviation: "sh tn", toBase: { $0 * 2000 * 0.45359237 }, fromBase: { $0 / (2000 * 0.45359237) }),
            Unit(nameAr: "طن بريطاني", nameEn: "UK Long Ton", abbreviation: "long tn", toBase: { $0 * 2240 * 0.45359237 }, fromBase: { $0 / (2240 * 0.45359237) }),
            // Grain is exact: 64.79891 mg (NIST). Troy ounce = 480 grains. Tola = 180 grains
            // (British Indian standard still used for Gulf gold bars, including the 10-tola bar).
            Unit(nameAr: "حبة", nameEn: "Grain", abbreviation: "gr", toBase: { $0 * 64.79891 / 1_000_000 }, fromBase: { $0 / (64.79891 / 1_000_000) }),
            Unit(nameAr: "أونصة تروي", nameEn: "Troy Ounce", abbreviation: "oz t", toBase: { $0 * 480 * 64.79891 / 1_000_000 }, fromBase: { $0 / (480 * 64.79891 / 1_000_000) }),
            Unit(nameAr: "تولة", nameEn: "Tola", abbreviation: "tola", toBase: { $0 * 180 * 64.79891 / 1_000_000 }, fromBase: { $0 / (180 * 64.79891 / 1_000_000) }),
            // Metric quintal used in modern Arab trade: exactly 100 kg.
            Unit(nameAr: "قنطار متري", nameEn: "Metric Quintal", abbreviation: "q", toBase: { $0 * 100 }, fromBase: { $0 / 100 }),
            // Gold-market and zakat conventions, named with the gram figure so the
            // definition is visible. Legal mithqal 4.25 g (20 mithqal = 85 g nisab,
            // the figure used by many Gulf zakat tables). Dirham = 7/10 of that mithqal.
            // Iraqi souk mithqal is a separate market unit of exactly 5 g.
            Unit(nameAr: "مثقال شرعي (4.25 غ)", nameEn: "Legal Mithqal (4.25 g)", abbreviation: "mth", toBase: { $0 * 0.00425 }, fromBase: { $0 / 0.00425 }),
            Unit(nameAr: "درهم شرعي (2.975 غ)", nameEn: "Legal Dirham (2.975 g)", abbreviation: "drm", toBase: { $0 * 0.002975 }, fromBase: { $0 / 0.002975 }),
            Unit(nameAr: "مثقال عراقي (5 غ)", nameEn: "Iraqi Mithqal (5 g)", abbreviation: "mth IQ", toBase: { $0 * 0.005 }, fromBase: { $0 / 0.005 })
        ]
    ),
    UnitCategory(
        id: "temperature",
        titleAr: "درجة الحرارة",
        titleEn: "Temperature",
        subtitleAr: "مئوي، فهرنهايت، كلفن...",
        subtitleEn: "Celsius, Fahrenheit, Kelvin...",
        icon: "thermometer.sun.fill",
        gradientColors: [Color.red, Color.orange],
        units: [
            Unit(nameAr: "سلسيوس (مئوي)", nameEn: "Celsius", abbreviation: "°C", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "فهرنهايت", nameEn: "Fahrenheit", abbreviation: "°F", toBase: { ($0 - 32) * 5 / 9 }, fromBase: { $0 * 9 / 5 + 32 }),
            Unit(nameAr: "كلفن", nameEn: "Kelvin", abbreviation: "K", toBase: { $0 - 273.15 }, fromBase: { $0 + 273.15 }),
            // Rankine shares the Fahrenheit degree and the kelvin zero point.
            // 0 °C = 273.15 K = 273.15 × 9/5 °R (NIST).
            Unit(nameAr: "رانكن", nameEn: "Rankine", abbreviation: "°R", toBase: { ($0 - 273.15 * 9 / 5) * 5 / 9 }, fromBase: { $0 * 9 / 5 + 273.15 * 9 / 5 })
        ]
    ),
    UnitCategory(
        id: "volume",
        titleAr: "الحجم والسعة",
        titleEn: "Volume & Capacity",
        subtitleAr: "لترات، أكواب، براميل...",
        subtitleEn: "Liters, Cups, Barrels...",
        icon: "drop.fill",
        gradientColors: [Color.teal, Color.blue],
        units: [
            Unit(nameAr: "لتر", nameEn: "Liter", abbreviation: "L", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "مليلتر", nameEn: "Milliliter", abbreviation: "mL", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            Unit(nameAr: "متر مكعب", nameEn: "Cubic Meter", abbreviation: "m³", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "جالون أمريكي", nameEn: "US Gallon", abbreviation: "gal", toBase: { $0 * 3.78541 }, fromBase: { $0 / 3.78541 }),
            Unit(nameAr: "كوب معياري", nameEn: "Standard Cup", abbreviation: "cup", toBase: { $0 * 0.236588 }, fromBase: { $0 / 0.236588 }),
            Unit(nameAr: "أونصة سائلة", nameEn: "Fluid Ounce", abbreviation: "fl oz", toBase: { $0 * 0.0295735 }, fromBase: { $0 / 0.0295735 }),
            Unit(nameAr: "ملعقة طعام", nameEn: "Tablespoon", abbreviation: "tbsp", toBase: { $0 * 0.0147868 }, fromBase: { $0 / 0.0147868 }),
            // 1 L = 1 dm³ exactly, so 1 cm³ = 1 mL (BIPM).
            Unit(nameAr: "سنتيمتر مكعب", nameEn: "Cubic Centimeter", abbreviation: "cm³", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            // International foot and inch are exact (NIST): 1 ft = 0.3048 m, 1 in = 0.0254 m.
            Unit(nameAr: "قدم مكعب", nameEn: "Cubic Foot", abbreviation: "ft³", toBase: { $0 * 0.3048 * 0.3048 * 0.3048 * 1000 }, fromBase: { $0 / (0.3048 * 0.3048 * 0.3048 * 1000) }),
            Unit(nameAr: "بوصة مكعبة", nameEn: "Cubic Inch", abbreviation: "in³", toBase: { $0 * 0.0254 * 0.0254 * 0.0254 * 1000 }, fromBase: { $0 / (0.0254 * 0.0254 * 0.0254 * 1000) }),
            // US gallon is exactly 231 in³ = 3.785411784 L (NIST). The gallon already
            // in this list keeps its original rounded factor.
            Unit(nameAr: "باينت أمريكي", nameEn: "US Pint", abbreviation: "pt", toBase: { $0 * 3.785411784 / 8 }, fromBase: { $0 / (3.785411784 / 8) }),
            Unit(nameAr: "كوارت أمريكي", nameEn: "US Quart", abbreviation: "qt", toBase: { $0 * 3.785411784 / 4 }, fromBase: { $0 / (3.785411784 / 4) }),
            Unit(nameAr: "ملعقة شاي أمريكية", nameEn: "US Teaspoon", abbreviation: "tsp", toBase: { $0 * 3.785411784 / 768 }, fromBase: { $0 / (3.785411784 / 768) }),
            // Imperial gallon is exactly 4.54609 L (UK Weights and Measures Act).
            Unit(nameAr: "جالون بريطاني", nameEn: "Imperial Gallon", abbreviation: "gal UK", toBase: { $0 * 4.54609 }, fromBase: { $0 / 4.54609 }),
            Unit(nameAr: "باينت بريطاني", nameEn: "Imperial Pint", abbreviation: "pt UK", toBase: { $0 * 4.54609 / 8 }, fromBase: { $0 / (4.54609 / 8) }),
            // Metric spoons and the 250 mL cup used in Arabic recipes.
            // Distinct from the US cup and tablespoon already above.
            Unit(nameAr: "كوب متري", nameEn: "Metric Cup", abbreviation: "cup m", toBase: { $0 * 0.25 }, fromBase: { $0 / 0.25 }),
            Unit(nameAr: "ملعقة طعام مترية", nameEn: "Metric Tablespoon", abbreviation: "tbsp m", toBase: { $0 * 0.015 }, fromBase: { $0 / 0.015 }),
            Unit(nameAr: "ملعقة شاي مترية", nameEn: "Metric Teaspoon", abbreviation: "tsp m", toBase: { $0 * 0.005 }, fromBase: { $0 / 0.005 }),
            // API oil barrel = 42 US gallons exactly. Relevant for the Gulf oil trade.
            Unit(nameAr: "برميل نفط", nameEn: "Oil Barrel", abbreviation: "bbl", toBase: { $0 * 42 * 3.785411784 }, fromBase: { $0 / (42 * 3.785411784) }),
            // Prophetic ṣāʿ at the Hijazi estimate of 2.75 L widely printed in
            // contemporary zakat tables (4 mudd). Hanafi estimates are larger;
            // the name carries 2.75 L so the factor is not ambiguous.
            Unit(nameAr: "صاع شرعي (2.75 ل)", nameEn: "Legal Sa (2.75 L)", abbreviation: "sa", toBase: { $0 * 2.75 }, fromBase: { $0 / 2.75 }),
            Unit(nameAr: "مد شرعي", nameEn: "Legal Mudd", abbreviation: "mudd", toBase: { $0 * 2.75 / 4 }, fromBase: { $0 / (2.75 / 4) })
        ]
    ),
    UnitCategory(
        id: "speed",
        titleAr: "السرعة",
        titleEn: "Speed & Velocity",
        subtitleAr: "كم/ساعة، ميل/ساعة، عقدة...",
        subtitleEn: "km/h, mph, Knots...",
        icon: "gauge.with.needle.fill",
        gradientColors: [Color.purple, Color.pink],
        units: [
            Unit(nameAr: "كم / ساعة", nameEn: "km/h", abbreviation: "km/h", toBase: { $0 / 3.6 }, fromBase: { $0 * 3.6 }),
            Unit(nameAr: "متر / ثانية", nameEn: "m/s", abbreviation: "m/s", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "ميل / ساعة", nameEn: "mph", abbreviation: "mph", toBase: { $0 * 0.44704 }, fromBase: { $0 / 0.44704 }),
            Unit(nameAr: "عقدة بحرية", nameEn: "Knot", abbreviation: "kn", toBase: { $0 * 0.514444 }, fromBase: { $0 / 0.514444 }),
            Unit(nameAr: "ماخ (سرعة الصوت)", nameEn: "Mach", abbreviation: "Mach", toBase: { $0 * 343 }, fromBase: { $0 / 343 }),
            // 1 ft/s = 0.3048 m/s exactly (international foot, NIST).
            Unit(nameAr: "قدم / ثانية", nameEn: "ft/s", abbreviation: "ft/s", toBase: { $0 * 0.3048 }, fromBase: { $0 / 0.3048 }),
            Unit(nameAr: "كم / ثانية", nameEn: "km/s", abbreviation: "km/s", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 })
        ]
    ),
    UnitCategory(
        id: "time",
        titleAr: "الوقت والزمن",
        titleEn: "Time & Duration",
        subtitleAr: "ثوانٍ، ساعات، أيام، سنوات...",
        subtitleEn: "Seconds, Hours, Days, Years...",
        icon: "clock.badge.checkmark.fill",
        gradientColors: [Color.green, Color.mint],
        units: [
            Unit(nameAr: "ثانية", nameEn: "Second", abbreviation: "s", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "دقيقة", nameEn: "Minute", abbreviation: "min", toBase: { $0 * 60 }, fromBase: { $0 / 60 }),
            Unit(nameAr: "ساعة", nameEn: "Hour", abbreviation: "h", toBase: { $0 * 3600 }, fromBase: { $0 / 3600 }),
            Unit(nameAr: "يوم", nameEn: "Day", abbreviation: "d", toBase: { $0 * 86400 }, fromBase: { $0 / 86400 }),
            Unit(nameAr: "أسبوع", nameEn: "Week", abbreviation: "wk", toBase: { $0 * 604800 }, fromBase: { $0 / 604800 }),
            Unit(nameAr: "شهر (30 يوم)", nameEn: "Month (30d)", abbreviation: "mo", toBase: { $0 * 2_592_000 }, fromBase: { $0 / 2_592_000 }),
            Unit(nameAr: "سنة", nameEn: "Year", abbreviation: "yr", toBase: { $0 * 31_536_000 }, fromBase: { $0 / 31_536_000 }),
            Unit(nameAr: "ملي ثانية", nameEn: "Millisecond", abbreviation: "ms", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            Unit(nameAr: "ميكرو ثانية", nameEn: "Microsecond", abbreviation: "µs", toBase: { $0 / 1_000_000 }, fromBase: { $0 * 1_000_000 }),
            Unit(nameAr: "نانو ثانية", nameEn: "Nanosecond", abbreviation: "ns", toBase: { $0 / 1_000_000_000 }, fromBase: { $0 * 1_000_000_000 }),
            // Decade and century follow this app's 365-day year (31,536,000 s), not the Julian year.
            Unit(nameAr: "عقد", nameEn: "Decade", abbreviation: "dec", toBase: { $0 * 10 * 31_536_000 }, fromBase: { $0 / (10 * 31_536_000) }),
            Unit(nameAr: "قرن", nameEn: "Century", abbreviation: "cy", toBase: { $0 * 100 * 31_536_000 }, fromBase: { $0 / (100 * 31_536_000) })
        ]
    ),
    UnitCategory(
        id: "area",
        titleAr: "المساحة",
        titleEn: "Area & Surface",
        subtitleAr: "متر مربع، أكر، دونم...",
        subtitleEn: "Square Meters, Acres, Dunams...",
        icon: "square.stack.3d.up.fill",
        gradientColors: [Color.indigo, Color.purple],
        units: [
            Unit(nameAr: "متر مربع", nameEn: "Square Meter", abbreviation: "m²", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلومتر مربع", nameEn: "Square Kilometer", abbreviation: "km²", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            Unit(nameAr: "هكتار", nameEn: "Hectare", abbreviation: "ha", toBase: { $0 * 10_000 }, fromBase: { $0 / 10_000 }),
            Unit(nameAr: "فدان", nameEn: "Feddan", abbreviation: "fed", toBase: { $0 * 4200.83 }, fromBase: { $0 / 4200.83 }),
            Unit(nameAr: "قدم مربع", nameEn: "Square Foot", abbreviation: "ft²", toBase: { $0 * 0.092903 }, fromBase: { $0 / 0.092903 }),
            Unit(nameAr: "دونوم", nameEn: "Dunam", abbreviation: "dunam", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "سنتيمتر مربع", nameEn: "Square Centimeter", abbreviation: "cm²", toBase: { $0 / 10_000 }, fromBase: { $0 * 10_000 }),
            Unit(nameAr: "مليمتر مربع", nameEn: "Square Millimeter", abbreviation: "mm²", toBase: { $0 / 1_000_000 }, fromBase: { $0 * 1_000_000 }),
            // International yard and inch, squared (NIST): 1 yd = 0.9144 m, 1 in = 0.0254 m.
            Unit(nameAr: "ياردة مربعة", nameEn: "Square Yard", abbreviation: "yd²", toBase: { $0 * 0.9144 * 0.9144 }, fromBase: { $0 / (0.9144 * 0.9144) }),
            Unit(nameAr: "بوصة مربعة", nameEn: "Square Inch", abbreviation: "in²", toBase: { $0 * 0.0254 * 0.0254 }, fromBase: { $0 / (0.0254 * 0.0254) }),
            // 1 acre = 43,560 ft² exactly. 1 ft = 0.3048 m, so 1 acre = 4046.8564224 m².
            Unit(nameAr: "أكر", nameEn: "Acre", abbreviation: "ac", toBase: { $0 * 43_560 * 0.3048 * 0.3048 }, fromBase: { $0 / (43_560 * 0.3048 * 0.3048) }),
            // International mile squared. 1 mi = 1609.344 m exactly (NIST).
            Unit(nameAr: "ميل مربع", nameEn: "Square Mile", abbreviation: "mi²", toBase: { $0 * 1609.344 * 1609.344 }, fromBase: { $0 / (1609.344 * 1609.344) }),
            // Iraqi donum is 2,500 m². The "دونوم" above is the metric dunam of 1,000 m².
            Unit(nameAr: "دونم عراقي", nameEn: "Iraqi Donum", abbreviation: "donum IQ", toBase: { $0 * 2500 }, fromBase: { $0 / 2500 }),
            // Egyptian land qirat: 1/24 of the feddan factor already used above (4200.83 m²).
            Unit(nameAr: "قيراط أرض", nameEn: "Land Qirat", abbreviation: "qirat", toBase: { $0 * 4200.83 / 24 }, fromBase: { $0 / (4200.83 / 24) })
        ]
    ),
    UnitCategory(
        id: "digital",
        titleAr: "البيانات الرقمية",
        titleEn: "Digital Storage",
        subtitleAr: "بايت، ميجابايت، جيجابايت...",
        subtitleEn: "Bytes, Megabytes, Gigabytes...",
        icon: "server.rack",
        gradientColors: [Color.cyan, Color.blue],
        units: [
            Unit(nameAr: "بايت", nameEn: "Byte", abbreviation: "B", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوبايت", nameEn: "Kilobyte", abbreviation: "KB", toBase: { $0 * 1024 }, fromBase: { $0 / 1024 }),
            Unit(nameAr: "ميجابايت", nameEn: "Megabyte", abbreviation: "MB", toBase: { $0 * 1_048_576 }, fromBase: { $0 / 1_048_576 }),
            Unit(nameAr: "جيجابايت", nameEn: "Gigabyte", abbreviation: "GB", toBase: { $0 * 1_073_741_824 }, fromBase: { $0 / 1_073_741_824 }),
            Unit(nameAr: "تيرابايت", nameEn: "Terabyte", abbreviation: "TB", toBase: { $0 * 1_099_511_627_776 }, fromBase: { $0 / 1_099_511_627_776 }),
            // 1 byte = 8 bits. KB…TB above stay binary (1024^n), as this category already did.
            Unit(nameAr: "بت", nameEn: "Bit", abbreviation: "bit", toBase: { $0 / 8 }, fromBase: { $0 * 8 }),
            // 1024^5 bytes.
            Unit(nameAr: "بيتابايت", nameEn: "Petabyte", abbreviation: "PB", toBase: { $0 * 1_125_899_906_842_624 }, fromBase: { $0 / 1_125_899_906_842_624 }),
            // Decimal SI labels (powers of 10), the figures printed on drives and memory cards (BIPM).
            Unit(nameAr: "ميجابايت (عشري)", nameEn: "Megabyte (Decimal)", abbreviation: "MB (SI)", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            Unit(nameAr: "جيجابايت (عشري)", nameEn: "Gigabyte (Decimal)", abbreviation: "GB (SI)", toBase: { $0 * 1_000_000_000 }, fromBase: { $0 / 1_000_000_000 }),
            Unit(nameAr: "تيرابايت (عشري)", nameEn: "Terabyte (Decimal)", abbreviation: "TB (SI)", toBase: { $0 * 1_000_000_000_000 }, fromBase: { $0 / 1_000_000_000_000 })
        ]
    ),
    UnitCategory(
        id: "energy",
        titleAr: "الطاقة والحرارة",
        titleEn: "Energy & Work",
        subtitleAr: "جول، سعرة حرارية، واط ساعي...",
        subtitleEn: "Joules, Calories, kWh...",
        icon: "bolt.fill",
        gradientColors: [Color.yellow, Color.orange],
        units: [
            Unit(nameAr: "جول", nameEn: "Joule", abbreviation: "J", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوجول", nameEn: "Kilojoule", abbreviation: "kJ", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "سعرة حرارية", nameEn: "Calorie", abbreviation: "cal", toBase: { $0 * 4.184 }, fromBase: { $0 / 4.184 }),
            Unit(nameAr: "كيلوسعرة (كالوري)", nameEn: "Kilocalorie", abbreviation: "kcal", toBase: { $0 * 4184 }, fromBase: { $0 / 4184 }),
            Unit(nameAr: "كيلوواط ساعي", nameEn: "Kilowatt-hour", abbreviation: "kWh", toBase: { $0 * 3_600_000 }, fromBase: { $0 / 3_600_000 }),
            // 1 W × 1 h = 3600 J exactly.
            Unit(nameAr: "واط ساعي", nameEn: "Watt-hour", abbreviation: "Wh", toBase: { $0 * 3600 }, fromBase: { $0 / 3600 }),
            Unit(nameAr: "ميجاواط ساعي", nameEn: "Megawatt-hour", abbreviation: "MWh", toBase: { $0 * 3_600_000_000 }, fromBase: { $0 / 3_600_000_000 }),
            // International Table BTU (NIST SP 811).
            Unit(nameAr: "وحدة حرارية بريطانية", nameEn: "BTU (IT)", abbreviation: "BTU", toBase: { $0 * 1_055.05585262 }, fromBase: { $0 / 1_055.05585262 }),
            // 1 ft·lbf = 0.3048 m × 1 lbf, and 1 lbf = 0.45359237 × 9.80665 N (NIST, standard gravity).
            Unit(nameAr: "قدم-رطل", nameEn: "Foot-pound", abbreviation: "ft·lbf", toBase: { $0 * 0.3048 * 0.45359237 * 9.80665 }, fromBase: { $0 / (0.3048 * 0.45359237 * 9.80665) }),
            // Electronvolt is exact in the 2019 SI: 1 eV = 1.602176634×10⁻¹⁹ J.
            Unit(nameAr: "إلكترون فولت", nameEn: "Electronvolt", abbreviation: "eV", toBase: { $0 * 1.602176634e-19 }, fromBase: { $0 / 1.602176634e-19 })
        ]
    ),
    UnitCategory(
        id: "pressure",
        titleAr: "الضغط الجوي",
        titleEn: "Pressure",
        subtitleAr: "بار، psi، ملم زئبق...",
        subtitleEn: "Bar, PSI, mmHg...",
        icon: "barometer",
        gradientColors: [Color.pink, Color.red],
        units: [
            Unit(nameAr: "باسكال", nameEn: "Pascal", abbreviation: "Pa", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوباسكال", nameEn: "Kilopascal", abbreviation: "kPa", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "بار", nameEn: "Bar", abbreviation: "bar", toBase: { $0 * 100_000 }, fromBase: { $0 / 100_000 }),
            Unit(nameAr: "ضغط جوي قياسي", nameEn: "Atmosphere", abbreviation: "atm", toBase: { $0 * 101_325 }, fromBase: { $0 / 101_325 }),
            Unit(nameAr: "رطل لكل بوصة مربعة", nameEn: "PSI", abbreviation: "psi", toBase: { $0 * 6894.76 }, fromBase: { $0 / 6894.76 }),
            // 1 mbar = 1 hPa = 100 Pa exactly (the bar is 10⁵ Pa, BIPM).
            Unit(nameAr: "هكتوباسكال", nameEn: "Hectopascal", abbreviation: "hPa", toBase: { $0 * 100 }, fromBase: { $0 / 100 }),
            Unit(nameAr: "مليبار", nameEn: "Millibar", abbreviation: "mbar", toBase: { $0 * 100 }, fromBase: { $0 / 100 }),
            Unit(nameAr: "ميجاباسكال", nameEn: "Megapascal", abbreviation: "MPa", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            // Conventional mmHg (NIST). Torr is exactly 1/760 of the standard atmosphere (101325 Pa).
            Unit(nameAr: "مليمتر زئبق", nameEn: "Millimeter of Mercury", abbreviation: "mmHg", toBase: { $0 * 133.322387415 }, fromBase: { $0 / 133.322387415 }),
            Unit(nameAr: "تور", nameEn: "Torr", abbreviation: "Torr", toBase: { $0 * 101_325 / 760 }, fromBase: { $0 / (101_325 / 760) }),
            // Conventional inch of mercury, 3.386389 kPa (NIST SP 811).
            Unit(nameAr: "بوصة زئبق", nameEn: "Inch of Mercury", abbreviation: "inHg", toBase: { $0 * 3386.389 }, fromBase: { $0 / 3386.389 }),
            // Technical atmosphere: 1 kgf/cm² = 9.80665 N / cm² = 98066.5 Pa (standard gravity).
            // Still printed on some Gulf tire and compressor gauges.
            Unit(nameAr: "كيلوغرام/سم²", nameEn: "kgf per cm²", abbreviation: "kgf/cm²", toBase: { $0 * 98_066.5 }, fromBase: { $0 / 98_066.5 })
        ]
    ),
    UnitCategory(
        id: "power",
        titleAr: "القدرة الكهربائية",
        titleEn: "Power",
        subtitleAr: "واط، حصان، طن تبريد...",
        subtitleEn: "Watts, Horsepower, AC Tons...",
        icon: "bolt.circle.fill",
        gradientColors: [Color.orange, Color.red],
        units: [
            Unit(nameAr: "واط", nameEn: "Watt", abbreviation: "W", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوواط", nameEn: "Kilowatt", abbreviation: "kW", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "ميجاواط", nameEn: "Megawatt", abbreviation: "MW", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            Unit(nameAr: "حصان ميكانيكي", nameEn: "Horsepower", abbreviation: "hp", toBase: { $0 * 745.7 }, fromBase: { $0 / 745.7 }),
            Unit(nameAr: "حصان متري", nameEn: "Metric Horsepower", abbreviation: "PS", toBase: { $0 * 735.5 }, fromBase: { $0 / 735.5 }),
            Unit(nameAr: "وحدة حرارية/ساعة", nameEn: "BTU per hour", abbreviation: "BTU/h", toBase: { $0 * 0.293071 }, fromBase: { $0 / 0.293071 }),
            // Ton of refrigeration, the air-conditioner capacity unit used in Kuwait.
            // 1 TR = 12,000 IT BTU/h. 1 BTU_IT = 1055.05585262 J (NIST).
            Unit(nameAr: "طن تبريد", nameEn: "Ton of Refrigeration", abbreviation: "TR", toBase: { $0 * 12_000 * 1_055.05585262 / 3_600 }, fromBase: { $0 * 3_600 / (12_000 * 1_055.05585262) }),
            // Thermochemical kilocalorie per hour, consistent with kcal = 4184 J above.
            Unit(nameAr: "كيلوسعرة/ساعة", nameEn: "Kilocalorie per hour", abbreviation: "kcal/h", toBase: { $0 * 4184 / 3600 }, fromBase: { $0 * 3600 / 4184 })
        ]
    ),
    UnitCategory(
        id: "fuel",
        titleAr: "استهلاك الوقود",
        titleEn: "Fuel Economy",
        subtitleAr: "لتر/100كم، كم/لتر، ميل/جالون...",
        subtitleEn: "L/100km, km/L, MPG...",
        icon: "fuelpump.fill",
        gradientColors: [Color.green, Color.teal],
        units: [
            // Base is L/100km. Distance-per-volume units are reciprocals.
            // A zero input stays zero so the converter shows 0 rather than an error.
            Unit(nameAr: "لتر لكل 100 كم", nameEn: "Liters per 100km", abbreviation: "L/100km", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كم لكل لتر", nameEn: "Kilometers per Liter", abbreviation: "km/L", toBase: { $0 == 0 ? 0 : 100 / $0 }, fromBase: { $0 == 0 ? 0 : 100 / $0 }),
            Unit(nameAr: "ميل لكل جالون (أمريكي)", nameEn: "MPG (US)", abbreviation: "mpg US", toBase: { $0 == 0 ? 0 : 235.215 / $0 }, fromBase: { $0 == 0 ? 0 : 235.215 / $0 }),
            Unit(nameAr: "ميل لكل جالون (بريطاني)", nameEn: "MPG (UK)", abbreviation: "mpg UK", toBase: { $0 == 0 ? 0 : 282.481 / $0 }, fromBase: { $0 == 0 ? 0 : 282.481 / $0 }),
            // 1 mile = 1.609344 km exactly, so L/100km = 100 / (mi/L × 1.609344).
            Unit(nameAr: "ميل لكل لتر", nameEn: "Miles per Liter", abbreviation: "mi/L", toBase: { $0 == 0 ? 0 : 100 / ($0 * 1.609344) }, fromBase: { $0 == 0 ? 0 : 100 / ($0 * 1.609344) }),
            // 1 US gallon = 3.785411784 L. 1 imperial gallon = 4.54609 L.
            Unit(nameAr: "كم لكل جالون أمريكي", nameEn: "km per US Gallon", abbreviation: "km/gal", toBase: { $0 == 0 ? 0 : 100 * 3.785411784 / $0 }, fromBase: { $0 == 0 ? 0 : 100 * 3.785411784 / $0 }),
            Unit(nameAr: "كم لكل جالون بريطاني", nameEn: "km per Imperial Gallon", abbreviation: "km/gal UK", toBase: { $0 == 0 ? 0 : 100 * 4.54609 / $0 }, fromBase: { $0 == 0 ? 0 : 100 * 4.54609 / $0 })
        ]
    ),
    UnitCategory(
        id: "angle",
        titleAr: "الزوايا",
        titleEn: "Angle",
        subtitleAr: "درجة، راديان، غراد...",
        subtitleEn: "Degrees, Radians, Gradians...",
        icon: "circle.lefthalf.filled",
        gradientColors: [Color.mint, Color.teal],
        units: [
            Unit(nameAr: "درجة", nameEn: "Degree", abbreviation: "°", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "راديان", nameEn: "Radian", abbreviation: "rad", toBase: { $0 * 180 / .pi }, fromBase: { $0 * .pi / 180 }),
            Unit(nameAr: "غراد (جون)", nameEn: "Gradian", abbreviation: "gon", toBase: { $0 * 0.9 }, fromBase: { $0 / 0.9 }),
            Unit(nameAr: "دورة كاملة", nameEn: "Revolution", abbreviation: "rev", toBase: { $0 * 360 }, fromBase: { $0 / 360 }),
            // Arcminute and arcsecond: 1° = 60′ = 3600″.
            Unit(nameAr: "دقيقة قوسية", nameEn: "Arcminute", abbreviation: "arcmin", toBase: { $0 / 60 }, fromBase: { $0 * 60 }),
            Unit(nameAr: "ثانية قوسية", nameEn: "Arcsecond", abbreviation: "arcsec", toBase: { $0 / 3600 }, fromBase: { $0 * 3600 }),
            // Milliradian: 0.001 rad. π is the same constant the radian unit uses.
            Unit(nameAr: "ملي راديان", nameEn: "Milliradian", abbreviation: "mrad", toBase: { $0 * 0.001 * 180 / .pi }, fromBase: { $0 * .pi / 180 / 0.001 })
        ]
    ),
    UnitCategory(
        id: "frequency",
        titleAr: "التردد",
        titleEn: "Frequency",
        subtitleAr: "هرتز، كيلوهرتز، ميجاهرتز...",
        subtitleEn: "Hertz, Kilohertz, Megahertz...",
        icon: "waveform",
        gradientColors: [Color.purple, Color.indigo],
        units: [
            Unit(nameAr: "هرتز", nameEn: "Hertz", abbreviation: "Hz", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوهرتز", nameEn: "Kilohertz", abbreviation: "kHz", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "ميجاهرتز", nameEn: "Megahertz", abbreviation: "MHz", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            Unit(nameAr: "جيجاهرتز", nameEn: "Gigahertz", abbreviation: "GHz", toBase: { $0 * 1_000_000_000 }, fromBase: { $0 / 1_000_000_000 }),
            Unit(nameAr: "دورة في الدقيقة", nameEn: "RPM", abbreviation: "RPM", toBase: { $0 / 60 }, fromBase: { $0 * 60 }),
            Unit(nameAr: "مليهرتز", nameEn: "Millihertz", abbreviation: "mHz", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            Unit(nameAr: "تيراهرتز", nameEn: "Terahertz", abbreviation: "THz", toBase: { $0 * 1_000_000_000_000 }, fromBase: { $0 / 1_000_000_000_000 }),
            // Same dimension as RPM (cycles per minute); named for pulse and tempo.
            Unit(nameAr: "نبضة في الدقيقة", nameEn: "Beats per Minute", abbreviation: "BPM", toBase: { $0 / 60 }, fromBase: { $0 * 60 })
        ]
    ),
    UnitCategory(
        id: "force",
        titleAr: "القوة",
        titleEn: "Force",
        subtitleAr: "نيوتن، كيلوغرام-قوة، رطل...",
        subtitleEn: "Newtons, Kilogram-force, Pounds...",
        icon: "dumbbell.fill",
        gradientColors: [Color.brown, Color.orange],
        units: [
            // Base: newton. Standard gravity gₙ = 9.80665 m/s² exactly (CGPM / NIST).
            Unit(nameAr: "نيوتن", nameEn: "Newton", abbreviation: "N", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلونيوتن", nameEn: "Kilonewton", abbreviation: "kN", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            // 1 dyne = 10⁻⁵ N exactly.
            Unit(nameAr: "داين", nameEn: "Dyne", abbreviation: "dyn", toBase: { $0 / 100_000 }, fromBase: { $0 * 100_000 }),
            Unit(nameAr: "كيلوغرام-قوة", nameEn: "Kilogram-force", abbreviation: "kgf", toBase: { $0 * 9.80665 }, fromBase: { $0 / 9.80665 }),
            // 1 lbf = 0.45359237 kg × 9.80665 m/s² (NIST).
            Unit(nameAr: "رطل-قوة", nameEn: "Pound-force", abbreviation: "lbf", toBase: { $0 * 0.45359237 * 9.80665 }, fromBase: { $0 / (0.45359237 * 9.80665) })
        ]
    ),
    UnitCategory(
        id: "torque",
        titleAr: "عزم الدوران",
        titleEn: "Torque",
        subtitleAr: "نيوتن متر، رطل-قدم...",
        subtitleEn: "Newton-meters, Pound-feet...",
        icon: "steeringwheel",
        gradientColors: [Color.indigo, Color.blue],
        units: [
            // Base: newton-metre. Pound-foot uses the international foot, 0.3048 m (NIST).
            Unit(nameAr: "نيوتن متر", nameEn: "Newton-meter", abbreviation: "N·m", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوغرام-قوة متر", nameEn: "Kilogram-force meter", abbreviation: "kgf·m", toBase: { $0 * 9.80665 }, fromBase: { $0 / 9.80665 }),
            Unit(nameAr: "رطل-قدم", nameEn: "Pound-foot", abbreviation: "lbf·ft", toBase: { $0 * 0.3048 * 0.45359237 * 9.80665 }, fromBase: { $0 / (0.3048 * 0.45359237 * 9.80665) }),
            Unit(nameAr: "رطل-بوصة", nameEn: "Pound-inch", abbreviation: "lbf·in", toBase: { $0 * 0.0254 * 0.45359237 * 9.80665 }, fromBase: { $0 / (0.0254 * 0.45359237 * 9.80665) })
        ]
    ),
    UnitCategory(
        id: "density",
        titleAr: "الكثافة",
        titleEn: "Density",
        subtitleAr: "كغ/م³، غ/سم³، كثافة نسبية...",
        subtitleEn: "kg/m³, g/cm³, Specific Gravity...",
        icon: "cube.fill",
        gradientColors: [Color.brown, Color.teal],
        units: [
            // Base: kg/m³. 1 g/cm³ = 1 g/mL = 1 kg/L = 1000 kg/m³.
            Unit(nameAr: "كيلوغرام/متر مكعب", nameEn: "Kilogram per m³", abbreviation: "kg/m³", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "غرام/سم³", nameEn: "Gram per cm³", abbreviation: "g/cm³", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "غرام/مليلتر", nameEn: "Gram per mL", abbreviation: "g/mL", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "كيلوغرام/لتر", nameEn: "Kilogram per Liter", abbreviation: "kg/L", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            // 1 lb/ft³. 1 ft³ = 0.3048³ m³. 1 lb = 0.45359237 kg (NIST).
            Unit(nameAr: "رطل/قدم مكعب", nameEn: "Pound per ft³", abbreviation: "lb/ft³", toBase: { $0 * 0.45359237 / (0.3048 * 0.3048 * 0.3048) }, fromBase: { $0 * (0.3048 * 0.3048 * 0.3048) / 0.45359237 }),
            // 1 US gallon = 3.785411784 L = 0.003785411784 m³.
            Unit(nameAr: "رطل/جالون أمريكي", nameEn: "Pound per US Gallon", abbreviation: "lb/gal", toBase: { $0 * 0.45359237 / 0.003785411784 }, fromBase: { $0 * 0.003785411784 / 0.45359237 }),
            // Specific gravity relative to water at 4 °C (1000 kg/m³). Dimensionless, shown as that scale.
            Unit(nameAr: "كثافة نسبية (ماء)", nameEn: "Specific Gravity (Water)", abbreviation: "SG", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 })
        ]
    ),
    UnitCategory(
        id: "data-rate",
        titleAr: "سرعة نقل البيانات",
        titleEn: "Data Transfer",
        subtitleAr: "ميجابت/ث، ميجابايت/ث...",
        subtitleEn: "Mbit/s, MB/s...",
        icon: "arrow.up.arrow.down.circle.fill",
        gradientColors: [Color.blue, Color.purple],
        units: [
            // Base: bit/s. Decimal prefixes are the SI ones ISPs use (BIPM):
            // 1 Mbit/s = 10⁶ bit/s. KiB/s and MiB/s are the IEC binary prefixes
            // common in file-copy readouts. 1 byte = 8 bits.
            Unit(nameAr: "بت/ثانية", nameEn: "Bit per second", abbreviation: "bit/s", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوبت/ثانية", nameEn: "Kilobit per second", abbreviation: "kbit/s", toBase: { $0 * 1_000 }, fromBase: { $0 / 1_000 }),
            Unit(nameAr: "ميجابت/ثانية", nameEn: "Megabit per second", abbreviation: "Mbit/s", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            Unit(nameAr: "جيجابت/ثانية", nameEn: "Gigabit per second", abbreviation: "Gbit/s", toBase: { $0 * 1_000_000_000 }, fromBase: { $0 / 1_000_000_000 }),
            Unit(nameAr: "بايت/ثانية", nameEn: "Byte per second", abbreviation: "B/s", toBase: { $0 * 8 }, fromBase: { $0 / 8 }),
            Unit(nameAr: "كيلوبايت/ثانية", nameEn: "Kilobyte per second", abbreviation: "kB/s", toBase: { $0 * 8_000 }, fromBase: { $0 / 8_000 }),
            Unit(nameAr: "ميجابايت/ثانية", nameEn: "Megabyte per second", abbreviation: "MB/s", toBase: { $0 * 8_000_000 }, fromBase: { $0 / 8_000_000 }),
            Unit(nameAr: "كيبيبايت/ثانية", nameEn: "Kibibyte per second", abbreviation: "KiB/s", toBase: { $0 * 8 * 1024 }, fromBase: { $0 / (8 * 1024) }),
            Unit(nameAr: "ميبيبايت/ثانية", nameEn: "Mebibyte per second", abbreviation: "MiB/s", toBase: { $0 * 8 * 1024 * 1024 }, fromBase: { $0 / (8 * 1024 * 1024) })
        ]
    )
]
