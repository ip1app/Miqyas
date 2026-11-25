import SwiftUI

// MARK: - History Screen

struct HistoryView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingClearAlert: Bool = false
    @State private var shareRecord: ConversionRecord?

    var body: some View {
        NavigationStack {
            Group {
                if settings.history.isEmpty {
                    ScrollView(showsIndicators: false) {
                        emptyStateView
                    }
                } else {
                    List {
                        if !settings.pinnedRecords.isEmpty {
                            Section {
                                ForEach(settings.pinnedRecords) { record in
                                    recordRow(record)
                                }
                            } header: {
                                Text(settings.l10n.pinnedSectionTitle)
                            }
                        }

                        if !settings.regularRecords.isEmpty {
                            Section {
                                ForEach(settings.regularRecords) { record in
                                    recordRow(record)
                                }
                            } header: {
                                Text(settings.l10n.historySectionTitle)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(NeonAmbientBackground())
            .navigationTitle(settings.l10n.historyTitle)
            .toolbar {
                if !settings.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert(settings.l10n.clearHistoryTitle, isPresented: $showingClearAlert) {
                Button(settings.l10n.cancel, role: .cancel) { }
                Button(settings.l10n.clearAll, role: .destructive) {
                    settings.clearHistory()
                }
            } message: {
                Text(settings.l10n.clearHistoryMsg)
            }
            .sheet(item: $shareRecord) { record in
                ActivityView(items: [record.shareText(for: settings.appLanguage)])
            }
        }
    }

    private func recordRow(_ record: ConversionRecord) -> some View {
        historyRow(record)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                recordSwipeActions(record)
            }
    }

    @ViewBuilder
    private func recordSwipeActions(_ record: ConversionRecord) -> some View {
        Button(role: .destructive) {
            settings.deleteRecord(record.id)
        } label: {
            Label(settings.l10n.deleteTitle, systemImage: "trash")
        }
        .tint(.red)

        Button {
            settings.togglePin(record.id)
        } label: {
            Label(record.isPinned ? settings.l10n.unpinTitle : settings.l10n.pinTitle, systemImage: record.isPinned ? "pin.slash" : "pin")
        }
        .tint(record.isPinned ? Color.orange : Color.yellow)
    }

    private func historyRow(_ record: ConversionRecord) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: record.categoryIcon)
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.categoryTitle(for: settings.appLanguage))
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                    Spacer()
                    Text(record.formattedDate(for: settings.appLanguage))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Text("\(record.fromValue) \(record.fromUnitName(for: settings.appLanguage))")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    Image(systemName: settings.appLanguage.arrowIcon)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(record.toValue) \(record.toUnitName(for: settings.appLanguage))")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                }
            }

            Spacer(minLength: 0)

            Button {
                settings.triggerFeedback(impact: .light)
                shareRecord = record
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.systemGray5).opacity(0.6))
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.l10n.shareBtn)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 60)

            Text(settings.l10n.emptyHistoryTitle)
                .font(.title3.bold())

            Text(settings.l10n.emptyHistoryMsg)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }
}
