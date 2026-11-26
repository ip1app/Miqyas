import SwiftUI

// MARK: - App Color Scheme

enum AppColorScheme: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case arabic = "ar"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        }
    }

    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }

    var arrowIcon: String {
        self == .arabic ? "arrow.left" : "arrow.right"
    }
}

// MARK: - Localization Strings (L10n)

struct L10n {
    let lang: AppLanguage

    // Tabs
    var tabHome: String { lang == .arabic ? "الرئيسية" : "Home" }
    var tabFavorites: String { lang == .arabic ? "المفضلة" : "Favorites" }
    var tabHistory: String { lang == .arabic ? "السجل" : "History" }
    var tabSettings: String { lang == .arabic ? "الإعدادات" : "Settings" }

    // Home Header & Search
    var smartConverter: String { lang == .arabic ? "مقياس" : "Miqyas" }
    var fastAccurate: String { lang == .arabic ? "تحويل سريع ودقيق لوحدات القياس" : "Smart Unit & Metric Converter" }
    var searchPlaceholder: String { lang == .arabic ? "ابحث عن فئة أو وحدة قياس..." : "Search category or unit..." }
    var filterAll: String { lang == .arabic ? "الكل" : "All" }
    var filterPopular: String { lang == .arabic ? "الشائعة" : "Popular" }
    var filterFavorites: String { lang == .arabic ? "المفضلة" : "Favorites" }
    var quickFavorites: String { lang == .arabic ? "المفضلة السريعة" : "Quick Favorites" }
    var unitsSuffix: String { lang == .arabic ? "وحدات" : "units" }
    var noSearchResults: String { lang == .arabic ? "لا توجد فئات مطابقة للبحث" : "No matching categories" }
    var clearSearch: String { lang == .arabic ? "مسح البحث" : "Clear Search" }

    // Home Layout Editing
    var editCards: String { lang == .arabic ? "تعديل" : "Edit" }
    var editModeTitle: String { lang == .arabic ? "وضع التعديل" : "Edit Mode" }
    var reorderHint: String { lang == .arabic ? "اسحب البطاقة لتغيير ترتيبها، واضغط − لإخفائها" : "Drag a card to reorder it, tap − to hide it" }
    var hideCard: String { lang == .arabic ? "إخفاء البطاقة" : "Hide Card" }
    var hiddenCardsTitle: String { lang == .arabic ? "البطاقات المخفية" : "Hidden Cards" }
    var noHiddenCards: String { lang == .arabic ? "كل البطاقات ظاهرة حالياً" : "All cards are currently visible" }
    var showAllCards: String { lang == .arabic ? "إظهار الكل" : "Show All" }
    var resetLayoutBtn: String { lang == .arabic ? "إعادة الترتيب الافتراضي" : "Reset Layout" }
    var layoutSectionTitle: String { lang == .arabic ? "تخصيص الواجهة الرئيسية" : "Home Layout" }
    var layoutSectionSubtitle: String { lang == .arabic ? "من الرئيسية اضغط زر التعديل أو اضغط مطولاً على أي بطاقة لترتيبها أو إخفائها." : "From Home, tap the edit button or long-press any card to reorder or hide it." }
    var cannotHideAll: String { lang == .arabic ? "لا يمكن إخفاء كل البطاقات" : "You can't hide all cards" }
    var cannotHideAllMsg: String { lang == .arabic ? "يجب أن تبقى بطاقة واحدة ظاهرة على الأقل." : "At least one card must stay visible." }
    var moveEarlier: String { lang == .arabic ? "تقديم البطاقة" : "Move Card Earlier" }
    var moveLater: String { lang == .arabic ? "تأخير البطاقة" : "Move Card Later" }

    // Converter View
    var fromLabel: String { lang == .arabic ? "من" : "From" }
    var toLabel: String { lang == .arabic ? "إلى" : "To" }
    var copyBtn: String { lang == .arabic ? "نسخ" : "Copy" }
    var shareBtn: String { lang == .arabic ? "مشاركة" : "Share" }
    var shareSubject: String { lang == .arabic ? "نتيجة تحويل - مقياس" : "Conversion Result - Miqyas" }
    var copiedToast: String { lang == .arabic ? "تم نسخ النتيجة إلى الحافظة" : "Copied result to clipboard" }
    var pastedToast: String { lang == .arabic ? "تم اللصق بنجاح" : "Pasted from clipboard" }
    var selectFromTitle: String { lang == .arabic ? "اختر وحدة التحويل (من)" : "Select Unit (From)" }
    var selectToTitle: String { lang == .arabic ? "اختر وحدة التحويل (إلى)" : "Select Unit (To)" }
    var searchUnitPlaceholder: String { lang == .arabic ? "ابحث عن وحدة قياس..." : "Search unit..." }
    var done: String { lang == .arabic ? "تم" : "Done" }
    var sourceUnitBadge: String { lang == .arabic ? "الوحدة الأصلية" : "Source Unit" }
    var multiUnitHeader: String { lang == .arabic ? "تحويل فوري لكافة وحدات" : "Instant conversion for all" }
    var tapToSelect: String { lang == .arabic ? "اضغط لاختيارها" : "Tap to select" }
    var showKeypad: String { lang == .arabic ? "لوحة الأرقام السريعة الذكية" : "Smart Quick Keypad" }
    var hideKeypad: String { lang == .arabic ? "إخفاء لوحة الأرقام السريعة" : "Hide Quick Keypad" }
    var doubleBtn: String { lang == .arabic ? "×2 (مضاعفة)" : "×2 (Double)" }
    var halfBtn: String { lang == .arabic ? "½ (تنصيف)" : "½ (Half)" }
    var resetBtn: String { lang == .arabic ? "1 (إعادة ضبط)" : "1 (Reset)" }
    var error: String { lang == .arabic ? "خطأ" : "Error" }

