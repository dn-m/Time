//
//  TimelineTests.swift
//  Timeline
//
//  Created by James Bean on 6/23/16.
//
//

import XCTest
import DataStructures
import Math
import Time
@testable import Timeline

class TimelineTests: XCTestCase {

    func testTimeStampToFrame() {

        let timeStamp: Seconds = 0.5
        let timeline = Timeline(rate: 1/60)
        timeline.insert(at: timeStamp) { print("something") }
        
        XCTAssertEqual(timeline.schedule.atomic.base.count, 1)
    }
    
    func testStateAtInitStopped() {
        let timeline = Timeline()
        guard case .stopped = timeline.status else {
            XCTFail()
            return
        }
    }
    
    func testFrameCalculationPlaybackRateOfOne() {
        
        let rate: Seconds = 1/120
        let scheduledDate: Seconds = 2
        let expectedFrames: Ticks = 240
        
        let result = frames(
            scheduledDate: scheduledDate,
            lastPausedDate: 0,
            rate: rate,
            playbackRate: 1
        )
        
        XCTAssertEqual(expectedFrames, result)
    }
    
    func testFrameCalculationPlaybackRateChanged() {
        
        let rate: Seconds = 1/120
        
        // event scheduled at 2 seconds
        let scheduledDate: Seconds = 2
        
        // playback rate changed at 1 seconds
        let playbackRateChangedOffset: Seconds = 1
        
        // new playback rate: twice as fast
        let newPlaybackRate = 2.0
        
        let expectedFrames: Ticks = 180
        
        let result = frames(
            scheduledDate: scheduledDate,
            lastPausedDate: playbackRateChangedOffset,
            rate: rate,
            playbackRate: newPlaybackRate
        )
        
        XCTAssertEqual(expectedFrames, result)
    }
    
    // MARK: - Playback
    
    func testStateAfterStartPlaying() {
        let timeline = Timeline()
        timeline.start()
        guard case .playing = timeline.status else {
            XCTFail()
            return
        }
        timeline.stop()
    }
    
    func testFiveEventsGetTriggered() {
        
        let unfulfilledExpectation = expectation(description: "Counter")
        
        // Gross little counter for testing
        var count = 0
        let increment = { count += 1 }
        
        // Create Timeline
        let timeline = Timeline()
        
        // Fill up Timeline
        for offset in 0..<5 {
            timeline.insert(at: Seconds(offset), performing: increment)
        }
        
        timeline.insert(at: 5) {
            XCTAssertEqual(count, 5)
            unfulfilledExpectation.fulfill()
            timeline.stop()
        }
        
        // Get things started
        timeline.start()
        
        // Make sure we don't
        waitForExpectations(timeout: 5.1)
    }
    
    func testFiveEventsGetTriggeredByLooping() {
        
        let unfulfilledExpectation = expectation(description: "Counter looping")

        // Create Timeline
        let timeline = Timeline()
        
        // Gross little counter for testing
        var count = 0
        timeline.loop(every: 1, startingAt: 0) { count += 1 }
        
        timeline.insert(at: 4.1) {
            XCTAssertEqual(count, 5)
            timeline.stop()
            unfulfilledExpectation.fulfill()
        }
        
        timeline.start()
        waitForExpectations(timeout: 4.2)
    }
    
    func testPlaybackRateHalf() {
        
        let unfulfilledExpectation = expectation(description: "Playback rate: 0.5")
        
        let clock = Clock()
        let timeline = Timeline { unfulfilledExpectation.fulfill() }

        for offset in 0..<5 {
            
            // actual time
            let playbackTime = Seconds(offset) * 2
            
            timeline.insert(at: Seconds(offset)) {
                XCTAssertEqual(clock.elapsed, playbackTime, accuracy: 0.01)
            }
        }
        
        timeline.playbackRate = 0.5
        timeline.start()
        clock.start()
        
        waitForExpectations(timeout: 10) { _ in
            timeline.stop()
        }
    }
    
    func testPlaybackRateTwice() {
        
        let unfulfilledExpectation = expectation(description: "Playback rate: 2")
        
        let clock = Clock()
        let timeline = Timeline { unfulfilledExpectation.fulfill() }
        
        for offset in 0..<5 {
            
            // actual time
            let playbackTime = Seconds(offset) / 2
            
            timeline.insert(at: Seconds(offset)) {
                XCTAssertEqual(clock.elapsed, playbackTime, accuracy: 0.01)
            }
        }
        
        timeline.playbackRate = 2
        timeline.start()
        clock.start()
        
        waitForExpectations(timeout: 10) { _ in
            timeline.stop()
        }
    }

