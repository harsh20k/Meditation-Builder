//
//  RoutineBrowseView.swift
//  Meditation Builder
//

import SwiftUI
import os

private let browseLog = Logger(subsystem: "com.AnimeAI.Meditation-Builder", category: "Browse")

struct RoutineBrowseView: View {
    let onSearchTap: () -> Void

    @State private var routines: [CommunityRoutine] = []
    @State private var nextToken: String?
    @State private var filters = BrowseFilters()
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showFilters = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            searchBar

            Group {
                if isLoading && routines.isEmpty {
                    ProgressView()
                        .tint(AppTheme.accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, routines.isEmpty {
                    CommunityEmptyState(
                        icon: "exclamationmark.triangle",
                        title: String(localized: "community.error.title"),
                        message: errorMessage
                    )
                } else if routines.isEmpty {
                    CommunityEmptyState(
                        icon: "books.vertical",
                        title: String(localized: "community.browse.empty.title"),
                        message: String(localized: "community.browse.empty.message")
                    )
                } else {
                    routineList
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            BrowseFilterSheet(filters: $filters) {
                Task { await reload() }
            }
        }
        .navigationDestination(for: CommunityRoutine.self) { routine in
            CommunityRoutineDetailView(routineId: routine.routineId, preview: routine)
        }
        .refreshable { await reload() }
        .task { await reload() }
        .onReceive(NotificationCenter.default.publisher(for: .communityRoutineLikeDidChange)) { notification in
            guard let routineId = notification.userInfo?["routineId"] as? String,
                  let likeCount = notification.userInfo?["likeCount"] as? Int,
                  let index = routines.firstIndex(where: { $0.routineId == routineId }) else { return }
            routines[index].likeCount = likeCount
            if let isLiked = notification.userInfo?["isLiked"] as? Bool {
                routines[index].isLikedByMe = isLiked
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Button(action: onSearchTap) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.lightGrey)
                    Text(LocalizedStringKey("community.search.placeholder"))
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.lightGrey)
                    Spacer()
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.searchBar)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .buttonStyle(.plain)

            Button {
                showFilters = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.accentColor)
            }
            .accessibilityLabel("Filter routines")
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private var routineList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(routines) { routine in
                    NavigationLink(value: routine) {
                        CommunityRoutineRow(routine: routine)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if routine.id == routines.last?.id {
                            Task { await loadMore() }
                        }
                    }
                }

                if isLoadingMore {
                    ProgressView()
                        .tint(AppTheme.accentColor)
                        .padding()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.tabBarClearance)
        }
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        nextToken = nil
        defer { isLoading = false }
        do {
            let response = try await CommunityAPIClient.shared.browseRoutines(nextToken: nil, filters: filters)
            routines = response.routines
            nextToken = response.nextToken
            browseLog.info("Browse page 1: \(response.routines.count) routines, hasMore=\(self.nextToken != nil)")
        } catch {
            errorMessage = error.localizedDescription
            routines = []
        }
    }

    private func loadMore() async {
        guard let token = nextToken, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await CommunityAPIClient.shared.browseRoutines(nextToken: token, filters: filters)
            routines.append(contentsOf: response.routines)
            nextToken = response.nextToken
            browseLog.info("Browse page loaded: +\(response.routines.count), total=\(self.routines.count), hasMore=\(self.nextToken != nil)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Filter Sheet

private struct BrowseFilterSheet: View {
    @Binding var filters: BrowseFilters
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tagText: String = ""
    @State private var minDuration: Double = 5
    @State private var maxDuration: Double = 60
    @State private var useDurationFilter = false

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "community.filter.tag")) {
                    TextField(String(localized: "community.filter.tag.placeholder"), text: $tagText)
                        .textInputAutocapitalization(.never)
                }

                Section(String(localized: "community.filter.duration")) {
                    Toggle(String(localized: "community.filter.duration.enable"), isOn: $useDurationFilter)
                    if useDurationFilter {
                        VStack(alignment: .leading) {
                            Text("\(Int(minDuration))–\(Int(maxDuration)) min")
                                .font(AppTheme.Typography.captionFont)
                            Slider(value: $minDuration, in: 1...120, step: 1)
                            Slider(value: $maxDuration, in: 1...120, step: 1)
                        }
                    }
                }

                Section(String(localized: "community.filter.sort")) {
                    Picker(String(localized: "community.filter.sort"), selection: $filters.sort) {
                        ForEach(BrowseSort.allCases, id: \.self) { sort in
                            Text(sort.displayName).tag(sort)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(String(localized: "community.filter.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "community.filter.apply")) {
                        filters.tag = tagText.isEmpty ? nil : tagText.lowercased()
                        if useDurationFilter {
                            filters.minDurationMinutes = Int(min(minDuration, maxDuration))
                            filters.maxDurationMinutes = Int(max(minDuration, maxDuration))
                        } else {
                            filters.minDurationMinutes = nil
                            filters.maxDurationMinutes = nil
                        }
                        onApply()
                        dismiss()
                    }
                }
            }
            .onAppear {
                tagText = filters.tag ?? ""
                if let min = filters.minDurationMinutes, let max = filters.maxDurationMinutes {
                    useDurationFilter = true
                    minDuration = Double(min)
                    maxDuration = Double(max)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        RoutineBrowseView(onSearchTap: {})
    }
}