    // Favorites
    var favoritesTitle: String { lang == .arabic ? "المفضلة ⭐" : "Favorites ⭐" }
    var emptyFavoritesTitle: String { lang == .arabic ? "قائمة المفضلة فارغة" : "Favorites List is Empty" }
    var emptyFavoritesMsg: String { lang == .arabic ? "اضغط على أيقونة النجمة ⭐ داخل أي فئة لإضافتها هنا والوصول إليها بسرعة فائقة." : "Tap the star icon ⭐ inside any category to add it here for fast access." }

    // History
    var historyTitle: String { lang == .arabic ? "سجل التحويلات 🕒" : "History 🕒" }
    var emptyHistoryTitle: String { lang == .arabic ? "لا يوجد سجل تحويلات بعد" : "No Conversion History Yet" }
    var emptyHistoryMsg: String { lang == .arabic ? "أي تحويل تقوم به سيظهر تلقائياً هنا لسهولة مراجعته وإعادة استخدامه." : "Any conversion you make will automatically appear here for easy reference." }
    var clearHistoryTitle: String { lang == .arabic ? "مسح السجل" : "Clear History" }
    var clearHistoryMsg: String { lang == .arabic ? "هل تريد مسح السجل؟ سيتم إبقاء التحويلات المثبتة." : "Clear history? Pinned conversions will be kept." }
    var clearAll: String { lang == .arabic ? "مسح الكل" : "Clear All" }
    var cancel: String { lang == .arabic ? "إلغاء" : "Cancel" }
    var pinTitle: String { lang == .arabic ? "تثبيت" : "Pin" }
    var unpinTitle: String { lang == .arabic ? "إلغاء التثبيت" : "Unpin" }
    var deleteTitle: String { lang == .arabic ? "حذف" : "Delete" }
    var pinnedSectionTitle: String { lang == .arabic ? "المثبت 📌" : "Pinned 📌" }
    var historySectionTitle: String { lang == .arabic ? "السجل" : "Recent" }

    // Settings
    var settingsTitle: String { lang == .arabic ? "الإعدادات ⚙️" : "Settings ⚙️" }
    var languageSection: String { lang == .arabic ? "اللغة" : "Language" }
    var appLanguageTitle: String { lang == .arabic ? "لغة التطبيق" : "App Language" }
    var appLanguageSubtitle: String { lang == .arabic ? "اختر لغة واجهة التطبيق" : "Choose the app language" }

    var calcSection: String { lang == .arabic ? "الأرقام والحساب" : "Numbers & Calculation" }
    var decimalDigitsTitle: String { lang == .arabic ? "عدد الخانات العشرية" : "Decimal Places" }
    var decimalDigitsSubtitle: String { lang == .arabic ? "عدد الأرقام بعد الفاصلة في النتائج" : "Number of digits after the decimal point" }
    var scientificTitle: String { lang == .arabic ? "الصيغة العلمية للأرقام الكبيرة" : "Scientific Notation" }
    var scientificSubtitle: String { lang == .arabic ? "مثال: 1.25e+06 للأعداد الضخمة أو المتناهية الصغر" : "e.g. 1.25e+06 for very large or tiny numbers" }
    var thousandsTitle: String { lang == .arabic ? "فاصل الآلاف" : "Thousands Separator" }
    var thousandsSubtitle: String { lang == .arabic ? "عرض الأعداد كـ 1,000 بدل 1000" : "Show numbers as 1,000 instead of 1000" }

    var feedbackSection: String { lang == .arabic ? "التفاعل" : "Interaction" }
    var hapticTitle: String { lang == .arabic ? "الاهتزاز اللمسي" : "Haptic Feedback" }
    var hapticSubtitle: String { lang == .arabic ? "اهتزاز خفيف عند التفاعل" : "Light vibration on interaction" }
    var soundTitle: String { lang == .arabic ? "المؤثرات الصوتية" : "Sound Effects" }
    var soundSubtitle: String { lang == .arabic ? "نقرة صوتية عند الضغط" : "Click sound on tap" }
    var autoSaveSection: String { lang == .arabic ? "السجل" : "History" }
    var autoSaveHistoryTitle: String { lang == .arabic ? "حفظ سجل التحويلات تلقائياً" : "Auto-save Conversion History" }
    var autoSaveHistorySubtitle: String { lang == .arabic ? "حفظ التحويلات تلقائياً لمراجعتها لاحقاً" : "Automatically save conversions for later review" }

    var aboutSection: String { lang == .arabic ? "عن التطبيق" : "About App" }
    var appNameTitle: String { lang == .arabic ? "اسم التطبيق" : "App Name" }

