import SwiftUI

// MARK: - Settings Screen

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingResetAlert: Bool = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.0"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Language Switcher Section
                    settingsSection(title: settings.l10n.languageSection, icon: "globe") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(settings.l10n.appLanguageTitle)
                                    .font(.body)
                                Text(settings.l10n.appLanguageSubtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Picker("", selection: $settings.appLanguage) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.displayName).tag(lang)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 170)
                        }
                    }

                    // Appearance Section
                    settingsSection(title: settings.l10n.appearanceSection, icon: "paintbrush.fill") {
                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.l10n.appearanceTitle)
                                        .font(.body)
                                    Text(settings.l10n.appearanceSubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Picker("", selection: $settings.appColorScheme) {
                                    Text(settings.l10n.appearanceSystem).tag(AppColorScheme.system)
                                    Text(settings.l10n.appearanceLight).tag(AppColorScheme.light)
                                    Text(settings.l10n.appearanceDark).tag(AppColorScheme.dark)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                            }
                        }
                    }

                    // Precision & Format Section
                    settingsSection(title: settings.l10n.calcSection, icon: "number.circle.fill") {
                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.l10n.decimalDigitsTitle)
                                        .font(.body)
                                    Text(settings.l10n.decimalDigitsSubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Picker("", selection: $settings.maxDecimalDigits) {
                                    Text("2").tag(2)
                                    Text("4").tag(4)
                                    Text("6").tag(6)
                                    Text("8").tag(8)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }

                            Divider()

                            Toggle(isOn: $settings.useScientificNotation) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.l10n.scientificTitle)
                                        .font(.body)
                                    Text(settings.l10n.scientificSubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.blue)

                            Divider()

                            Toggle(isOn: $settings.useThousandsSeparator) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.l10n.thousandsTitle)
                                        .font(.body)
                                    Text(settings.l10n.thousandsSubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.blue)
                        }
                    }

                    // Interaction Section
                    settingsSection(title: settings.l10n.feedbackSection, icon: "hand.tap.fill") {
                        VStack(spacing: 14) {
                            Toggle(isOn: $settings.hapticFeedback) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.l10n.hapticTitle)
                                        .font(.body)
                                    Text(settings.l10n.hapticSubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.blue)

                            Divider()

                            Toggle(isOn: $settings.soundEffects) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.l10n.soundTitle)
                                        .font(.body)
                                    Text(settings.l10n.soundSubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.blue)
                        }
                    }

                    // History Section
                    settingsSection(title: settings.l10n.autoSaveSection, icon: "clock.arrow.circlepath") {
                        VStack(spacing: 14) {
                            Toggle(isOn: $settings.showConversionHistory) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.l10n.autoSaveHistoryTitle)
                                        .font(.body)
                                    Text(settings.l10n.autoSaveHistorySubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.blue)
                        }
                    }

                    // Home Layout Section
                    settingsSection(title: settings.l10n.layoutSectionTitle, icon: "rectangle.grid.2x2.fill") {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(settings.l10n.layoutSectionSubtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 10) {
                                layoutActionButton(
                                    title: settings.l10n.resetLayoutBtn,
                                    icon: "arrow.counterclockwise",
                                    tint: .blue
                                ) {
                                    settings.resetHomeLayout()
                                }

                                layoutActionButton(
                                    title: settings.l10n.showAllCards,
                                    icon: "eye.fill",
                                    tint: .green
                                ) {
                                    settings.showAllCategories()
                                }
                            }
                        }
                    }

                    // App Info Section
                    settingsSection(title: settings.l10n.aboutSection, icon: "info.circle.fill") {
                        VStack(spacing: 10) {
                            HStack {
                                Text(settings.l10n.appNameTitle)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(settings.l10n.appNameVal)
                                    .bold()
                            }
                            Divider()
                            HStack {
                                Text(settings.l10n.versionTitle)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(appVersion)
                                    .bold()
                            }
                            Divider()
                            if let reviewURL = URL(string: "https://apps.apple.com/app/id6838107268?action=write-review") {
                                Link(destination: reviewURL) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "star.fill")
                                            .font(.body)
                                            .foregroundColor(.yellow)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(settings.l10n.rateAppTitle)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Text(settings.l10n.rateAppSubtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.forward.app")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            Divider()
                            if let privacyURL = URL(string: "https://www.ip1.app/privacy.html") {
                                Link(destination: privacyURL) {
                                    HStack {
                                        Text(settings.l10n.privacyPolicyTitle)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.up.forward.app")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Reset Button
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text(settings.l10n.resetDefaultsBtn)
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                    }

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(NeonAmbientBackground())
            .navigationTitle(settings.l10n.settingsTitle)
            .alert(settings.l10n.resetAlertTitle, isPresented: $showingResetAlert) {
                Button(settings.l10n.cancel, role: .cancel) { }
                Button(settings.l10n.resetConfirm, role: .destructive) {
                    settings.favorites.removeAll()
                    settings.history.removeAll()
                    settings.categoryOrder = unitCategories.map(\.id)
                    settings.hiddenCategoryIds.removeAll()
                    settings.toolOrder = MeasuringTool.allCases.map(\.rawValue)
                    settings.hiddenMeasuringToolIds.removeAll()
                    settings.measuringToolFavoriteIDs.removeAll()
                    settings.maxDecimalDigits = 4
                    settings.useScientificNotation = true
                    settings.useThousandsSeparator = true
                    settings.soundEffects = true
                    settings.hapticFeedback = true
                    settings.showConversionHistory = true
                    settings.appColorScheme = .system
                    let preferred = Locale.preferredLanguages.first?.lowercased() ?? "ar"
                    settings.appLanguage = preferred.hasPrefix("ar") ? .arabic : .english
                }
            } message: {
                Text(settings.l10n.resetAlertMsg)
            }
        }
    }

    @ViewBuilder
    private func layoutActionButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: accentGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
        }
    }
}

