//
//  RoutineSearchView.swift
//  Meditation Builder
//

import SwiftUI

struct RoutineSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var debouncedQuery = ""
    @State private var results: [CommunityRoutine] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var filters = SearchFilters()
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()

                VStack(spacing: AppTheme.Spacing.medium) {
                    searchField
                    content
                }
            }
            .navigationTitle(String(localized: "community.search.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
            }
            .navigationDestination(for: CommunityRoutine.self) { routine in
                CommunityRoutineDetailView(routineId: routine.routineId, preview: routine)
            }
            .onChange(of: query) { _, newValue in
                scheduleSearch(for: newValue)
            }
        }
        .liquidGlassNavigationBar()
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.lightGrey)
            TextField(String(localized: "community.search.placeholder"), text: $query)
                .font(AppTheme.Typography.bodyFont)
                .foregroundColor(AppTheme.offWhiteText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.lightGrey)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.searchBar)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.medium)
    }

    @ViewBuilder
    private var content: some View {
        if query.isEmpty {
            CommunityEmptyState(
                icon: "magnifyingglass",
                title: String(localized: "community.search.hint.title"),
                message: String(localized: "community.search.hint.message")
            )
        } else if isSearching && results.isEmpty {
            ProgressView()
                .tint(AppTheme.accentColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage, results.isEmpty {
            CommunityEmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "community.error.title"),
                message: errorMessage
            )
        } else if results.isEmpty && !debouncedQuery.isEmpty {
            CommunityEmptyState(
                icon: "doc.text.magnifyingglass",
                title: String(localized: "community.search.empty.title"),
                message: String(localized: "community.search.empty.message")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    ForEach(results) { routine in
                        NavigationLink(value: routine) {
                            CommunityRoutineRow(routine: routine)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
        }
    }

    private func scheduleSearch(for text: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch(query: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func performSearch(query: String) async {
        debouncedQuery = query
        guard !query.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            results = try await CommunityAPIClient.shared.search(query: query, filters: filters)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
    }
}

#Preview {
    RoutineSearchView()
}