    // Appearance
    var appearanceSection: String { lang == .arabic ? "المظهر" : "Appearance" }
    var appearanceTitle: String { lang == .arabic ? "مظهر التطبيق" : "App Appearance" }
    var appearanceSubtitle: String { lang == .arabic ? "فاتح أو داكن أو تلقائي حسب النظام" : "Light, dark, or follow the system" }
    var appearanceSystem: String { lang == .arabic ? "تلقائي" : "Auto" }
    var appearanceLight: String { lang == .arabic ? "فاتح ☀️" : "Light ☀️" }
    var appearanceDark: String { lang == .arabic ? "داكن 🌙" : "Dark 🌙" }

    // App Icon
    var appIconSection: String { lang == .arabic ? "أيقونة التطبيق" : "App Icon" }
    var appIconSubtitle: String { lang == .arabic ? "غيّر شكل الأيقونة على شاشتك الرئيسية" : "Change the icon appearance on your home screen" }
    var appIconDefault: String { lang == .arabic ? "الافتراضية" : "Default" }
    var appIconDark: String { lang == .arabic ? "داكنة 🌙" : "Dark 🌙" }
    var appIconColor: String { lang == .arabic ? "ملوّنة 🎨" : "Colorful 🎨" }
    var appNameVal: String { lang == .arabic ? "مقياس - Miqyas" : "Miqyas - Unit Converter" }
    var versionTitle: String { lang == .arabic ? "الإصدار" : "Version" }
    var privacyPolicyTitle: String { lang == .arabic ? "سياسة الخصوصية والاستخدام" : "Privacy & Terms of Use" }
    var rateAppTitle: String { lang == .arabic ? "قيّم مقياس" : "Rate Miqyas" }
    var rateAppSubtitle: String { lang == .arabic ? "رأيك يساعدنا نطوّر التطبيق" : "Your feedback helps us improve" }
    var resetDefaultsBtn: String { lang == .arabic ? "استعادة الإعدادات الافتراضية" : "Restore Default Settings" }
    var resetAlertTitle: String { lang == .arabic ? "إعادة التعيين" : "Reset Settings" }
    var resetAlertMsg: String { lang == .arabic ? "هل ترغب في إعادة جميع الإعدادات وسجل التحويلات إلى الحالة الافتراضية؟" : "Do you want to reset all settings and history to default?" }
    var resetConfirm: String { lang == .arabic ? "إعادة الضبط" : "Reset" }

    // Real-World Comparisons Feature
    var realWorldTitle: String { lang == .arabic ? "مقارنات بصرية واقعية 🌍" : "Real-World Visual Insights 🌍" }
    var realWorldSubtitle: String { lang == .arabic ? "تخيل القيمة بمقاييس واقعية ملموسة" : "Visualize this value with real-world objects" }
    var realWorldEquivalent: String { lang == .arabic ? "يعادل تقريباً:" : "Approximately equals:" }
}

// MARK: - Shared Formatting & Sharing Helpers

func formatDecimal(_ value: Double, maxFractionDigits: Int, locale: Locale, usesGroupingSeparator: Bool = true) -> String {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = maxFractionDigits
    formatter.minimumFractionDigits = 0
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = usesGroupingSeparator
    formatter.locale = locale
    return formatter.string(from: NSNumber(value: value)) ?? String(value)
}

func shareTextForConversion(fromValue: String, fromUnitName: String, toValue: String, toUnitName: String, categoryTitle: String, lang: AppLanguage) -> String {
    if lang == .arabic {
        return """
📐 نتيجة تحويل من تطبيق مقياس:
🔹 \(fromValue) \(fromUnitName) = \(toValue) \(toUnitName)
🏷️ الفئة: \(categoryTitle)
━━━━━━━━━━━━━
تم التحويل بواسطة تطبيق مقياس ⚡️
"""
    } else {
        return """
📐 Conversion Result from Miqyas:
🔹 \(fromValue) \(fromUnitName) = \(toValue) \(toUnitName)
🏷️ Category: \(categoryTitle)
━━━━━━━━━━━━━
Converted with Miqyas App ⚡️
"""
    }
}

// MARK: - History Record Model

