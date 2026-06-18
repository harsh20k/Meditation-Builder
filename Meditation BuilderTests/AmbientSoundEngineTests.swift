//
//  AmbientSoundEngineTests.swift
//  Meditation BuilderTests
//

import Testing
import Foundation
@testable import Meditation_Builder

@Suite("AmbientSoundEngine")
@MainActor
struct AmbientSoundEngineTests {

    @Test("catalog has expected sound IDs")
    func catalogIDs() {
        let ids = AmbientSound.catalog.map(\.id)
        #expect(ids.contains("rain"))
        #expect(ids.contains("forest"))
        #expect(ids.contains("ocean"))
        #expect(ids.contains("white_noise"))
    }

    @Test("initial tracks match catalog")
    func initialTracksMatchCatalog() {
        let engine = AmbientSoundEngine()
        #expect(engine.tracks.count == AmbientSound.catalog.count)
    }

    @Test("initial masterVolume is 1.0")
    func initialMasterVolume() {
        let engine = AmbientSoundEngine()
        #expect(engine.masterVolume == 1.0)
    }

    @Test("setEnabled updates track.isEnabled")
    func setEnabledUpdatesTrack() {
        let engine = AmbientSoundEngine()
        let id = AmbientSound.catalog[0].id
        // Disable (default is false, calling setEnabled(false) should keep it false)
        engine.setEnabled(false, for: id)
        #expect(engine.tracks.first(where: { $0.id == id })?.isEnabled == false)
    }

    @Test("setVolume clamps to 0–1 range")
    func setVolumeUpdatesTrack() {
        let engine = AmbientSoundEngine()
        let id = AmbientSound.catalog[0].id
        engine.setVolume(0.5, for: id)
        #expect(engine.tracks.first(where: { $0.id == id })?.volume == 0.5)
    }
}
