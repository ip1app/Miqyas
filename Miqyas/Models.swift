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
    var favoritesUnitsSection: String { lang == .arabic ? "الوحدات" : "Units" }
    var favoritesToolsSection: String { lang == .arabic ? "الأدوات" : "Tools" }
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

    // Measuring Tools
    var tabTools: String { lang == .arabic ? "أدوات القياس" : "Measuring Tools" }
    var homeHeadline: String { lang == .arabic ? "تحويل الوحدات" : "Unit Converter" }
    var homeSubtitle: String { lang == .arabic ? "طول، وزن، حرارة، مساحة، والمزيد" : "Length, weight, temperature, area, and more" }
    var toolsHeadline: String { lang == .arabic ? "أدوات القياس" : "Measuring Tools" }
    var toolsSubtitle: String { lang == .arabic ? "مسطرة، زاوية، ارتفاع، خطوات، والمزيد" : "Ruler, angle, altitude, steps, and more" }
    var toolsSearchPlaceholder: String { lang == .arabic ? "ابحث عن أداة..." : "Search tools..." }
    var toolsNoSearchResults: String { lang == .arabic ? "لا توجد أدوات مطابقة للبحث" : "No matching tools" }
    var toolsEmptyFavoritesTitle: String { lang == .arabic ? "لا توجد أدوات مفضلة" : "No Favorite Tools" }
    var toolsEmptyFavoritesMsg: String { lang == .arabic ? "افتح أي أداة واضغط النجمة ⭐ لإضافتها هنا." : "Open a tool and tap the star to add it here." }
    var favoriteTool: String { lang == .arabic ? "إضافة إلى المفضلة" : "Add to Favorites" }
    var unfavoriteTool: String { lang == .arabic ? "إزالة من المفضلة" : "Remove from Favorites" }

    var toolLevelTitle: String { lang == .arabic ? "ميزان استواء" : "Level" }
    var toolLevelSubtitle: String { lang == .arabic ? "فقاعة وزاوية" : "Bubble and angle" }
    var toolLevelBadge: String { lang == .arabic ? "فقاعة" : "Bubble" }
    var toolCompassTitle: String { lang == .arabic ? "البوصلة والقبلة" : "Compass & Qibla" }
    var toolCompassSubtitle: String { lang == .arabic ? "اتجاه القبلة" : "Qibla direction" }
    var toolCompassBadge: String { lang == .arabic ? "اتجاه" : "Heading" }
    var toolSoundTitle: String { lang == .arabic ? "مقياس الصوت" : "Sound Meter" }
    var toolSoundSubtitle: String { lang == .arabic ? "مستوى تقريبي" : "Approximate level" }
    var toolSoundBadge: String { lang == .arabic ? "تقريبي" : "Approx" }

    var openSettings: String { lang == .arabic ? "فتح الإعدادات" : "Open Settings" }
    var tryAgain: String { lang == .arabic ? "إعادة المحاولة" : "Try Again" }

    var levelSurface: String { lang == .arabic ? "سطح" : "Surface" }
    var levelEdge: String { lang == .arabic ? "حافة" : "Edge" }
    var levelCalibrate: String { lang == .arabic ? "تصفير" : "Zero" }
    var levelResetCalibration: String { lang == .arabic ? "إلغاء التصفير" : "Clear Zero" }
    var levelCalibratedBadge: String { lang == .arabic ? "تم التصفير" : "Zeroed" }
    var levelIsLevel: String { lang == .arabic ? "مستوٍ" : "Level" }
    var levelFromHorizontal: String { lang == .arabic ? "عن الأفقي" : "From horizontal" }
    var levelMotionUnavailable: String { lang == .arabic ? "مستشعر الحركة غير متوفر على هذا الجهاز، لذلك لا يمكن استخدام ميزان الاستواء." : "Motion sensors are not available on this device, so the level cannot be used." }
    var levelHintSurface: String { lang == .arabic ? "ضع الهاتف مسطحاً على السطح. عندما تستقر الفقاعة في الوسط يكون السطح مستوياً." : "Lay the phone flat on the surface. The surface is level when the bubble rests in the center." }
    var levelHintEdge: String { lang == .arabic ? "ضع الهاتف على حافته الطويلة. الزاوية صفر تعني أن الحافة أفقية." : "Rest the phone on its long edge. Zero degrees means that edge is horizontal." }

    var compassTrueNorth: String { lang == .arabic ? "الشمال الحقيقي" : "True north" }
    var compassMagneticNorth: String { lang == .arabic ? "الشمال المغناطيسي" : "Magnetic north" }
    var qiblaBearingLabel: String { lang == .arabic ? "اتجاه القبلة" : "Qibla bearing" }
    var distanceToMakkah: String { lang == .arabic ? "المسافة إلى مكة" : "Distance to Makkah" }
    var kilometersUnit: String { lang == .arabic ? "كم" : "km" }
    var compassCalibrateHint: String { lang == .arabic ? "حرّك الهاتف على شكل رقم 8 لمعايرة البوصلة." : "Move the phone in a figure-8 to calibrate the compass." }
    var compassHardwareUnavailable: String { lang == .arabic ? "مستشعر البوصلة غير متوفر على هذا الجهاز. اتجاه القبلة والمسافة يعتمدان على موقعك فقط." : "The compass sensor is not available on this device. Qibla direction and distance still use your location." }
    var locationPromptMessage: String { lang == .arabic ? "سيطلب مقياس إذن الموقع أثناء استخدام التطبيق لإظهار اتجاه القبلة والمسافة إلى مكة." : "Miqyas will ask for location access while the app is open, so it can show the Qibla direction and the distance to Makkah." }
    var locationDeniedMessage: String { lang == .arabic ? "يلزم السماح بالموقع أثناء استخدام التطبيق لإظهار الاتجاه والقبلة. يمكنك تفعيل ذلك من الإعدادات." : "Allow location access while using the app to show your heading and the Qibla. You can turn it on in Settings." }
    var locatingMessage: String { lang == .arabic ? "جارٍ تحديد موقعك لإظهار القبلة والمسافة." : "Finding your location to show the Qibla and distance." }
    var atKaabaMessage: String { lang == .arabic ? "أنت عند الكعبة" : "You are at the Kaaba" }
    var facingQibla: String { lang == .arabic ? "أنت باتجاه القبلة" : "You are facing the Qibla" }

    func turnRight(_ degrees: String) -> String {
        lang == .arabic ? "أدر يميناً \(degrees)°" : "Turn right \(degrees)°"
    }

    func turnLeft(_ degrees: String) -> String {
        lang == .arabic ? "أدر يساراً \(degrees)°" : "Turn left \(degrees)°"
    }

    var cardinalNorth: String { lang == .arabic ? "شمال" : "North" }
    var cardinalNorthEast: String { lang == .arabic ? "شمال شرقي" : "Northeast" }
    var cardinalEast: String { lang == .arabic ? "شرق" : "East" }
    var cardinalSouthEast: String { lang == .arabic ? "جنوب شرقي" : "Southeast" }
    var cardinalSouth: String { lang == .arabic ? "جنوب" : "South" }
    var cardinalSouthWest: String { lang == .arabic ? "جنوب غربي" : "Southwest" }
    var cardinalWest: String { lang == .arabic ? "غرب" : "West" }
    var cardinalNorthWest: String { lang == .arabic ? "شمال غربي" : "Northwest" }
    var cardinalNorthShort: String { lang == .arabic ? "ش" : "N" }
    var cardinalEastShort: String { lang == .arabic ? "ق" : "E" }
    var cardinalSouthShort: String { lang == .arabic ? "ج" : "S" }
    var cardinalWestShort: String { lang == .arabic ? "غ" : "W" }

    func cardinalName(_ direction: CardinalDirection) -> String {
        switch direction {
        case .north: return cardinalNorth
        case .northEast: return cardinalNorthEast
        case .east: return cardinalEast
        case .southEast: return cardinalSouthEast
        case .south: return cardinalSouth
        case .southWest: return cardinalSouthWest
        case .west: return cardinalWest
        case .northWest: return cardinalNorthWest
        }
    }

    var soundApproximateLabel: String { lang == .arabic ? "تقريبي وليس قياساً معايرًا" : "Approximate, not a calibrated measurement" }
    var soundDecibelUnit: String { lang == .arabic ? "ديسيبل" : "dB" }
    var soundMin: String { lang == .arabic ? "الأدنى" : "Min" }
    var soundAvg: String { lang == .arabic ? "المتوسط" : "Avg" }
    var soundMax: String { lang == .arabic ? "الأعلى" : "Max" }
    var soundReset: String { lang == .arabic ? "إعادة ضبط" : "Reset" }
    var soundPromptMessage: String { lang == .arabic ? "سيطلب مقياس استخدام الميكروفون لإظهار مستوى صوت تقريبي. القياس ليس معايرًا." : "Miqyas will ask to use the microphone to show an approximate sound level. The reading is not calibrated." }
    var soundMicDenied: String { lang == .arabic ? "يلزم السماح بالميكروفون لقياس مستوى الصوت. يمكنك تفعيل ذلك من الإعدادات." : "Allow microphone access to measure the sound level. You can turn it on in Settings." }
    var soundMicUnavailable: String { lang == .arabic ? "الميكروفون غير متوفر على هذا الجهاز، لذلك لا يمكن قياس الصوت." : "The microphone is not available on this device, so sound cannot be measured." }
    var soundFailed: String { lang == .arabic ? "تعذر بدء قياس الصوت. حاول مرة أخرى." : "The sound meter could not start. Try again." }
    var soundMeasuring: String { lang == .arabic ? "جارٍ القياس" : "Measuring" }

    var approximateReading: String { lang == .arabic ? "تقريبي" : "Approximate" }
    var motionDeniedMessage: String { lang == .arabic ? "يلزم السماح بالحركة واللياقة لاستخدام هذه الأداة. يمكنك تفعيل ذلك من الإعدادات." : "Allow Motion & Fitness to use this tool. You can turn it on in Settings." }
    var motionPromptMessage: String { lang == .arabic ? "سيطلب مقياس استخدام مستشعرات الحركة لهذا القياس." : "Miqyas will ask to use motion sensors for this measurement." }
    var motionUnavailableMessage: String { lang == .arabic ? "مستشعر الحركة غير متوفر على هذا الجهاز." : "Motion sensors are not available on this device." }
    var cameraDeniedMessage: String { lang == .arabic ? "يلزم السماح بالكاميرا لاستخدام هذه الأداة. يمكنك تفعيل ذلك من الإعدادات." : "Allow camera access to use this tool. You can turn it on in Settings." }
    var cameraPromptMessage: String { lang == .arabic ? "سيطلب مقياس استخدام الكاميرا لهذا القياس. لا يتم حفظ الصور." : "Miqyas will ask to use the camera for this measurement. No photos are saved." }
    var cameraUnavailableMessage: String { lang == .arabic ? "الكاميرا غير متوفرة على هذا الجهاز." : "The camera is not available on this device." }

    var unitCentimeter: String { lang == .arabic ? "سم" : "cm" }
    var unitMeter: String { lang == .arabic ? "م" : "m" }
    var unitInch: String { lang == .arabic ? "بوصة" : "in" }
    var unitFoot: String { lang == .arabic ? "قدم" : "ft" }
    var unitSquareCentimeter: String { lang == .arabic ? "سم²" : "cm²" }
    var unitSquareMeter: String { lang == .arabic ? "م²" : "m²" }
    var unitSquareInch: String { lang == .arabic ? "بوصة²" : "in²" }
    var unitSquareFoot: String { lang == .arabic ? "قدم²" : "ft²" }

    var toolRulerTitle: String { lang == .arabic ? "مسطرة الشاشة" : "Screen Ruler" }
    var toolRulerSubtitle: String { lang == .arabic ? "سنتيمتر وبوصة" : "Centimeters and inches" }
    var toolRulerBadge: String { lang == .arabic ? "شاشة" : "Screen" }
    var rulerCentimeters: String { lang == .arabic ? "سم" : "cm" }
    var rulerInches: String { lang == .arabic ? "بوصة" : "in" }
    var rulerHorizontal: String { lang == .arabic ? "أفقي" : "Horizontal" }
    var rulerVertical: String { lang == .arabic ? "رأسي" : "Vertical" }
    var rulerMarker: String { lang == .arabic ? "المؤشر" : "Marker" }
    var rulerScreenSize: String { lang == .arabic ? "مقاس الشاشة" : "This screen" }
    var rulerHint: String { lang == .arabic ? "اسحب المؤشر. تعتمد العلامات على كثافة شاشة هذا الجهاز، فالسنتيمتر على المسطرة سنتيمتر حقيقي." : "Drag the marker. The marks use this device's screen density, so a centimeter on the ruler is a real centimeter." }

    var toolProtractorTitle: String { lang == .arabic ? "منقلة" : "Protractor" }
    var toolProtractorSubtitle: String { lang == .arabic ? "الميل والزاوية" : "Tilt and angle" }
    var toolProtractorBadge: String { lang == .arabic ? "زاوية" : "Angle" }
    var protractorTilt: String { lang == .arabic ? "الميل" : "Tilt" }
    var protractorFromFlat: String { lang == .arabic ? "عن الوضع الأفقي" : "From flat" }
    var protractorBetween: String { lang == .arabic ? "الزاوية بين الوضعين" : "Angle between" }
    var protractorNoStart: String { lang == .arabic ? "لم تُثبَّت البداية" : "No starting pose" }
    var protractorCapture: String { lang == .arabic ? "تثبيت البداية" : "Set Start" }
    var protractorClear: String { lang == .arabic ? "مسح البداية" : "Clear Start" }
    var protractorHint: String { lang == .arabic ? "الميل هو الزاوية عن وضع الشاشة الأفقية. الزاوية الثانية هي الفرق بين الوضع المحفوظ والوضع الحالي." : "Tilt is the angle from a flat, screen-up pose. The second angle is the turn between the saved pose and the current one." }

    var toolBarometerTitle: String { lang == .arabic ? "مقياس الضغط" : "Barometer" }
    var toolBarometerSubtitle: String { lang == .arabic ? "الضغط والارتفاع" : "Pressure and altitude" }
    var toolBarometerBadge: String { lang == .arabic ? "تقريبي" : "Approx" }
    var barometerPressure: String { lang == .arabic ? "الضغط" : "Pressure" }
    var barometerHpa: String { lang == .arabic ? "هكتوباسكال" : "hPa" }
    var barometerAltitude: String { lang == .arabic ? "الارتفاع" : "Altitude" }
    var barometerChange: String { lang == .arabic ? "التغيّر" : "Change" }
    var barometerEstimate: String { lang == .arabic ? "ارتفاع تقديري" : "Estimated altitude" }
    var barometerAbsoluteCaption: String { lang == .arabic ? "ارتفاع تقريبي عن سطح البحر" : "Approximate height above sea level" }
    var barometerRelativeCaption: String { lang == .arabic ? "تغيّر تقريبي منذ فتح الأداة" : "Approximate change since this tool opened" }
    var barometerEstimateCaption: String { lang == .arabic ? "تقريبي بافتراض الضغط القياسي عند سطح البحر" : "Approximate, assuming standard sea-level pressure" }
    var barometerUnavailable: String { lang == .arabic ? "مقياس الضغط غير متوفر على هذا الجهاز." : "The barometer is not available on this device." }
    var barometerHint: String { lang == .arabic ? "الارتفاع تقريبي. الطقس يغيّر الضغط، لذلك الرقم ليس ارتفاعًا مساحيًا." : "Altitude is approximate. Weather changes the pressure, so this is not a surveyed height." }

    var toolPedometerTitle: String { lang == .arabic ? "عداد الخطوات" : "Pedometer" }
    var toolPedometerSubtitle: String { lang == .arabic ? "الخطوات والمسافة" : "Steps and distance" }
    var toolPedometerBadge: String { lang == .arabic ? "اليوم" : "Today" }
    var pedometerSteps: String { lang == .arabic ? "الخطوات" : "Steps" }
    var pedometerDistance: String { lang == .arabic ? "المسافة" : "Distance" }
    var pedometerToday: String { lang == .arabic ? "منذ بداية اليوم" : "Since the start of today" }
    var pedometerUnavailable: String { lang == .arabic ? "عدّ الخطوات غير متوفر على هذا الجهاز." : "Step counting is not available on this device." }
    var pedometerNoDistance: String { lang == .arabic ? "المسافة غير متوفرة من عداد هذا الجهاز." : "Distance is not available from this device's pedometer." }
    var pedometerHint: String { lang == .arabic ? "تُحسب الخطوات والمسافة من بداية اليوم على هذا الجهاز." : "Steps and distance are counted from the start of today on this device." }

    var toolSpeedTitle: String { lang == .arabic ? "عداد السرعة" : "Speedometer" }
    var toolSpeedSubtitle: String { lang == .arabic ? "سرعة الموقع" : "GPS speed" }
    var toolSpeedBadge: String { lang == .arabic ? "موقع" : "GPS" }
    var speedCurrent: String { lang == .arabic ? "السرعة" : "Speed" }
    var speedMax: String { lang == .arabic ? "القصوى" : "Max" }
    var speedResetMax: String { lang == .arabic ? "تصفير القصوى" : "Reset Max" }
    var speedWaiting: String { lang == .arabic ? "بانتظار إشارة الموقع. تظهر السرعة عندما تصبح الدقة كافية." : "Waiting for a GPS fix. Speed appears once the location is accurate enough." }
    var speedUnavailable: String { lang == .arabic ? "عتاد الموقع غير متوفر على هذا الجهاز." : "Location hardware is not available on this device." }
    var speedKmh: String { lang == .arabic ? "كم/س" : "km/h" }
    var speedMph: String { lang == .arabic ? "ميل/س" : "mph" }
    var speedMs: String { lang == .arabic ? "م/ث" : "m/s" }
    var speedDeniedMessage: String { lang == .arabic ? "يلزم السماح بالموقع أثناء استخدام التطبيق لقياس السرعة. يمكنك تفعيل ذلك من الإعدادات." : "Allow location access while using the app to measure speed. You can turn it on in Settings." }
    var speedPromptMessage: String { lang == .arabic ? "سيطلب مقياس إذن الموقع أثناء استخدام التطبيق لإظهار سرعتك الحالية." : "Miqyas will ask for location access while the app is open to show your current speed." }

    var toolLightTitle: String { lang == .arabic ? "مقياس الضوء" : "Light Meter" }
    var toolLightSubtitle: String { lang == .arabic ? "لوكس تقريبي" : "Approximate lux" }
    var toolLightBadge: String { lang == .arabic ? "تقريبي" : "Approx" }
    var lightLux: String { lang == .arabic ? "لوكس" : "lux" }
    var lightISO: String { lang == .arabic ? "حساسية" : "ISO" }
    var lightShutter: String { lang == .arabic ? "الغالق" : "Shutter" }
    var lightAperture: String { lang == .arabic ? "الفتحة" : "Aperture" }
    var lightHint: String { lang == .arabic ? "إضاءة تقريبية من تعريض الكاميرا. هذا ليس مقياس ضوء معايرًا، ولا يتم حفظ أي صورة." : "Approximate illuminance from the camera's exposure. This is not a calibrated light meter, and no photo is saved." }
    var lightFailed: String { lang == .arabic ? "تعذر بدء الكاميرا. حاول مرة أخرى." : "The camera could not start. Try again." }

    var toolMagnetTitle: String { lang == .arabic ? "كاشف المعادن" : "Metal Detector" }
    var toolMagnetSubtitle: String { lang == .arabic ? "المجال المغناطيسي" : "Magnetic field" }
    var toolMagnetBadge: String { lang == .arabic ? "تقريبي" : "Approx" }
    var magnetMicrotesla: String { lang == .arabic ? "مكروتسلا" : "µT" }
    var magnetHaptics: String { lang == .arabic ? "اهتزاز عند القفزات" : "Haptic on spikes" }
    var magnetCalibrate: String { lang == .arabic ? "حرّك الهاتف على شكل رقم 8 لتحسين القراءة المغناطيسية." : "Move the phone in a figure-8 to improve the magnetic reading." }
    var magnetHint: String { lang == .arabic ? "قوة تقريبية للمجال المغناطيسي. المعدن القريب يجعل القيمة تقفز. مجال الأرض عادة بين ٢٥ و٦٥ مكروتسلا." : "Approximate magnetic-field strength. Metal nearby makes the value jump. Earth's field is usually 25–65 µT." }
    var magnetUnavailable: String { lang == .arabic ? "مستشعر المغناطيس غير متوفر على هذا الجهاز." : "The magnetometer is not available on this device." }

    var toolSeismoTitle: String { lang == .arabic ? "مقياس الاهتزاز" : "Seismometer" }
    var toolSeismoSubtitle: String { lang == .arabic ? "رسم الاهتزاز" : "Vibration graph" }
    var toolSeismoBadge: String { lang == .arabic ? "مباشر" : "Live" }
    var seismoNow: String { lang == .arabic ? "الآن" : "Now" }
    var seismoPeak: String { lang == .arabic ? "الذروة" : "Peak" }
    var seismoReset: String { lang == .arabic ? "تصفير الذروة" : "Reset Peak" }
    var seismoHint: String { lang == .arabic ? "يعرض الرسم الحركة بعد حذف الجاذبية. الهاتف الساكن يبقى قرب الصفر." : "The graph shows movement, with gravity removed. A still phone stays near zero." }
    var seismoUnavailable: String { lang == .arabic ? "مقياس التسارع غير متوفر على هذا الجهاز." : "The accelerometer is not available on this device." }
    var seismoUnit: String { lang == .arabic ? "ج" : "g" }

    var toolARTitle: String { lang == .arabic ? "مقياس بالكاميرا" : "Camera Measure" }
    var toolARSubtitle: String { lang == .arabic ? "المسافة والمساحة" : "Distance and area" }
    var toolARBadge: String { lang == .arabic ? "كاميرا" : "Camera" }
    var arDistanceMode: String { lang == .arabic ? "مسافة" : "Distance" }
    var arAreaMode: String { lang == .arabic ? "مساحة" : "Area" }
    var arClear: String { lang == .arabic ? "مسح" : "Clear" }
    var arTapFirst: String { lang == .arabic ? "حرّك الهاتف حتى يظهر سطح، ثم المس النقطة الأولى." : "Move the phone until a surface appears, then tap the first point." }
    var arTapSecond: String { lang == .arabic ? "المس النقطة الثانية لقياس المسافة." : "Tap the second point to measure the distance." }
    var arTapWidth: String { lang == .arabic ? "المس نهاية الضلع الأول للمستطيل." : "Tap the end of the rectangle's first side." }
    var arTapHeight: String { lang == .arabic ? "المس نقطة لتحديد الضلع الآخر للمستطيل." : "Tap a point to set the other side of the rectangle." }
    var arNeedSurface: String { lang == .arabic ? "لم يُعثر على سطح. حرّك الهاتف ببطء ثم أعد المحاولة." : "No surface found. Move the phone slowly, then try again." }
    var arDone: String { lang == .arabic ? "المس مسح للبدء من جديد." : "Tap Clear to measure again." }
    var arUnsupported: String { lang == .arabic ? "القياس بالكاميرا غير مدعوم على هذا الجهاز." : "Camera measurement is not supported on this device." }
    var arLineOptions: String { lang == .arabic ? "خيارات الخط" : "Line Options" }
    var arLineColor: String { lang == .arabic ? "اللون" : "Color" }
    var arLineThickness: String { lang == .arabic ? "السُمك" : "Thickness" }
    var arColorYellow: String { lang == .arabic ? "أصفر" : "Yellow" }
    var arColorWhite: String { lang == .arabic ? "أبيض" : "White" }
    var arColorRed: String { lang == .arabic ? "أحمر" : "Red" }
    var arColorGreen: String { lang == .arabic ? "أخضر" : "Green" }
    var arColorBlue: String { lang == .arabic ? "أزرق" : "Blue" }
    var arThicknessThin: String { lang == .arabic ? "رفيع" : "Thin" }
    var arThicknessMedium: String { lang == .arabic ? "متوسط" : "Medium" }
    var arThicknessThick: String { lang == .arabic ? "سميك" : "Thick" }
    var arWidth: String { lang == .arabic ? "العرض" : "Width" }
    var arHeight: String { lang == .arabic ? "الارتفاع" : "Height" }
    var arArea: String { lang == .arabic ? "المساحة" : "Area" }
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

        case "force":
            // baseValue is in Newtons
            return [
                RealWorldItem(emoji: "🍎", titleAr: "وزن تفاحة (1 نيوتن تقريباً)", titleEn: "An Apple's Weight (~1 N)", factorInBase: 1, unitLabelAr: "تفاحة", unitLabelEn: "Apple"),
                RealWorldItem(emoji: "🧍", titleAr: "وزن شخص 70 كغ على الأرض (686 نيوتن)", titleEn: "70 kg Person (686 N)", factorInBase: 70 * 9.80665, unitLabelAr: "شخص بالغ", unitLabelEn: "Adult"),
                RealWorldItem(emoji: "🚗", titleAr: "وزن سيارة صغيرة (12 كيلونيوتن)", titleEn: "Small Car Weight (12 kN)", factorInBase: 12_000, unitLabelAr: "سيارة", unitLabelEn: "Car")
            ]

        case "torque":
            // baseValue is in Newton-meters
            return [
                RealWorldItem(emoji: "🧴", titleAr: "فتح غطاء زجاجة (2 نيوتن متر)", titleEn: "Bottle Cap (2 N·m)", factorInBase: 2, unitLabelAr: "غطاء زجاجة", unitLabelEn: "Bottle Cap"),
                RealWorldItem(emoji: "🔩", titleAr: "شد صواميل إطار سيارة (110 نيوتن متر)", titleEn: "Car Lug Nuts (110 N·m)", factorInBase: 110, unitLabelAr: "صامولة إطار", unitLabelEn: "Lug Nut"),
                RealWorldItem(emoji: "🚗", titleAr: "عزم محرك سيارة عائلية (250 نيوتن متر)", titleEn: "Family-Car Engine (250 N·m)", factorInBase: 250, unitLabelAr: "محرك سيارة", unitLabelEn: "Car Engine")
            ]

        case "density":
            // baseValue is in kg/m³
            return [
                RealWorldItem(emoji: "💨", titleAr: "هواء الغرفة (1.2 كغ/م³)", titleEn: "Room Air (1.2 kg/m³)", factorInBase: 1.2, unitLabelAr: "هواء", unitLabelEn: "Air"),
                RealWorldItem(emoji: "💧", titleAr: "الماء النقي عند 4° (1000 كغ/م³)", titleEn: "Pure Water at 4°C (1000 kg/m³)", factorInBase: 1000, unitLabelAr: "ماء", unitLabelEn: "Water"),
                RealWorldItem(emoji: "🪙", titleAr: "الذهب الخالص (19300 كغ/م³)", titleEn: "Pure Gold (19,300 kg/m³)", factorInBase: 19_300, unitLabelAr: "ذهب", unitLabelEn: "Gold")
            ]

        case "data-rate":
            // baseValue is in bit/s
            return [
                RealWorldItem(emoji: "🎵", titleAr: "بث أغنية عالية الجودة (320 كيلوبت/ث)", titleEn: "High-Quality Audio (320 kbit/s)", factorInBase: 320_000, unitLabelAr: "بث صوتي", unitLabelEn: "Audio Stream"),
                RealWorldItem(emoji: "🎬", titleAr: "بث فيلم 4K (25 ميجابت/ث)", titleEn: "4K Video Stream (25 Mbit/s)", factorInBase: 25_000_000, unitLabelAr: "بث 4K", unitLabelEn: "4K Stream"),
                RealWorldItem(emoji: "🏠", titleAr: "إنترنت منزلي سريع (500 ميجابت/ث)", titleEn: "Fast Home Internet (500 Mbit/s)", factorInBase: 500_000_000, unitLabelAr: "إنترنت منزلي", unitLabelEn: "Home Internet")
            ]

        default:
            return []
        }
    }
}