struct ConversionRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let categoryId: String
    let categoryTitleAr: String
    let categoryTitleEn: String
    let categoryIcon: String
    let fromValue: String
    let fromUnitNameAr: String
    let fromUnitNameEn: String
    let toValue: String
    let toUnitNameAr: String
    let toUnitNameEn: String
    let timestamp: Date
    var isPinned: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, categoryId, categoryTitleAr, categoryTitleEn, categoryIcon
        case fromValue, fromUnitNameAr, fromUnitNameEn
        case toValue, toUnitNameAr, toUnitNameEn
        case timestamp, isPinned
    }

    init(id: UUID = UUID(), categoryId: String, categoryTitleAr: String, categoryTitleEn: String, categoryIcon: String, fromValue: String, fromUnitNameAr: String, fromUnitNameEn: String, toValue: String, toUnitNameAr: String, toUnitNameEn: String, timestamp: Date, isPinned: Bool = false) {
        self.id = id
        self.categoryId = categoryId
        self.categoryTitleAr = categoryTitleAr
        self.categoryTitleEn = categoryTitleEn
        self.categoryIcon = categoryIcon
        self.fromValue = fromValue
        self.fromUnitNameAr = fromUnitNameAr
        self.fromUnitNameEn = fromUnitNameEn
        self.toValue = toValue
        self.toUnitNameAr = toUnitNameAr
        self.toUnitNameEn = toUnitNameEn
        self.timestamp = timestamp
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        categoryId = try c.decode(String.self, forKey: .categoryId)
        categoryTitleAr = try c.decode(String.self, forKey: .categoryTitleAr)
        categoryTitleEn = try c.decode(String.self, forKey: .categoryTitleEn)
        categoryIcon = try c.decode(String.self, forKey: .categoryIcon)
        fromValue = try c.decode(String.self, forKey: .fromValue)
        fromUnitNameAr = try c.decode(String.self, forKey: .fromUnitNameAr)
        fromUnitNameEn = try c.decode(String.self, forKey: .fromUnitNameEn)
        toValue = try c.decode(String.self, forKey: .toValue)
        toUnitNameAr = try c.decode(String.self, forKey: .toUnitNameAr)
        toUnitNameEn = try c.decode(String.self, forKey: .toUnitNameEn)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(categoryId, forKey: .categoryId)
        try c.encode(categoryTitleAr, forKey: .categoryTitleAr)
        try c.encode(categoryTitleEn, forKey: .categoryTitleEn)
        try c.encode(categoryIcon, forKey: .categoryIcon)
        try c.encode(fromValue, forKey: .fromValue)
        try c.encode(fromUnitNameAr, forKey: .fromUnitNameAr)
        try c.encode(fromUnitNameEn, forKey: .fromUnitNameEn)
        try c.encode(toValue, forKey: .toValue)
        try c.encode(toUnitNameAr, forKey: .toUnitNameAr)
        try c.encode(toUnitNameEn, forKey: .toUnitNameEn)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encode(isPinned, forKey: .isPinned)
    }

    func categoryTitle(for lang: AppLanguage) -> String {
        lang == .arabic ? categoryTitleAr : categoryTitleEn
    }

    func fromUnitName(for lang: AppLanguage) -> String {
        lang == .arabic ? fromUnitNameAr : fromUnitNameEn
    }

    func toUnitName(for lang: AppLanguage) -> String {
        lang == .arabic ? toUnitNameAr : toUnitNameEn
    }

    func formattedDate(for lang: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang.rawValue)
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    func shareText(for lang: AppLanguage) -> String {
        shareTextForConversion(
            fromValue: fromValue,
            fromUnitName: fromUnitName(for: lang),
            toValue: toValue,
            toUnitName: toUnitName(for: lang),
            categoryTitle: categoryTitle(for: lang),
            lang: lang
        )
    }
}

// MARK: - Unit Data Models

struct UnitCategory: Identifiable, Equatable {
    let id: String
    let titleAr: String
    let titleEn: String
    let subtitleAr: String
    let subtitleEn: String
    let icon: String
    let gradientColors: [Color]
    let units: [Unit]

    func title(for lang: AppLanguage) -> String {
        lang == .arabic ? titleAr : titleEn
    }

    func subtitle(for lang: AppLanguage) -> String {
        lang == .arabic ? subtitleAr : subtitleEn
    }

    static func == (lhs: UnitCategory, rhs: UnitCategory) -> Bool {
        lhs.id == rhs.id
    }
}

extension UnitCategory: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Unit: Identifiable, Equatable {
    let id: String
    let nameAr: String
    let nameEn: String
    let abbreviation: String
    let toBase: (Double) -> Double
    let fromBase: (Double) -> Double

    init(nameAr: String, nameEn: String, abbreviation: String, toBase: @escaping (Double) -> Double, fromBase: @escaping (Double) -> Double) {
        self.id = nameEn + "_" + abbreviation
        self.nameAr = nameAr
        self.nameEn = nameEn
        self.abbreviation = abbreviation
        self.toBase = toBase
        self.fromBase = fromBase
    }

    func name(for lang: AppLanguage) -> String {
        lang == .arabic ? nameAr : nameEn
    }

    static func == (lhs: Unit, rhs: Unit) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Real-World Visual Insights Model

struct RealWorldItem {
    let emoji: String
    let titleAr: String
    let titleEn: String
    let factorInBase: Double
    let unitLabelAr: String
    let unitLabelEn: String
    let isThreshold: Bool

    init(emoji: String, titleAr: String, titleEn: String, factorInBase: Double, unitLabelAr: String, unitLabelEn: String, isThreshold: Bool = false) {
        self.emoji = emoji
        self.titleAr = titleAr
        self.titleEn = titleEn
        self.factorInBase = factorInBase
        self.unitLabelAr = unitLabelAr
        self.unitLabelEn = unitLabelEn
        self.isThreshold = isThreshold
    }

    func title(for lang: AppLanguage) -> String { lang == .arabic ? titleAr : titleEn }
    func unitLabel(for lang: AppLanguage) -> String { lang == .arabic ? unitLabelAr : unitLabelEn }

