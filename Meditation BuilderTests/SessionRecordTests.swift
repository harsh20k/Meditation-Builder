//
//  SessionRecordTests.swift
//  Meditation BuilderTests
//

import Testing
import Foundation
@testable import Meditation_Builder

@Suite("SessionRecord")
struct SessionRecordTests {

    // MARK: - Event Timeline

    @Test("startTime returns first start event")
    func startTimeIsFirstStart() {
        let t0 = Date()
        let record = SessionRecord(routineID: UUID())
        record.addEvent(.start(t0))
        record.addEvent(.finish(t0.addingTimeInterval(60)))

        #expect(record.startTime == t0)
    }

    @Test("finishTime returns last finish event")
    func finishTimeIsLastFinish() {
        let t0 = Date()
        let t1 = t0.addingTimeInterval(300)
        let record = SessionRecord(routineID: UUID())
        record.addEvent(.start(t0))
        record.addEvent(.finish(t1))

        #expect(record.finishTime == t1)
    }

    @Test("finishTime is nil when no finish event")
    func finishTimeNilWithoutFinish() {
        let record = SessionRecord(routineID: UUID())
        record.addEvent(.start(Date()))

        #expect(record.finishTime == nil)
    }

    // MARK: - Actual Meditation Time

    @Test("calculateActualMeditationTime excludes paused intervals")
    func meditationTimeExcludesPauses() {
        let t0 = Date()
        let record = SessionRecord(routineID: UUID())

        record.addEvent(.start(t0))
        record.addEvent(.pause(t0.addingTimeInterval(60)))   // pause after 60s active
        record.addEvent(.resume(t0.addingTimeInterval(120))) // paused for 60s
        record.addEvent(.finish(t0.addingTimeInterval(180))) // 60s more active → total 120s active

        let actual = record.calculateActualMeditationTime()
        #expect(abs(actual - 120) < 1)
    }

    @Test("calculateActualMeditationTime with no pauses equals wall time")
    func meditationTimeNoPauses() {
        let t0 = Date()
        let record = SessionRecord(routineID: UUID())
        record.addEvent(.start(t0))
        record.addEvent(.finish(t0.addingTimeInterval(300)))

        let actual = record.calculateActualMeditationTime()
        #expect(abs(actual - 300) < 1)
    }

    // MARK: - Pause Intervals

    @Test("getPauseIntervals returns matched pairs")
    func pauseIntervalsPaired() {
        let t0 = Date()
        let record = SessionRecord(routineID: UUID())
        record.addEvent(.start(t0))
        record.addEvent(.pause(t0.addingTimeInterval(30)))
        record.addEvent(.resume(t0.addingTimeInterval(60)))
        record.addEvent(.finish(t0.addingTimeInterval(120)))

        let intervals = record.getPauseIntervals()
        #expect(intervals.count == 1)
        #expect(abs(intervals[0].pause.timeIntervalSince(t0) - 30) < 1)
        #expect(intervals[0].resume != nil)
    }

    @Test("getPauseIntervals handles open pause at session end")
    func pauseIntervalsOpenPause() {
        let t0 = Date()
        let record = SessionRecord(routineID: UUID())
        record.addEvent(.start(t0))
        record.addEvent(.pause(t0.addingTimeInterval(30)))
        record.addEvent(.finish(t0.addingTimeInterval(60)))

        let intervals = record.getPauseIntervals()
        #expect(intervals.count == 1)
        #expect(intervals[0].resume == nil)
    }
}
