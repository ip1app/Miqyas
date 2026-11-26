import SwiftUI
import StoreKit

// MARK: - Unit Converter View (Detail Screen)

struct ConverterView: View {
    let category: UnitCategory

    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var fromIndex: Int = 0
    @State private var toIndex: Int = 1
    @State private var inputAmount: String = "1"
    @State private var showingToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var swapRotation: Double = 0
    @State private var selectingSheetType: UnitSheetType?
    @State private var showingCustomKeypad: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var reviewWatchTask: Task<Void, Never>?
    @State private var didRegisterVisibleBaseline = false

    /// Wait until a result has settled before counting it, so keypad entry and
    /// quick edits become one conversion. The system review dialog is requested
    /// only after that pause, and never while the text field is focused.
    private static let settledConversionDelay: UInt64 = 600_000_000

    enum UnitSheetType: Identifiable {
        case from, to
        var id: Int { hashValue }
    }

    var fromUnit: Unit {
        category.units[safe: fromIndex] ?? category.units[0]
    }

    var toUnit: Unit {
        category.units[safe: toIndex] ?? category.units[min(1, category.units.count - 1)]
    }

    private func normalizeDigits(_ str: String) -> String {
        let arabicToAscii: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
            "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9",
            "٫": ".", ",": "."
        ]
        return String(str.map { arabicToAscii[$0] ?? $0 })
    }

    var numericValue: Double? {
        let normalized = normalizeDigits(inputAmount)
        return Double(normalized)
    }

    var convertedValue: String {
        guard let amount = numericValue else {
            return "—"
        }
        let baseValue = fromUnit.toBase(amount)
        let result = toUnit.fromBase(baseValue)

        if result.isInfinite || result.isNaN {
            return settings.l10n.error
        } else if settings.useScientificNotation && (abs(result) >= 1_000_000 || (abs(result) < 0.0001 && result != 0)) {
            return String(format: "%.3e", result)
        } else {
            return formatDecimal(result, maxFractionDigits: settings.maxDecimalDigits, locale: Locale(identifier: settings.appLanguage.rawValue), usesGroupingSeparator: settings.useThousandsSeparator)
        }
    }

    var fullFormulaString: String {
        guard let amount = numericValue else { return "" }
        return "\(formatNumber(amount)) \(fromUnit.name(for: settings.appLanguage)) = \(convertedValue) \(toUnit.name(for: settings.appLanguage))"
    }

    var shareText: String {
        guard let amount = numericValue else { return "" }
        return shareTextForConversion(
            fromValue: formatNumber(amount),
            fromUnitName: fromUnit.name(for: settings.appLanguage),
            toValue: convertedValue,
            toUnitName: toUnit.name(for: settings.appLanguage),
            categoryTitle: category.title(for: settings.appLanguage),
            lang: settings.appLanguage
        )
    }

    private func formatNumber(_ num: Double) -> String {
        formatDecimal(num, maxFractionDigits: settings.maxDecimalDigits, locale: Locale(identifier: settings.appLanguage.rawValue), usesGroupingSeparator: settings.useThousandsSeparator)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Hero Header Card (smoothly collapses when keyboard is active to keep result card visible)
                if !isInputFocused {
                    heroHeaderView
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                }

                // Converter Dual Cards (From & To)
                VStack(spacing: 12) {
                    fromInputCard
                    swapButtonView
                    toResultCard
                }

                // Quick Adjustments Chips
                quickAdjustmentsBar

                // Real-World Visual Insights Card
                realWorldInsightsSection

                // Custom Built-in Keypad Toggle & Section
                keypadSection

                // Live Multi-Unit Matrix
                allUnitsMatrixSection

                Color.clear.frame(height: 50)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isInputFocused)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            if isInputFocused {
                isInputFocused = false
            }
        }
        .background(NeonAmbientBackground())
        .navigationTitle(category.title(for: settings.appLanguage))
        .navigationBarTitleDisplayMode(.inline)

        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    inputAmount = ""
                    settings.triggerFeedback(impact: .light)
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if numericValue != nil {
                    HStack(spacing: 6) {
                        Text("=")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        Text(convertedValue)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(toUnit.abbreviation)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
                }

                Spacer()

                Button {
                    isInputFocused = false
                    settings.triggerFeedback(impact: .medium)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.subheadline.bold())
                        Text(settings.l10n.done)
                            .font(.headline.bold())
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    ShareLink(
                        item: shareText,
                        subject: Text(settings.l10n.shareSubject)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        settings.triggerFeedback(impact: .light)
                    })

                    favoriteHeaderButton
                }
            }
        }
        .sheet(item: $selectingSheetType) { sheet in
            switch sheet {
            case .from:
                UnitSelectionSheet(
                    title: settings.l10n.selectFromTitle,
                    units: category.units,
                    selectedIndex: $fromIndex
                )
                .environmentObject(settings)
            case .to:
                UnitSelectionSheet(
                    title: settings.l10n.selectToTitle,
                    units: category.units,
                    selectedIndex: $toIndex
                )
                .environmentObject(settings)
            }
        }
        .overlay(alignment: .bottom) {
            if showingToast {
                toastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            // The value already on screen is a reload, not a new conversion.
            // Only the first appearance sets that baseline, so a later edit is
            // still counted if SwiftUI calls onAppear again.
            guard !didRegisterVisibleBaseline else { return }
            didRegisterVisibleBaseline = true
            settings.registerSuccessfulConversion(
                normalizedInput: normalizeDigits(inputAmount),
                result: finiteConvertedNumber,
                signature: conversionSignature,
                isReload: true
            )
        }
        .onChange(of: conversionSignature) { _, _ in
            // Keystrokes in the focused field are not conversions yet.
            guard !isInputFocused else { return }
            scheduleConversionReviewCheck()
        }
        .onChange(of: isInputFocused) { _, focused in
            if focused {
                reviewWatchTask?.cancel()
            } else {
                scheduleConversionReviewCheck()
            }
        }
        .onDisappear {
            reviewWatchTask?.cancel()
            if !isInputFocused {
                commitConversionForReview(requestPrompt: false)
            }
            recordHistory()
        }
    }

    // MARK: - Subviews

    private var heroHeaderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: category.gradientColors.map { $0.opacity(0.85) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
                .blur(radius: 5)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: 66, height: 66)
                        .blur(radius: 12)

                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 58, height: 58)

                    Image(systemName: category.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title(for: settings.appLanguage))
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text(category.subtitle(for: settings.appLanguage))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                Text("\(category.units.count) \(settings.l10n.unitsSuffix)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: category.gradientColors.first?.opacity(0.3) ?? Color.clear, radius: 12, y: 6)
    }

    private var favoriteHeaderButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                settings.toggleFavorite(category.id)
            }
        } label: {
            Image(systemName: settings.isFavorite(category.id) ? "star.fill" : "star")
                .font(.title3)
                .foregroundColor(settings.isFavorite(category.id) ? .yellow : .primary)
                .scaleEffect(settings.isFavorite(category.id) ? 1.15 : 1.0)
        }
    }

    private var fromInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text(settings.l10n.fromLabel)
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    selectingSheetType = .from
                    settings.triggerFeedback()
                } label: {
                    HStack(spacing: 6) {
                        Text(fromUnit.name(for: settings.appLanguage))
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(fromUnit.abbreviation)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue)
                            .clipShape(Capsule())

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            HStack(spacing: 8) {
                TextField("0", text: $inputAmount)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)

                if !inputAmount.isEmpty {
                    Button {
                        inputAmount = ""
                        settings.triggerFeedback()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    if let clip = UIPasteboard.general.string, !clip.isEmpty {
                        inputAmount = clip
                        triggerToast(settings.l10n.pastedToast)
                        settings.triggerFeedback()
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }

    private var swapButtonView: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    let temp = fromIndex
                    fromIndex = toIndex
                    toIndex = temp
                    swapRotation += 180
                }
                settings.triggerFeedback(impact: .medium)
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.blue.opacity(0.35), radius: 8, y: 4)

                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(swapRotation))
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.vertical, -4)
    }

    private var toResultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(settings.l10n.toLabel)
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    selectingSheetType = .to
                    settings.triggerFeedback()
                } label: {
                    HStack(spacing: 6) {
                        Text(toUnit.name(for: settings.appLanguage))
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(toUnit.abbreviation)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .clipShape(Capsule())

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            HStack(alignment: .center) {
                Text(convertedValue)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Spacer()

                HStack(spacing: 8) {
                    ShareLink(
                        item: shareText,
                        subject: Text(settings.l10n.shareSubject)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.85), Color.teal.opacity(0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.green.opacity(0.25), radius: 4, y: 2)
                            .contentShape(Circle())
                    }
                    .accessibilityLabel(settings.l10n.shareBtn)
                    .simultaneousGesture(TapGesture().onEnded {
                        settings.triggerFeedback(impact: .light)
                    })

                    Button {
                        UIPasteboard.general.string = convertedValue
                        triggerToast(settings.l10n.copiedToast)
                        settings.triggerFeedback(impact: .medium)
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, y: 2)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(settings.l10n.copyBtn)
                }
            }

            if !fullFormulaString.isEmpty {
                Text(fullFormulaString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }

    private var quickAdjustmentsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                adjustmentButton(label: "+1") {
                    addAmount(1)
                }
                adjustmentButton(label: "+10") {
                    addAmount(10)
                }
                adjustmentButton(label: "+100") {
                    addAmount(100)
                }
                adjustmentButton(label: settings.l10n.doubleBtn) {
                    multiplyAmount(2)
                }
                adjustmentButton(label: settings.l10n.halfBtn) {
                    multiplyAmount(0.5)
                }
                adjustmentButton(label: settings.l10n.resetBtn) {
                    inputAmount = "1"
                    settings.triggerFeedback()
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func adjustmentButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 0.8)
                )
        }
    }

    private func addAmount(_ val: Double) {
        let current = numericValue ?? 0
        inputAmount = formatNumber(max(0, current + val))
        settings.triggerFeedback()
    }

    private func multiplyAmount(_ val: Double) {
        let current = numericValue ?? 1
        inputAmount = formatNumber(current * val)
        settings.triggerFeedback()
    }

    private var keypadSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showingCustomKeypad.toggle()
                    }
                    settings.triggerFeedback()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showingCustomKeypad ? "keyboard.chevron.compact.down" : "circle.grid.3x3.fill")
                            .font(.subheadline)
                        Text(showingCustomKeypad ? settings.l10n.hideKeypad : settings.l10n.showKeypad)
                            .font(.subheadline.bold())
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showingCustomKeypad ? 180 : 0))
                    }
                    .foregroundColor(.blue)
                    .padding(12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(14)
                }
            }

            if showingCustomKeypad {
                ModernNumericKeypad(inputAmount: $inputAmount)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    @ViewBuilder
    private var realWorldInsightsSection: some View {
        if let amount = numericValue {
            let baseVal = fromUnit.toBase(amount)
            let items = RealWorldHelper.insights(for: category.id, baseValue: baseVal)

            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings.l10n.realWorldTitle)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text(settings.l10n.realWorldSubtitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 9) {
                        ForEach(items.indices, id: \.self) { idx in
                            insightRow(items[idx], baseVal: baseVal)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemGroupedBackground).opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.blue.opacity(0.08), radius: 12, y: 5)
            }
        }
    }

    @ViewBuilder
    private func insightRow(_ item: RealWorldItem, baseVal: Double) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                Text(item.emoji)
                    .font(.system(size: 22))
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title(for: settings.appLanguage))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if item.isThreshold {
                    Text(item.thresholdText(baseValue: baseVal, lang: settings.appLanguage))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(baseVal >= item.factorInBase ? Color.orange : Color.cyan)
                } else {
                    Text("\(settings.l10n.realWorldEquivalent) \(formatRatio(baseVal / item.factorInBase)) \(item.unitLabel(for: settings.appLanguage))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.cyan)
                }
            }

            Spacer()

            if !item.isThreshold {
                Text(formatRatio(baseVal / item.factorInBase) + "×")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.12))
                    )
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.blue.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func formatRatio(_ val: Double) -> String {
        if val >= 100 {
            return String(format: "%.0f", val)
        } else if val >= 10 {
            return String(format: "%.1f", val)
        } else if val >= 0.01 {
            return String(format: "%.2f", val)
        } else {
            return String(format: "%.4f", val)
        }
    }

    private var allUnitsMatrixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.blue)
                Text("\(settings.l10n.multiUnitHeader) \(category.title(for: settings.appLanguage))")
                    .font(.headline)
                Spacer()
                Text(settings.l10n.tapToSelect)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            LazyVStack(spacing: 8) {
                ForEach(category.units) { unit in
                    let isTarget = (unit.id == toUnit.id)
                    let isSource = (unit.id == fromUnit.id)
                    let unitVal = calculateValue(for: unit)

                    Button {
                        if let idx = category.units.firstIndex(where: { $0.id == unit.id }) {
                            toIndex = idx
                            settings.triggerFeedback()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(unit.abbreviation)
                                .font(.system(.subheadline, design: .monospaced).bold())
                                .foregroundColor(isTarget ? .white : .primary)
                                .frame(width: 44, height: 32)
                                .background(isTarget ? Color.green : Color(.systemGray5))
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(unit.name(for: settings.appLanguage))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)

                                if isSource {
                                    Text(settings.l10n.sourceUnitBadge)
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }

                            Spacer()

                            Text(unitVal)
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundColor(isTarget ? .green : .primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isTarget ? Color.green.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isTarget ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func calculateValue(for unit: Unit) -> String {
        guard let amount = numericValue else { return "—" }
        let base = fromUnit.toBase(amount)
        let res = unit.fromBase(base)

        if res.isInfinite || res.isNaN {
            return "—"
        } else if abs(res) >= 1_000_000 || (abs(res) < 0.0001 && res != 0) {
            return String(format: "%.3e", res)
        } else {
            return formatDecimal(res, maxFractionDigits: 4, locale: Locale(identifier: settings.appLanguage.rawValue), usesGroupingSeparator: settings.useThousandsSeparator)
        }
    }

    private var toastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(toastMessage)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
    }

    private func triggerToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring()) {
            showingToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.spring()) {
                showingToast = false
            }
        }
    }

    private var conversionSignature: String {
        let input = normalizeDigits(inputAmount).trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(category.id)|\(fromUnit.id)|\(toUnit.id)|\(input)"
    }

    private var finiteConvertedNumber: Double? {
        guard let amount = numericValue else { return nil }
        let result = toUnit.fromBase(fromUnit.toBase(amount))
        return result.isFinite ? result : nil
    }

    private func scheduleConversionReviewCheck() {
        reviewWatchTask?.cancel()
        reviewWatchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.settledConversionDelay)
            guard !Task.isCancelled else { return }
            // Still typing into the field: wait until it is dismissed.
            guard !isInputFocused else { return }
            commitConversionForReview(requestPrompt: true)
        }
    }

    private func commitConversionForReview(requestPrompt: Bool) {
        let outcome = settings.registerSuccessfulConversion(
            normalizedInput: normalizeDigits(inputAmount),
            result: finiteConvertedNumber,
            signature: conversionSignature,
            isReload: false
        )
        guard requestPrompt, outcome.shouldRequestReview else { return }
        requestReview()
        settings.markReviewRequestedForCurrentVersion()
    }

    private func recordHistory() {
        guard numericValue != nil else { return }
        settings.addHistoryRecord(
            category: category,
            fromVal: inputAmount,
            fromUnit: fromUnit,
            toVal: convertedValue,
            toUnit: toUnit
        )
    }
}
