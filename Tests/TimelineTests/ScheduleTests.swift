//
//  ScheduleTests.swift
//  Timeline
//
//  Created by James Bean on 5/3/17.
//
//

import XCTest
import DataStructures
import Time
@testable import Timeline

class ScheduleTests: XCTestCase {
    
    func testSchedule() {
        
        let timeline = Timeline(rate: 1/100)
        
        for offset in 0..<10 {
            timeline.schedule(at: Seconds(offset), performing: { })
        }
        
        let expectedSecondsOffsets: SortedArray<Seconds> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        XCTAssertEqual(timeline.schedule.atomic.keys, expectedSecondsOffsets)
    }

    func testIdentifier() {
        
        let timeline = Timeline(identifier: "ABC")
        timeline.schedule(at: 0, performing: { })
        
        let action = timeline.schedule.atomic.first!.1.first!
        let identifier = action.identifiers.first!
        XCTAssertEqual(identifier, "ABC")
    }

    // FIXME: Move to ScheduleTests
    func testRemoveAll() {

        let timeline = Timeline()

        for offset in 0..<5 {
            timeline.schedule(at: Seconds(offset)) { }
        }

        XCTAssertEqual(timeline.schedule.atomic.count, 5)
        timeline.removeAll()
        XCTAssertEqual(timeline.schedule.atomic.count, 0)
    }
}
