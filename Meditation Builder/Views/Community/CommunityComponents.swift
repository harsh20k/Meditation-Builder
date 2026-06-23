//
//  CommunityComponents.swift
//  Meditation Builder
//

import SwiftUI

struct CommunityRoutineRow: View {
    let routine: CommunityRoutine

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundStyle(AppTheme.offWhiteText)
                        .lineLimit(2)
                    if let author = routine.authorName {
                        Text(author)
                            .font(AppTheme.Typography.captionFont)
                            .foregroundStyle(AppTheme.lightGrey)
                    }
                }
                Spacer()
                Text("\(routine.durationMinutes) min")
                    .font(AppTheme.Typography.captionFont)
                    .foregroundStyle(AppTheme.lightGrey)
            }

            if !routine.tags.isEmpty {
                CommunityTagRow(tags: Array(routine.tags.prefix(3)))
            }

            HStack(spacing: AppTheme.Spacing.medium) {
                Label("\(routine.likeCount)", systemImage: "heart.fill")
                Label("\(routine.importCount)", systemImage: "square.and.arrow.down")
            }
            .font(AppTheme.Typography.captionFont)
            .foregroundStyle(AppTheme.lightGrey)
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.cardColor)
        )
    }
}

struct CommunityEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppTheme.accentColor)
            Text(title)
                .font(AppTheme.Typography.headlineFontLarge)
                .foregroundStyle(AppTheme.offWhiteText)
            Text(message)
                .font(AppTheme.Typography.bodyFont)
                .foregroundStyle(AppTheme.lightGrey)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.extraLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CommunityTagRow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(AppTheme.Typography.captionFont)
                        .foregroundStyle(AppTheme.offWhiteText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.cardColor)
                        )
                }
            }
        }
    }
}

struct SignInPromptView: View {
    let message: String
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraLarge) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppTheme.accentColor)

            Text(message)
                .font(AppTheme.Typography.bodyFont)
                .foregroundStyle(AppTheme.lightGrey)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)

            SignInWithAppleButtonView {
                onSignIn()
            }
            .frame(height: 48)
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .padding(.vertical, AppTheme.Spacing.extraLarge)
    }
}
