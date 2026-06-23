//
//  CreatorProfileView.swift
//  Meditation Builder
//

import SwiftUI

struct CreatorProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var routines: [CommunityRoutine] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var routineToDelete: CommunityRoutine?
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            if !authManager.isAuthenticated {
                SignInPromptView(
                    message: String(localized: "community.signIn.profile"),
                    onSignIn: { Task { try? await authManager.signInWithApple() } }
                )
            } else if isLoading && routines.isEmpty {
                ProgressView().tint(AppTheme.accentColor)
            } else if let errorMessage, routines.isEmpty {
                CommunityEmptyState(
                    icon: "exclamationmark.triangle",
                    title: String(localized: "community.error.title"),
                    message: errorMessage
                )
            } else if routines.isEmpty {
                CommunityEmptyState(
                    icon: "square.and.arrow.up",
                    title: String(localized: "community.profile.empty.title"),
                    message: String(localized: "community.profile.empty.message")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(routines) { routine in
                            publishedRoutineCard(routine)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.medium)
                }
            }
        }
        .navigationTitle(String(localized: "community.profile.title"))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
        .confirmationDialog(
            String(localized: "community.unpublish.confirm.title"),
            isPresented: $showDeleteConfirm,
            presenting: routineToDelete
        ) { routine in
            Button(String(localized: "community.unpublish.button"), role: .destructive) {
                Task { await unpublish(routine) }
            }
            Button(String(localized: "button.cancel"), role: .cancel) {}
        } message: { routine in
            Text(String.localizedStringWithFormat(
                String(localized: "community.unpublish.confirm.message"),
                routine.name
            ))
        }
    }

    private func publishedRoutineCard(_ routine: CommunityRoutine) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                NavigationLink {
                    CommunityRoutineDetailView(routineId: routine.routineId, preview: routine)
                } label: {
                    Text(routine.name)
                        .font(AppTheme.Typography.headlineFontLarge)
                        .foregroundColor(AppTheme.offWhiteText)
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    routineToDelete = routine
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
                .accessibilityLabel("Unpublish \(routine.name)")
            }

            HStack(spacing: AppTheme.Spacing.large) {
                Label("\(routine.likeCount)", systemImage: "heart.fill")
                Label("\(routine.importCount)", systemImage: "square.and.arrow.down")
            }
            .font(AppTheme.Typography.captionFont)
            .foregroundColor(AppTheme.lightGrey)

            if !routine.tags.isEmpty {
                CommunityTagRow(tags: routine.tags)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }

    private func load() async {
        guard let sub = authManager.currentUserSub else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let ids = PublishedRoutineStore.ids(for: sub)
        guard !ids.isEmpty else {
            routines = []
            return
        }

        var loaded: [CommunityRoutine] = []
        for id in ids {
            if let routine = try? await CommunityAPIClient.shared.getRoutine(id: id) {
                loaded.append(routine)
            }
        }
        routines = loaded.sorted {
            ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
        }
    }

    private func unpublish(_ routine: CommunityRoutine) async {
        do {
            try await CommunityAPIClient.shared.deleteRoutine(id: routine.routineId)
            routines.removeAll { $0.routineId == routine.routineId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CreatorProfileView()
    }
    .environment(AuthManager())
}