    func testPauseResume() {
        
        let unfulfilledExpectation = expectation(description: "Pause / resume")
        
        let clock = Clock()
        
        let referenceTimeline = Timeline { unfulfilledExpectation.fulfill() }
        let realLifeTimeline = Timeline()
        
        // store events in the reference timeline at one and two seconds
        let oneSecondReference = {
            XCTAssertEqual(clock.elapsed, 1, accuracy: 0.01)
        }
        
        // should happen at 3 seconds (real-life time)
        let twoSecondsReference = {
            XCTAssertEqual(clock.elapsed, 3, accuracy: 0.01)
        }
        
        referenceTimeline.insert(at: 1, performing: oneSecondReference)
        referenceTimeline.insert(at: 2, performing: twoSecondsReference)
        
        // pause the reference timeline at one second
        let oneSecondRealLife = {
            print("one second IN REAL LIFE: pausing reference timeline")
            referenceTimeline.pause()
        }
        
        let twoSecondsRealLife = {
            print("two seconds in REAL LIFE: resuming reference timeline")
            referenceTimeline.resume()
        }
        
        realLifeTimeline.insert(at: 1, performing: oneSecondRealLife)
        realLifeTimeline.insert(at: 2, performing: twoSecondsRealLife)
        
        clock.start()
        referenceTimeline.start()
        realLifeTimeline.start()

        waitForExpectations(timeout: 10) { _ in
            referenceTimeline.stop()
            realLifeTimeline.stop()
        }
    }
    
    func assertAccuracyWithRepeatedPulse(interval: Seconds, for duration: Seconds) {
     
        guard duration > 0 else {
            return
        }
        
        let unfulfilledExpectation = expectation(description: "Test accuracy of Timer")
        
        let range = stride(from: Seconds(0), to: duration, by: interval).map { $0 }
        
        // Data
        var globalErrors: [Double] = []
        var localErrors: [Double] = []
        
        // Create `Timeline` to test
        let timeline = Timeline()
        
        let start: UInt64 = DispatchTime.now().uptimeNanoseconds
        var last: UInt64 = DispatchTime.now().uptimeNanoseconds
        
        for (i, offset) in range.enumerated() {
            
            let operation = {
                
                // For now, don't test an event on first hit, as the offset should be 0
                if offset > 0 {
                    
                    let current = DispatchTime.now().uptimeNanoseconds
                    
                    let actualTotalOffset = Seconds(current - start) / 1_000_000_000
                    let expectedTotalOffset = range[i]
                    
                    let actualLocalOffset = Seconds(current - last) / 1_000_000_000
                    let expectedLocalOffset: Seconds = interval
                    
                    let globalError = abs(actualTotalOffset - expectedTotalOffset)
                    let localError = abs(expectedLocalOffset - actualLocalOffset)

                    globalErrors.append(globalError)
                    localErrors.append(localError)
                    
                    print("local error: \(localError)")
                    print("global error: \(globalError)")
                    
                    last = current
                }
            }
            
            timeline.insert(at: offset, performing: operation)
        }
        
        // Finish up 1 second after done
        let assertion = {
            
            let maxGlobalError = globalErrors.max()!
            let averageGlobalError = globalErrors.mean!
            
            let maxLocalError = localErrors.max()!
            let averageLocalError = localErrors.mean!
            
            XCTAssertLessThan(maxGlobalError, 0.015)
            XCTAssertLessThan(averageGlobalError, 0.015)
            
            XCTAssertLessThan(maxLocalError, 0.015)
            XCTAssertLessThan(averageLocalError, 0.015)
            
            print("max global error: \(maxGlobalError); average global error: \(averageGlobalError)")
            print("max local error: \(maxLocalError); average local error: \(averageLocalError)")
            
            // Fulfill expecation
            unfulfilledExpectation.fulfill()
            
            timeline.stop()
        }
        
        timeline.insert(at: range.last!, performing: assertion)
        
        // Start the timeline
        timeline.start()
        
        // Ensure that test lasts for enough time
        waitForExpectations(timeout: duration + 2) { _ in }
    }
    
    func assertAccuracyWithPulseEverySecond(for duration: Seconds) {
        assertAccuracyWithRepeatedPulse(interval: 1, for: duration)
    }

    // MARK: - Short Tests
    
    func testAccuracyWithFastPulseForOneSecond() {
        assertAccuracyWithRepeatedPulse(interval: 0.1, for: 1)
    }
    
    func testAccuracyWithIrregularFastPulseForOneSecond() {
        assertAccuracyWithRepeatedPulse(interval: 0.1618, for: 1)
    }
    
    // MARK: - Medium Tests
    
    func testAccuracyWithFastPulseForFiveSeconds() {
        assertAccuracyWithRepeatedPulse(interval: 0.1, for: 5)
    }
    
    func testAccuracyWithIrregularFastPulseForFiveSeconds() {
        assertAccuracyWithRepeatedPulse(interval: 0.5, for: 5)
    }
    
    // MARK: - Long Tests

    func testAccuracyWithPulseEverySecondForAMinute() {
        assertAccuracyWithPulseEverySecond(for: 60)
    }
    
    func testAccuracyWithPulseEveryThirdOfASecondForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 1/3, for: 60)
    }
    
    func testAccuracyWithPulseEveryTenthOfASecondForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 1/10, for: 60)
    }
    
    func testAccuracyWithPulseAbritraryIntervalForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 0.123456, for: 60)
    }
    
    func testAccuracyOfLongIntervalForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 12.3456, for: 60)
    }

    func testAccuracyWithPulseEverySecondFor30Minutes() {
        assertAccuracyWithPulseEverySecond(for: 60)
    }
}
