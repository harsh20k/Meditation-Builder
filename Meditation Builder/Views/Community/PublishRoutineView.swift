//
//  PublishRoutineView.swift
//  Meditation Builder
//

import SwiftUI
import SwiftData

enum PublishStep: Int, CaseIterable {
    case selectRoutine = 1
    case reviewTags = 2
    case confirm = 3
}

struct PublishRoutineView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<SavedRoutine> { !$0.isDeleted && !$0.isSystemRoutine },
           sort: \SavedRoutine.lastModified, order: .reverse)
    private var localRoutines: [SavedRoutine]

    let preselectedRoutine: SavedRoutine?

    @State private var step: PublishStep = .selectRoutine
    @State private var selectedRoutine: SavedRoutine?
    @State private var userDescription = ""
    @State private var publishedRoutine: CommunityRoutine?
    @State private var isPublishing = false
    @State private var isPollingTags = false
    @State private var errorMessage: String?

    init(preselectedRoutine: SavedRoutine? = nil) {
        self.preselectedRoutine = preselectedRoutine
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()

                if !authManager.isAuthenticated {
                    SignInPromptView(
                        message: String(localized: "community.signIn.publish"),
                        onSignIn: { Task { try? await authManager.signInWithApple() } }
                    )
                } else {
                    stepContent
                }
            }
            .navigationTitle(String(localized: "community.publish.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
            }
            .onAppear {
                if let preselectedRoutine {
                    selectedRoutine = preselectedRoutine
                    step = .reviewTags
                }
                CommunityAPIClient.shared.configure(authManager: authManager)
            }
        }
        .liquidGlassNavigationBar()
    }

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            stepIndicator

            switch step {
            case .selectRoutine:
                selectRoutineStep
            case .reviewTags:
                reviewTagsStep
            case .confirm:
                confirmStep
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private var stepIndicator: some View {
        HStack {
            ForEach(PublishStep.allCases, id: \.rawValue) { item in
                Circle()
                    .fill(item.rawValue <= step.rawValue ? AppTheme.accentColor : AppTheme.lightGrey.opacity(0.3))
                    .frame(width: 10, height: 10)
                if item != PublishStep.allCases.last {
                    Rectangle()
                        .fill(AppTheme.lightGrey.opacity(0.3))
                        .frame(height: 1)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.medium)
    }

    private var selectRoutineStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("community.publish.select.title"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)

            if localRoutines.isEmpty {
                Text(LocalizedStringKey("community.publish.select.empty"))
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.lightGrey)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(localRoutines) { routine in
                            Button {
                                selectedRoutine = routine
                                step = .reviewTags
                            } label: {
                                HStack {
                                    Text(routine.routineName)
                                        .font(AppTheme.Typography.bodyFont)
                                        .foregroundColor(AppTheme.offWhiteText)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.lightGrey)
                                }
                                .padding(AppTheme.Spacing.medium)
                                .background(AppTheme.cardColor)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var reviewTagsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if let selectedRoutine {
                Text(selectedRoutine.routineName)
                    .font(AppTheme.Typography.headlineFontLarge)
                    .foregroundColor(AppTheme.offWhiteText)
            }

            TextField(String(localized: "community.publish.description.placeholder"), text: $userDescription, axis: .vertical)
                .lineLimit(3...6)
                .font(AppTheme.Typography.bodyFont)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.searchBar)
                .cornerRadius(AppTheme.CornerRadius.medium)

            if isPublishing || isPollingTags {
                HStack {
                    ProgressView().tint(AppTheme.accentColor)
                    Text(isPublishing
                         ? String(localized: "community.publish.publishing")
                         : String(localized: "community.publish.tagging"))
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(AppTheme.lightGrey)
                }
            }

            if let publishedRoutine {
                if publishedRoutine.isTaggingPending && publishedRoutine.tags.isEmpty {
                    Text(LocalizedStringKey("community.publish.tags.pending"))
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(AppTheme.lightGrey)
                } else if !publishedRoutine.tags.isEmpty {
                    Text(LocalizedStringKey("community.publish.tags.title"))
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    CommunityTagRow(tags: publishedRoutine.tags)
                    if let description = publishedRoutine.description {
                        Text(description)
                            .font(AppTheme.Typography.bodyFont)
                            .foregroundColor(AppTheme.lightGrey)
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(.red.opacity(0.8))
            }

            Spacer()

            if publishedRoutine == nil {
                AppTheme.primaryButton(isEnabled: selectedRoutine != nil && !isPublishing, action: {
                    Task { await publish() }
                }) {
                    Text(LocalizedStringKey("community.publish.submit"))
                }
            } else {
                AppTheme.primaryButton(action: { step = .confirm }) {
                    Text(LocalizedStringKey("community.publish.continue"))
                }
            }
        }
    }

    private var confirmStep: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.accentColor)
            Text(LocalizedStringKey("community.publish.done.title"))
                .font(AppTheme.Typography.headlineFontLarge)
                .foregroundColor(AppTheme.offWhiteText)
            Text(LocalizedStringKey("community.publish.done.message"))
                .font(AppTheme.Typography.bodyFont)
                .foregroundColor(AppTheme.lightGrey)
                .multilineTextAlignment(.center)
            Spacer()
            AppTheme.primaryButton(action: { dismiss() }) {
                Text(LocalizedStringKey("button.done"))
            }
        }
    }

    private func publish() async {
        guard let selectedRoutine else { return }
        isPublishing = true
        errorMessage = nil
        defer { isPublishing = false }
        do {
            let routine = selectedRoutine.getRoutine()
            let result = try await CommunityAPIClient.shared.publishRoutine(routine, userDescription: userDescription.isEmpty ? nil : userDescription)
            publishedRoutine = result
            await pollForTags(routineId: result.routineId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pollForTags(routineId: String) async {
        isPollingTags = true
        defer { isPollingTags = false }
        for _ in 0..<10 {
            try? await Task.sleep(for: .seconds(1.5))
            if let detail = try? await CommunityAPIClient.shared.getRoutine(id: routineId),
               !detail.tags.isEmpty || detail.description != nil {
                publishedRoutine = detail
                return
            }
        }
    }
}

#Preview {
    PublishRoutineView()
        .environment(AuthManager())
}
