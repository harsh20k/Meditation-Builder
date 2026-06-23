//
//  CommunityHomeView.swift
//  Meditation Builder
//

import SwiftUI

enum CommunitySegment: String, CaseIterable {
    case discover
    case forYou

    var title: String {
        switch self {
        case .discover: return String(localized: "community.segment.discover")
        case .forYou: return String(localized: "community.segment.forYou")
        }
    }
}

struct CommunityHomeView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var segment: CommunitySegment = .discover
    @State private var showSearch = false
    @State private var showCreatorProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    segmentPicker
                    segmentContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSearch) {
                RoutineSearchView()
            }
            .navigationDestination(isPresented: $showCreatorProfile) {
                CreatorProfileView()
            }
        }
        .liquidGlassNavigationBar()
    }

    private var header: some View {
        HStack {
            Text(LocalizedStringKey("community.title"))
                .font(AppTheme.Typography.titleFont)
                .foregroundColor(AppTheme.offWhiteText)
            Spacer()
            if authManager.isAuthenticated {
                Button {
                    showCreatorProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(AppTheme.accentColor)
                }
                .accessibilityLabel("Your published routines")
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.section)
        .padding(.bottom, AppTheme.Spacing.medium)
    }

    private var segmentPicker: some View {
        Picker("Segment", selection: $segment) {
            ForEach(CommunitySegment.allCases, id: \.self) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.medium)
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch segment {
        case .discover:
            RoutineBrowseView(onSearchTap: { showSearch = true })
        case .forYou:
            if authManager.isAuthenticated {
                RecommendationsFeedView()
            } else {
                SignInPromptView(
                    message: String(localized: "community.signIn.forYou"),
                    onSignIn: { Task { try? await authManager.signInWithApple() } }
                )
            }
        }
    }
}

// MARK: - Recommendations Feed

private struct RecommendationsFeedView: View {
    @State private var routines: [CommunityRoutine] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
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
                    icon: "sparkles",
                    title: String(localized: "community.recommendations.empty.title"),
                    message: String(localized: "community.recommendations.empty.message")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(routines) { routine in
                            NavigationLink(value: routine) {
                                CommunityRoutineRow(routine: routine)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.tabBarClearance)
                }
            }
        }
        .navigationDestination(for: CommunityRoutine.self) { routine in
            CommunityRoutineDetailView(routineId: routine.routineId, preview: routine)
        }
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            routines = try await CommunityAPIClient.shared.getRecommendations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CommunityHomeView()
        .environment(AuthManager())
}
