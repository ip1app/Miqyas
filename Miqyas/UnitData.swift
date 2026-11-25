import SwiftUI

// MARK: - Rich Unit Categories Data

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
            Unit(nameAr: "ميل بحري", nameEn: "Nautical Mile", abbreviation: "NM", toBase: { $0 * 1852 }, fromBase: { $0 / 1852 })
        ]
    ),
    UnitCategory(
        id: "weight",
        titleAr: "الوزن والكتلة",
        titleEn: "Weight & Mass",
        subtitleAr: "كيلوغرام، رطل، أونصة...",
        subtitleEn: "Kilograms, Pounds, Ounces...",
        icon: "scalemass.fill",
        gradientColors: [Color.orange, Color.yellow],
        units: [
            Unit(nameAr: "كيلوغرام", nameEn: "Kilogram", abbreviation: "kg", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "غرام", nameEn: "Gram", abbreviation: "g", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            Unit(nameAr: "ملغرام", nameEn: "Milligram", abbreviation: "mg", toBase: { $0 / 1_000_000 }, fromBase: { $0 * 1_000_000 }),
            Unit(nameAr: "طن متري", nameEn: "Metric Ton", abbreviation: "t", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "رطل (باوند)", nameEn: "Pound", abbreviation: "lb", toBase: { $0 * 0.45359237 }, fromBase: { $0 / 0.45359237 }),
            Unit(nameAr: "أونصة", nameEn: "Ounce", abbreviation: "oz", toBase: { $0 * 0.02834952 }, fromBase: { $0 / 0.02834952 }),
            Unit(nameAr: "قيراط", nameEn: "Carat", abbreviation: "ct", toBase: { $0 * 0.0002 }, fromBase: { $0 / 0.0002 })
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
            Unit(nameAr: "كلفن", nameEn: "Kelvin", abbreviation: "K", toBase: { $0 - 273.15 }, fromBase: { $0 + 273.15 })
        ]
    ),
    UnitCategory(
        id: "volume",
        titleAr: "الحجم والسعة",
        titleEn: "Volume & Capacity",
        subtitleAr: "لترات، جالونات، أكواب...",
        subtitleEn: "Liters, Gallons, Cups...",
        icon: "drop.fill",
        gradientColors: [Color.teal, Color.blue],
        units: [
            Unit(nameAr: "لتر", nameEn: "Liter", abbreviation: "L", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "مليلتر", nameEn: "Milliliter", abbreviation: "mL", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
            Unit(nameAr: "متر مكعب", nameEn: "Cubic Meter", abbreviation: "m³", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "جالون أمريكي", nameEn: "US Gallon", abbreviation: "gal", toBase: { $0 * 3.78541 }, fromBase: { $0 / 3.78541 }),
            Unit(nameAr: "كوب معياري", nameEn: "Standard Cup", abbreviation: "cup", toBase: { $0 * 0.236588 }, fromBase: { $0 / 0.236588 }),
            Unit(nameAr: "أونصة سائلة", nameEn: "Fluid Ounce", abbreviation: "fl oz", toBase: { $0 * 0.0295735 }, fromBase: { $0 / 0.0295735 }),
            Unit(nameAr: "ملعقة طعام", nameEn: "Tablespoon", abbreviation: "tbsp", toBase: { $0 * 0.0147868 }, fromBase: { $0 / 0.0147868 })
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
            Unit(nameAr: "ماخ (سرعة الصوت)", nameEn: "Mach", abbreviation: "Mach", toBase: { $0 * 343 }, fromBase: { $0 / 343 })
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
            Unit(nameAr: "سنة", nameEn: "Year", abbreviation: "yr", toBase: { $0 * 31_536_000 }, fromBase: { $0 / 31_536_000 })
        ]
    ),
    UnitCategory(
        id: "area",
        titleAr: "المساحة",
        titleEn: "Area & Surface",
        subtitleAr: "متر مربع، هكتار، فدان...",
        subtitleEn: "Square Meters, Hectares...",
        icon: "square.stack.3d.up.fill",
        gradientColors: [Color.indigo, Color.purple],
        units: [
            Unit(nameAr: "متر مربع", nameEn: "Square Meter", abbreviation: "m²", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلومتر مربع", nameEn: "Square Kilometer", abbreviation: "km²", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            Unit(nameAr: "هكتار", nameEn: "Hectare", abbreviation: "ha", toBase: { $0 * 10_000 }, fromBase: { $0 / 10_000 }),
            Unit(nameAr: "فدان", nameEn: "Feddan", abbreviation: "fed", toBase: { $0 * 4200.83 }, fromBase: { $0 / 4200.83 }),
            Unit(nameAr: "قدم مربع", nameEn: "Square Foot", abbreviation: "ft²", toBase: { $0 * 0.092903 }, fromBase: { $0 / 0.092903 }),
            Unit(nameAr: "دونوم", nameEn: "Dunam", abbreviation: "dunam", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 })
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
            Unit(nameAr: "تيرابايت", nameEn: "Terabyte", abbreviation: "TB", toBase: { $0 * 1_099_511_627_776 }, fromBase: { $0 / 1_099_511_627_776 })
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
            Unit(nameAr: "كيلوواط ساعي", nameEn: "Kilowatt-hour", abbreviation: "kWh", toBase: { $0 * 3_600_000 }, fromBase: { $0 / 3_600_000 })
        ]
    ),
    UnitCategory(
        id: "pressure",
        titleAr: "الضغط الجوي",
        titleEn: "Pressure",
        subtitleAr: "بار، باسكال، ضغط جوي، psi...",
        subtitleEn: "Bar, Pascal, ATM, PSI...",
        icon: "barometer",
        gradientColors: [Color.pink, Color.red],
        units: [
            Unit(nameAr: "باسكال", nameEn: "Pascal", abbreviation: "Pa", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوباسكال", nameEn: "Kilopascal", abbreviation: "kPa", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "بار", nameEn: "Bar", abbreviation: "bar", toBase: { $0 * 100_000 }, fromBase: { $0 / 100_000 }),
            Unit(nameAr: "ضغط جوي قياسي", nameEn: "Atmosphere", abbreviation: "atm", toBase: { $0 * 101_325 }, fromBase: { $0 / 101_325 }),
            Unit(nameAr: "رطل لكل بوصة مربعة", nameEn: "PSI", abbreviation: "psi", toBase: { $0 * 6894.76 }, fromBase: { $0 / 6894.76 })
        ]
    ),
    UnitCategory(
        id: "power",
        titleAr: "القدرة الكهربائية",
        titleEn: "Power",
        subtitleAr: "واط، كيلوواط، حصان...",
        subtitleEn: "Watts, Kilowatts, Horsepower...",
        icon: "bolt.circle.fill",
        gradientColors: [Color.orange, Color.red],
        units: [
            Unit(nameAr: "واط", nameEn: "Watt", abbreviation: "W", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كيلوواط", nameEn: "Kilowatt", abbreviation: "kW", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
            Unit(nameAr: "ميجاواط", nameEn: "Megawatt", abbreviation: "MW", toBase: { $0 * 1_000_000 }, fromBase: { $0 / 1_000_000 }),
            Unit(nameAr: "حصان ميكانيكي", nameEn: "Horsepower", abbreviation: "hp", toBase: { $0 * 745.7 }, fromBase: { $0 / 745.7 }),
            Unit(nameAr: "حصان متري", nameEn: "Metric Horsepower", abbreviation: "PS", toBase: { $0 * 735.5 }, fromBase: { $0 / 735.5 }),
            Unit(nameAr: "وحدة حرارية/ساعة", nameEn: "BTU per hour", abbreviation: "BTU/h", toBase: { $0 * 0.293071 }, fromBase: { $0 / 0.293071 })
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
            Unit(nameAr: "لتر لكل 100 كم", nameEn: "Liters per 100km", abbreviation: "L/100km", toBase: { $0 }, fromBase: { $0 }),
            Unit(nameAr: "كم لكل لتر", nameEn: "Kilometers per Liter", abbreviation: "km/L", toBase: { $0 == 0 ? 0 : 100 / $0 }, fromBase: { $0 == 0 ? 0 : 100 / $0 }),
            Unit(nameAr: "ميل لكل جالون (أمريكي)", nameEn: "MPG (US)", abbreviation: "mpg US", toBase: { $0 == 0 ? 0 : 235.215 / $0 }, fromBase: { $0 == 0 ? 0 : 235.215 / $0 }),
            Unit(nameAr: "ميل لكل جالون (بريطاني)", nameEn: "MPG (UK)", abbreviation: "mpg UK", toBase: { $0 == 0 ? 0 : 282.481 / $0 }, fromBase: { $0 == 0 ? 0 : 282.481 / $0 })
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
            Unit(nameAr: "دورة كاملة", nameEn: "Revolution", abbreviation: "rev", toBase: { $0 * 360 }, fromBase: { $0 / 360 })
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
            Unit(nameAr: "دورة في الدقيقة", nameEn: "RPM", abbreviation: "RPM", toBase: { $0 / 60 }, fromBase: { $0 * 60 })
        ]
    )
]



