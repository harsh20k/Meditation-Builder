//
//  AmbientSoundMixerView.swift
//  Meditation Builder
//

import SwiftUI

struct AmbientSoundMixerView: View {
    @State private var engine = AmbientSoundEngine()

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 26, weight: .bold))
                        .accessibilityHidden(true)
                    Text(LocalizedStringKey("tab.sounds"))
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.extraLarge)
                .padding(.bottom, AppTheme.Spacing.medium)

                // Master Volume
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(AppTheme.lightGrey)
                            .font(.system(size: 14))
                            .accessibilityHidden(true)
                        Text(LocalizedStringKey("sounds.master.volume"))
                            .font(AppTheme.Typography.captionFont)
                            .foregroundColor(AppTheme.lightGrey)
                        Spacer()
                        Text("\(Int(engine.masterVolume * 100))%")
                            .font(AppTheme.Typography.captionFont)
                            .foregroundColor(AppTheme.lightGrey)
                    }
                    Slider(value: $engine.masterVolume, in: 0...1)
                        .tint(AppTheme.accentColor)
                        .accessibilityLabel("Master volume")
                        .accessibilityValue("\(Int(engine.masterVolume * 100)) percent")
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.medium)

                // Track List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(engine.tracks) { track in
                            AmbientTrackRow(track: track, engine: engine)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // tab bar clearance
                }
            }
        }
    }
}

// MARK: - Track Row

private struct AmbientTrackRow: View {
    @Bindable var track: AmbientTrack
    let engine: AmbientSoundEngine

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(track.isEnabled
                              ? AppTheme.accentColor.opacity(0.2)
                              : AppTheme.cardColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: track.sound.icon)
                        .foregroundColor(track.isEnabled ? AppTheme.accentColor : AppTheme.lightGrey)
                        .font(.system(size: 18, weight: .medium))
                        .symbolEffect(.breathe, isActive: track.isEnabled)
                }

                // Name
                Text(track.sound.displayName)
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(track.isEnabled ? AppTheme.offWhiteText : AppTheme.lightGrey)

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { track.isEnabled },
                    set: { engine.setEnabled($0, for: track.id) }
                ))
                .tint(AppTheme.accentColor)
                .labelsHidden()
                .accessibilityLabel("\(track.sound.displayName) sound")
                .accessibilityHint(track.isEnabled ? "On. Double-tap to disable." : "Off. Double-tap to enable.")
                .sensoryFeedback(.impact(flexibility: .soft), trigger: track.isEnabled)
            }

            // Volume Slider (only when enabled)
            if track.isEnabled {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(AppTheme.lightGrey)
                        .font(.system(size: 12))
                    Slider(
                        value: Binding(
                            get: { track.volume },
                            set: { engine.setVolume($0, for: track.id) }
                        ),
                        in: 0...1
                    )
                    .tint(AppTheme.accentColor)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(AppTheme.lightGrey)
                        .font(.system(size: 12))
                }
                .padding(.leading, 56) // align under name
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .animation(.easeInOut(duration: 0.2), value: track.isEnabled)
    }
}

#Preview {
    AmbientSoundMixerView()
        .preferredColorScheme(.dark)
}
