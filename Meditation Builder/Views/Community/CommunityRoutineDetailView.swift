//
//  CommunityRoutineDetailView.swift
//  Meditation Builder
//

import SwiftUI
import SwiftData

struct CommunityRoutineDetailView: View {
    let routineId: String
    let preview: CommunityRoutine?

    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var routine: CommunityRoutine?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var isTogglingLike = false
    @State private var isImporting = false
    @State private var showImportSuccess = false
    @State private var showAlreadyImported = false
    @State private var showSignInPrompt = false

    private var displayRoutine: CommunityRoutine? { routine ?? preview }

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            if isLoading && displayRoutine == nil {
                ProgressView()
                    .tint(AppTheme.accentColor)
            } else if let errorMessage, displayRoutine == nil {
                CommunityEmptyState(
                    icon: "exclamationmark.triangle",
                    title: String(localized: "community.error.title"),
                    message: errorMessage
                )
            } else if let displayRoutine {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                        header(for: displayRoutine)
                        if let description = displayRoutine.description, !description.isEmpty {
                            Text(description)
                                .font(AppTheme.Typography.bodyFont)
                                .foregroundColor(AppTheme.lightGrey)
                        }
                        if !displayRoutine.tags.isEmpty {
                            CommunityTagRow(tags: displayRoutine.tags)
                        }
                        actionBar(for: displayRoutine)
                        blocksSection(for: displayRoutine)
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.extraLarge)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
        .alert(String(localized: "community.import.success.title"), isPresented: $showImportSuccess) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "community.import.success.message"))
        }
        .alert(String(localized: "community.import.already.title"), isPresented: $showAlreadyImported) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "community.import.already.message"))
        }
        .sheet(isPresented: $showSignInPrompt) {
            NavigationStack {
                SignInPromptView(
                    message: String(localized: "community.signIn.actions"),
                    onSignIn: {
                        Task {
                            try? await authManager.signInWithApple()
                            showSignInPrompt = false
                        }
                    }
                )
                .navigationTitle(String(localized: "community.signIn.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "button.cancel")) { showSignInPrompt = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func header(for routine: CommunityRoutine) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(routine.name)
                .font(AppTheme.Typography.titleFont)
                .foregroundColor(AppTheme.offWhiteText)
            HStack {
                if let author = routine.authorName {
                    Label(author, systemImage: "person.fill")
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(AppTheme.lightGrey)
                }
                Spacer()
                Text(String.localizedStringWithFormat(
                    String(localized: "routine.duration.format.simplified"),
                    routine.durationMinutes
                ))
                .font(AppTheme.Typography.captionFont)
                .foregroundColor(AppTheme.lightGrey)
            }
        }
        .padding(.top, AppTheme.Spacing.medium)
    }

    private var isImported: Bool { routine?.isImportedByMe == true }

    private func actionBar(for routine: CommunityRoutine) -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Button {
                guardAuth { Task { await toggleLike() } }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                    Text("\(likeCount)")
                }
                .font(AppTheme.Typography.bodyFont)
                .foregroundColor(isLiked ? AppTheme.accentColor : AppTheme.offWhiteText)
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.cardColor)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .buttonStyle(.plain)

            AppTheme.primaryButton(isEnabled: !isImporting && !isImported, action: {
                guardAuth { Task { await importRoutine() } }
            }) {
                if isImporting {
                    ProgressView().tint(AppTheme.offWhiteText)
                } else if isImported {
                    Text(LocalizedStringKey("community.import.already.button"))
                } else {
                    Text(LocalizedStringKey("community.import.button"))
                }
            }
        }
    }

    private func blocksSection(for routine: CommunityRoutine) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("ritual.blocks.title"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)

            let blocks = routine.toLocalBlocks()
            if blocks.isEmpty {
                Text(LocalizedStringKey("community.blocks.unavailable"))
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                        TimelineBlockCard(
                            block: block,
                            isLast: index == blocks.count - 1,
                            index: index,
                            blocksCount: blocks.count
                        )
                    }
                }
            }
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        if let preview {
            likeCount = preview.likeCount
            isLiked = preview.isLikedByMe ?? false
        }
        defer { isLoading = false }
        do {
            let detail = try await CommunityAPIClient.shared.getRoutine(id: routineId)
            routine = detail
            likeCount = detail.likeCount
            isLiked = detail.isLikedByMe ?? false
        } catch CommunityAPIError.unauthorized {
            routine = preview
        } catch {
            if preview == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func toggleLike() async {
        guard !isTogglingLike else { return }
        isTogglingLike = true
        defer { isTogglingLike = false }

        // Optimistic update — apply immediately before the network round-trip.
        let rollbackLiked = isLiked
        let rollbackCount = likeCount
        let newLiked = !isLiked
        isLiked = newLiked
        likeCount = max(0, likeCount + (newLiked ? 1 : -1))
        broadcastLikeChange(likeCount: likeCount, isLiked: isLiked)

        do {
            // Write-behind: server commits to Redis immediately and flushes to
            // DynamoDB on a 60s schedule — UI doesn't wait for persistence.
            let serverCount = try await (newLiked
                ? CommunityAPIClient.shared.likeRoutine(id: routineId)
                : CommunityAPIClient.shared.unlikeRoutine(id: routineId))
            // Sync server count only if it diverged (concurrent likes from others).
            if likeCount != serverCount {
                likeCount = serverCount
                broadcastLikeChange(likeCount: serverCount, isLiked: isLiked)
            }
            routine?.likeCount = likeCount
            routine?.isLikedByMe = isLiked
        } catch CommunityAPIError.unauthorized {
            revertLike(liked: rollbackLiked, count: rollbackCount)
            showSignInPrompt = true
        } catch {
            revertLike(liked: rollbackLiked, count: rollbackCount)
            errorMessage = error.localizedDescription
        }
    }

    private func broadcastLikeChange(likeCount: Int, isLiked: Bool) {
        NotificationCenter.default.post(
            name: .communityRoutineLikeDidChange,
            object: nil,
            userInfo: ["routineId": routineId, "likeCount": likeCount, "isLiked": isLiked]
        )
    }

    private func revertLike(liked: Bool, count: Int) {
        isLiked = liked
        likeCount = count
        routine?.likeCount = count
        routine?.isLikedByMe = liked
        broadcastLikeChange(likeCount: count, isLiked: liked)
    }

    private func importRoutine() async {
        isImporting = true
        defer { isImporting = false }
        do {
            let response = try await CommunityAPIClient.shared.importRoutine(id: routineId)
            routine?.isImportedByMe = true

            if response.alreadyImported == true {
                showAlreadyImported = true
                return
            }

            let localRoutine = response.routine.toLocalRoutine()
            let saved = SavedRoutine(routine: localRoutine)
            modelContext.insert(saved)
            try modelContext.save()
            showImportSuccess = true
        } catch CommunityAPIError.unauthorized {
            showSignInPrompt = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func guardAuth(_ action: () -> Void) {
        if authManager.isAuthenticated {
            action()
        } else {
            showSignInPrompt = true
        }
    }
}

#Preview {
    NavigationStack {
        CommunityRoutineDetailView(
            routineId: "preview-id",
            preview: CommunityRoutine(
                routineId: "preview-id",
                name: "Morning Focus",
                description: "A gentle focus routine.",
                tags: ["focus", "morning"],
                durationSeconds: 600,
                authorName: "Jane D.",
                authorSub: nil,
                likeCount: 42,
                importCount: 17,
                blocks: nil,
                audioAssetKeys: nil,
                publishedAt: Date(),
                updatedAt: nil,
                isLikedByMe: false,
                isImportedByMe: false,
                taggingStatus: nil,
                score: nil
            )
        )
    }
    .environment(AuthManager())
}