    func thresholdText(baseValue: Double, lang: AppLanguage) -> String {
        let diff = baseValue - factorInBase
        let formatted = String(format: "%.1f", abs(diff))
        if lang == .arabic {
            return diff >= 0 ? "أدفأ بـ \(formatted)° من \(titleAr)" : "أبرد بـ \(formatted)° من \(titleAr)"
        } else {
            return diff >= 0 ? "\(formatted)° warmer than \(titleEn)" : "\(formatted)° colder than \(titleEn)"
        }
    }
}

// MARK: - Real-World Visual Insights Helper

struct RealWorldHelper {
    static func insights(for categoryId: String, baseValue: Double) -> [RealWorldItem] {
        guard baseValue.isFinite else { return [] }
        if categoryId != "temperature" && baseValue <= 0 { return [] }

        switch categoryId {
        case "length":
            // baseValue is in Meters
            var items: [RealWorldItem] = []
            if baseValue >= 500 {
                items.append(RealWorldItem(emoji: "🏢", titleAr: "برج خليفة (828م)", titleEn: "Burj Khalifa (828m)", factorInBase: 828, unitLabelAr: "برج خليفة", unitLabelEn: "Burj Khalifa"))
                items.append(RealWorldItem(emoji: "🗼", titleAr: "برج إيفل (330م)", titleEn: "Eiffel Tower (330m)", factorInBase: 330, unitLabelAr: "برج إيفل", unitLabelEn: "Eiffel Tower"))
                items.append(RealWorldItem(emoji: "✈️", titleAr: "ارتفاع طيران الركاب (10 كم)", titleEn: "Cruising Altitude (10km)", factorInBase: 10_000, unitLabelAr: "ارتفاع تحليق", unitLabelEn: "Cruising Alt"))
            } else if baseValue >= 5 {
                items.append(RealWorldItem(emoji: "⚽️", titleAr: "ملعب كرة قدم (105م)", titleEn: "Football Pitch (105m)", factorInBase: 105, unitLabelAr: "ملعب كرة قدم", unitLabelEn: "Football Pitch"))
                items.append(RealWorldItem(emoji: "🏊‍♂️", titleAr: "مسبح أولمبي (50م)", titleEn: "Olympic Pool (50m)", factorInBase: 50, unitLabelAr: "مسبح أولمبي", unitLabelEn: "Olympic Pool"))
                items.append(RealWorldItem(emoji: "🚌", titleAr: "حافلة نقل عام (12م)", titleEn: "City Bus (12m)", factorInBase: 12, unitLabelAr: "حافلة", unitLabelEn: "City Bus"))
                items.append(RealWorldItem(emoji: "🚗", titleAr: "سيارة سيدان (4.5م)", titleEn: "Sedan Car (4.5m)", factorInBase: 4.5, unitLabelAr: "طول سيارة", unitLabelEn: "Car length"))
            } else {
                items.append(RealWorldItem(emoji: "📱", titleAr: "طول آيفون (15 سم)", titleEn: "iPhone Length (15cm)", factorInBase: 0.15, unitLabelAr: "جهاز آيفون", unitLabelEn: "iPhone"))
                items.append(RealWorldItem(emoji: "💳", titleAr: "بطاقة بنكية (8.5 سم)", titleEn: "Credit Card (8.5cm)", factorInBase: 0.0856, unitLabelAr: "بطاقة بنكية", unitLabelEn: "Credit Card"))
                items.append(RealWorldItem(emoji: "🚶‍♂️", titleAr: "خطوة مشي لشخص بالغ (0.75م)", titleEn: "Adult Step (0.75m)", factorInBase: 0.75, unitLabelAr: "خطوة مشي", unitLabelEn: "Adult Step"))
            }
            return items

        case "weight":
            // baseValue is in Kilograms
            var items: [RealWorldItem] = []
            if baseValue >= 500 {
                items.append(RealWorldItem(emoji: "🐘", titleAr: "فيل أفريقي بالغ (5000 كغ)", titleEn: "African Elephant (5,000kg)", factorInBase: 5000, unitLabelAr: "فيل أفريقي", unitLabelEn: "Elephant"))
                items.append(RealWorldItem(emoji: "🚙", titleAr: "سيارة دفع رباعي (2000 كغ)", titleEn: "SUV Car (2,000kg)", factorInBase: 2000, unitLabelAr: "سيارة عائلية", unitLabelEn: "Family Car"))
                items.append(RealWorldItem(emoji: "🐎", titleAr: "حصان عربي (450 كغ)", titleEn: "Arabian Horse (450kg)", factorInBase: 450, unitLabelAr: "حصان", unitLabelEn: "Horse"))
            } else if baseValue >= 1 {
                items.append(RealWorldItem(emoji: "🧑", titleAr: "متوسط وزن شخص بالغ (75 كغ)", titleEn: "Average Adult Weight (75kg)", factorInBase: 75, unitLabelAr: "شخص بالغ", unitLabelEn: "Adult"))
                items.append(RealWorldItem(emoji: "🎒", titleAr: "حقيبة سفر مسموحة (23 كغ)", titleEn: "Checked Luggage (23kg)", factorInBase: 23, unitLabelAr: "حقيبة سفر", unitLabelEn: "Suitcase"))
                items.append(RealWorldItem(emoji: "💻", titleAr: "لابتوب ماك بوك (1.5 كغ)", titleEn: "MacBook Laptop (1.5kg)", factorInBase: 1.5, unitLabelAr: "لابتوب", unitLabelEn: "Laptop"))
            } else {
                items.append(RealWorldItem(emoji: "🍎", titleAr: "حبة تفاح متوسطة (180 غرام)", titleEn: "Medium Apple (180g)", factorInBase: 0.18, unitLabelAr: "تفاحة", unitLabelEn: "Apple"))
                items.append(RealWorldItem(emoji: "☕️", titleAr: "كوب قهوة ممتلئ (250 غرام)", titleEn: "Cup of Coffee (250g)", factorInBase: 0.25, unitLabelAr: "كوب قهوة", unitLabelEn: "Coffee Cup"))
                items.append(RealWorldItem(emoji: "🪙", titleAr: "قطعة نقدية معدنية (8 غرام)", titleEn: "Coin (8g)", factorInBase: 0.008, unitLabelAr: "عملة معدنية", unitLabelEn: "Coin"))
            }
            return items

        case "area":
            // baseValue is in Square Meters
            var items: [RealWorldItem] = []
            if baseValue >= 1000 {
                items.append(RealWorldItem(emoji: "⚽️", titleAr: "مساحة ملعب كرة قدم (7,140 م²)", titleEn: "Football Pitch (7,140 m²)", factorInBase: 7140, unitLabelAr: "ملعب كرة قدم", unitLabelEn: "Football Pitch"))
                items.append(RealWorldItem(emoji: "🛫", titleAr: "مدرج طائرات دولي (180,000 م²)", titleEn: "Airport Runway (180,000 m²)", factorInBase: 180_000, unitLabelAr: "مدرج مطار", unitLabelEn: "Airport Runway"))
                items.append(RealWorldItem(emoji: "🏞️", titleAr: "سنترال بارك بنيويورك (3.4 كم²)", titleEn: "Central Park (3.41 km²)", factorInBase: 3_410_000, unitLabelAr: "سنترال بارك", unitLabelEn: "Central Park"))
            } else {
                items.append(RealWorldItem(emoji: "🎾", titleAr: "ملعب تنس أرضي (260 م²)", titleEn: "Tennis Court (260 m²)", factorInBase: 260, unitLabelAr: "ملعب تنس", unitLabelEn: "Tennis Court"))
                items.append(RealWorldItem(emoji: "🏠", titleAr: "شقة سكنية متوسطة (120 م²)", titleEn: "Average Apartment (120 m²)", factorInBase: 120, unitLabelAr: "شقة سكنية", unitLabelEn: "Apartment"))
                items.append(RealWorldItem(emoji: "🚗", titleAr: "موقف سيارة قياسي (12.5 م²)", titleEn: "Parking Space (12.5 m²)", factorInBase: 12.5, unitLabelAr: "موقف سيارة", unitLabelEn: "Parking Spot"))
            }
            return items

        case "volume":
            // baseValue is in Liters
            var items: [RealWorldItem] = []
            if baseValue >= 500 {
                items.append(RealWorldItem(emoji: "🏊‍♂️", titleAr: "مسبح أولمبي (2,500,000 لتر)", titleEn: "Olympic Pool (2.5M Liters)", factorInBase: 2_500_000, unitLabelAr: "مسبح أولمبي", unitLabelEn: "Olympic Pool"))
                items.append(RealWorldItem(emoji: "🚛", titleAr: "شاحنة صهريج وقود (30,000 لتر)", titleEn: "Fuel Tanker (30,000 Liters)", factorInBase: 30_000, unitLabelAr: "صهريج وقود", unitLabelEn: "Fuel Tanker"))
                items.append(RealWorldItem(emoji: "🛁", titleAr: "حوض استحمام منزلي (150 لتر)", titleEn: "Standard Bathtub (150 Liters)", factorInBase: 150, unitLabelAr: "حوض استحمام", unitLabelEn: "Bathtub"))
            } else {
                items.append(RealWorldItem(emoji: "🧴", titleAr: "قارورة ماء شرب (0.5 لتر)", titleEn: "Water Bottle (500mL)", factorInBase: 0.5, unitLabelAr: "قارورة ماء", unitLabelEn: "Water Bottle"))
                items.append(RealWorldItem(emoji: "☕️", titleAr: "فنجان قهوة/شاي (0.2 لتر)", titleEn: "Coffee Mug (200mL)", factorInBase: 0.2, unitLabelAr: "فنجان شاي", unitLabelEn: "Coffee Mug"))
                items.append(RealWorldItem(emoji: "🥄", titleAr: "ملعقة طعام (0.015 لتر)", titleEn: "Tablespoon (15mL)", factorInBase: 0.0147868, unitLabelAr: "ملعقة طعام", unitLabelEn: "Tablespoon"))
            }
            return items

        case "speed":
            // baseValue is in m/s (speed of sound is 343 m/s)
            var items: [RealWorldItem] = []
            items.append(RealWorldItem(emoji: "✈️", titleAr: "طائرة بوينغ تجارية (250 م/ث - 900 كم/س)", titleEn: "Passenger Jet (900 km/h)", factorInBase: 250, unitLabelAr: "طائرة نفاثة", unitLabelEn: "Jetliner"))
            items.append(RealWorldItem(emoji: "🐆", titleAr: "الفهد الصياد بأقصى سرعة (30 م/ث - 110 كم/س)", titleEn: "Cheetah Sprint (110 km/h)", factorInBase: 30.5, unitLabelAr: "سرعة الفهد", unitLabelEn: "Cheetah"))
            items.append(RealWorldItem(emoji: "⚡️", titleAr: "سرعة الصوت في الهواء (343 م/ث)", titleEn: "Speed of Sound (343 m/s)", factorInBase: 343, unitLabelAr: "سرعة الصوت", unitLabelEn: "Mach 1"))
            items.append(RealWorldItem(emoji: "🚶‍♂️", titleAr: "سرعة المشي العادي (1.4 م/ث - 5 كم/س)", titleEn: "Walking Pace (5 km/h)", factorInBase: 1.4, unitLabelAr: "مشي عادي", unitLabelEn: "Walking Pace"))
            return items

        case "digital":
            // baseValue is in Bytes
            var items: [RealWorldItem] = []
            let mb = 1_048_576.0
            let gb = 1_073_741_824.0
            if baseValue >= gb {
                items.append(RealWorldItem(emoji: "🎬", titleAr: "فيلم بجودة 4K فائقة (25 جيجابايت)", titleEn: "4K Movie Stream (25 GB)", factorInBase: 25 * gb, unitLabelAr: "فيلم 4K", unitLabelEn: "4K Movie"))
                items.append(RealWorldItem(emoji: "🎮", titleAr: "لعبة بلايستيشن ضخمة (80 جيجابايت)", titleEn: "Modern AAA Game (80 GB)", factorInBase: 80 * gb, unitLabelAr: "لعبة بلايستيشن", unitLabelEn: "AAA Game"))
                items.append(RealWorldItem(emoji: "📸", titleAr: "ألبوم صور آيفون (1000 صورة عالية الدقة)", titleEn: "1,000 High-Res Photos (3 GB)", factorInBase: 3 * gb, unitLabelAr: "1,000 صورة", unitLabelEn: "1k Photos"))
            } else {
                items.append(RealWorldItem(emoji: "🎵", titleAr: "أغنية صوتية بجودة عالية (7 ميجابايت)", titleEn: "High-Quality Song (7 MB)", factorInBase: 7 * mb, unitLabelAr: "أغنية HQ", unitLabelEn: "Song (HQ)"))
                items.append(RealWorldItem(emoji: "📚", titleAr: "كتاب إلكتروني كامل PDF (3 ميجابايت)", titleEn: "Complete eBook (3 MB)", factorInBase: 3 * mb, unitLabelAr: "كتاب رقمي", unitLabelEn: "eBook"))
                items.append(RealWorldItem(emoji: "💬", titleAr: "رسالة محادثة نصية (1 كيلوبايت)", titleEn: "Text Message (1 KB)", factorInBase: 1024, unitLabelAr: "رسالة نصية", unitLabelEn: "Text Msg"))
            }
            return items

        case "time":
            // baseValue is in Seconds
            var items: [RealWorldItem] = []
            if baseValue >= 86400 {
                items.append(RealWorldItem(emoji: "🗓️", titleAr: "يوم كامل (24 ساعة)", titleEn: "Full Day (24h)", factorInBase: 86400, unitLabelAr: "يوم", unitLabelEn: "Day"))
                items.append(RealWorldItem(emoji: "😴", titleAr: "ليلة نوم موصى بها (8 ساعات)", titleEn: "Recommended Sleep (8h)", factorInBase: 28800, unitLabelAr: "ليلة نوم", unitLabelEn: "Night's Sleep"))
                items.append(RealWorldItem(emoji: "🎬", titleAr: "فيلم سينمائي كامل (ساعتان)", titleEn: "Feature Film (2h)", factorInBase: 7200, unitLabelAr: "فيلم", unitLabelEn: "Movie"))
            } else if baseValue >= 60 {
                items.append(RealWorldItem(emoji: "⏰", titleAr: "ساعة كاملة (60 دقيقة)", titleEn: "One Hour (60min)", factorInBase: 3600, unitLabelAr: "ساعة", unitLabelEn: "Hour"))
                items.append(RealWorldItem(emoji: "📺", titleAr: "حلقة مسلسل (45 دقيقة)", titleEn: "TV Episode (45min)", factorInBase: 2700, unitLabelAr: "حلقة مسلسل", unitLabelEn: "TV Episode"))
                items.append(RealWorldItem(emoji: "☕️", titleAr: "استراحة قهوة (15 دقيقة)", titleEn: "Coffee Break (15min)", factorInBase: 900, unitLabelAr: "استراحة قهوة", unitLabelEn: "Coffee Break"))
            } else {
                items.append(RealWorldItem(emoji: "👏", titleAr: "دقيقة تصفيق (60 ثانية)", titleEn: "One Minute (60s)", factorInBase: 60, unitLabelAr: "دقيقة", unitLabelEn: "Minute"))
                items.append(RealWorldItem(emoji: "🚦", titleAr: "إشارة مرور حمراء (30 ثانية)", titleEn: "Red Traffic Light (30s)", factorInBase: 30, unitLabelAr: "إشارة مرور", unitLabelEn: "Traffic Light"))
                items.append(RealWorldItem(emoji: "💓", titleAr: "نبضة قلب (0.8 ثانية)", titleEn: "Heartbeat (0.8s)", factorInBase: 0.8, unitLabelAr: "نبضة قلب", unitLabelEn: "Heartbeat"))
            }
            return items

        case "energy":
            // baseValue is in Joules
            var items: [RealWorldItem] = []
            let kcal = 4184.0
            if baseValue >= 3_600_000 {
                items.append(RealWorldItem(emoji: "🔋", titleAr: "بطارية سيارة كهربائية (60 كيلوواط ساعي)", titleEn: "EV Battery (60 kWh)", factorInBase: 216_000_000, unitLabelAr: "بطارية سيارة كهربائية", unitLabelEn: "EV Battery"))
                items.append(RealWorldItem(emoji: "🏠", titleAr: "استهلاك منزل ليوم واحد (30 كيلوواط ساعي)", titleEn: "Home Daily Usage (30 kWh)", factorInBase: 108_000_000, unitLabelAr: "استهلاك منزل", unitLabelEn: "Home Usage"))
            } else {
                items.append(RealWorldItem(emoji: "🔋", titleAr: "بطارية هاتف ذكي (5 واط ساعي)", titleEn: "Phone Battery (5 Wh)", factorInBase: 18_000, unitLabelAr: "بطارية هاتف", unitLabelEn: "Phone Battery"))
                items.append(RealWorldItem(emoji: "🍌", titleAr: "موزة متوسطة (100 سعرة حرارية)", titleEn: "Medium Banana (100 kcal)", factorInBase: 100 * kcal, unitLabelAr: "موزة", unitLabelEn: "Banana"))
                items.append(RealWorldItem(emoji: "💡", titleAr: "مصباح LED لمدة ساعة (10 واط ساعي)", titleEn: "LED Bulb Hour (10 Wh)", factorInBase: 36_000, unitLabelAr: "مصباح LED", unitLabelEn: "LED Bulb"))
            }
            return items

        case "pressure":
            // baseValue is in Pascal
            var items: [RealWorldItem] = []
            items.append(RealWorldItem(emoji: "🌍", titleAr: "الضغط الجوي عند سطح البحر (1 ضغط جوي)", titleEn: "Sea-Level Atmosphere (1 atm)", factorInBase: 101_325, unitLabelAr: "ضغط جوي", unitLabelEn: "Atmosphere"))
            items.append(RealWorldItem(emoji: "🚗", titleAr: "ضغط إطار سيارة (2.2 بار)", titleEn: "Car Tire (2.2 bar)", factorInBase: 220_000, unitLabelAr: "إطار سيارة", unitLabelEn: "Car Tire"))
            items.append(RealWorldItem(emoji: "🚲", titleAr: "ضغط إطار دراجة (4 بار)", titleEn: "Bike Tire (4 bar)", factorInBase: 400_000, unitLabelAr: "إطار دراجة", unitLabelEn: "Bike Tire"))
            return items

        case "power":
            // baseValue is in Watts
            var items: [RealWorldItem] = []
            items.append(RealWorldItem(emoji: "💡", titleAr: "مصباح LED موفر (10 واط)", titleEn: "LED Bulb (10 W)", factorInBase: 10, unitLabelAr: "مصباح LED", unitLabelEn: "LED Bulb"))
            items.append(RealWorldItem(emoji: "🔌", titleAr: "غلاية ماء كهربائية (2000 واط)", titleEn: "Electric Kettle (2 kW)", factorInBase: 2000, unitLabelAr: "غلاية ماء", unitLabelEn: "Kettle"))
            items.append(RealWorldItem(emoji: "🚗", titleAr: "محرك سيارة متوسط (120 حصان)", titleEn: "Car Engine (120 hp)", factorInBase: 120 * 745.7, unitLabelAr: "محرك سيارة", unitLabelEn: "Car Engine"))
            return items

        case "temperature":
            // baseValue is in Celsius — reference points comparison
            var items: [RealWorldItem] = []
            items.append(RealWorldItem(emoji: "❄️", titleAr: "تجمّد الماء (0°C)", titleEn: "Water Freezing (0°C)", factorInBase: 0, unitLabelAr: "تجمّد الماء", unitLabelEn: "Freezing", isThreshold: true))
            items.append(RealWorldItem(emoji: "🌡️", titleAr: "حرارة الغرفة (20°C)", titleEn: "Room Temperature (20°C)", factorInBase: 20, unitLabelAr: "حرارة الغرفة", unitLabelEn: "Room Temp", isThreshold: true))
            items.append(RealWorldItem(emoji: "🤒", titleAr: "حرارة جسم الإنسان (37°C)", titleEn: "Human Body (37°C)", factorInBase: 37, unitLabelAr: "حرارة الجسم", unitLabelEn: "Body Temp", isThreshold: true))
            items.append(RealWorldItem(emoji: "♨️", titleAr: "غليان الماء (100°C)", titleEn: "Water Boiling (100°C)", factorInBase: 100, unitLabelAr: "غليان الماء", unitLabelEn: "Boiling", isThreshold: true))
            return items

        default:
            return []
        }
    }
}







