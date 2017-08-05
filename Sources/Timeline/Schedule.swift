//
//  Schedule.swift
//  Timeline
//
//  Created by James Bean on 5/4/17.
//
//

import Foundation
import StructureWrapping
import DataStructures
import Time

/// Schedule of atomic and looping actions.
public class Schedule {

    /// Next set of events with the offset in scheduled-time in Seconds
    public var next: (offset: Seconds, actions: [Action])? {
        guard !nextSchedules.isEmpty else { return nil }
        let offset = nextSchedules.first!.next!.offset
        let actions = nextSchedules.flatMap { schedule in schedule.next!.actions }
        return (offset, actions)
    }

    /// The schedules which contain the soonest actions.
    private var nextSchedules: [SubSchedule] {
        return [atomic,looping]
            .filter { $0.next != nil }
            .extrema(property: { $0.next!.offset }, areInIncreasingOrder: <)
    }

    // Storage of atomic events to be performed, stored by offset in scheduled-time in Seconds.
    internal var atomic: SubSchedule

    // Storage of looping events to be performed, stored by offset in scheduled-time in Seconds.
    internal var looping: SubSchedule.Looping

    /// Creates an empty Schedule.
    public init() {
        self.atomic = SubSchedule()
        self.looping = SubSchedule.Looping()
    }

    // MARK: Building a Schedule

    /// Schedule the given `operation` to be performed at the given `offset`, tagged with the given
    /// `identifiers`.
    public func insert(
        at offset: Seconds,
        identifiers: [String] = [],
        performing operation: @escaping Action.Operation
    )
    {
        let action = Action(identifiers: identifiers, performing: operation)
        insert(action, at: offset)
    }

    /// Insert the given `action` to be performed atomically the the given `offset`.
    private func insert(_ action: Action, at offset: Seconds) {
        atomic.insert(action, at: offset)
    }

    /// Schedule the given `operation` to loop every `interval`, starting at the given `offset`.
    public func loop(
        every interval: Seconds,
        startingAt offset: Seconds = 0,
        identifiers: [String] = [],
        performing operation: @escaping Action.Operation
    )
    {
        loop(
            Action.Looping(every: interval, identifiers: identifiers, performing: operation),
            startingAt: offset
        )
    }

    /// Schedule the given `action` to loop, starting at the given `offset`.
    private func loop(_ action: Action.Looping, startingAt offset: Seconds) {
        looping.insert(action, at: offset)
    }

    /// Inserts the contents of the given `schedule`.
    public func insert(contentsOf schedule: Schedule) {
        atomic.insert(contentsOf: schedule.atomic)
        looping.insert(contentsOf: schedule.looping)
    }

    // Modifying a Schedule

    /// Remove all of the actions that match the given `identifiers`.
    public func removeAll(identifiers: Set<String> = []) {
        looping.removeAll(identifiers: identifiers)
        atomic.removeAll(identifiers: identifiers)
    }

    // Navigation

    /// Advance each of the sub schedules as necessary.
    public func advance() {
        nextSchedules.forEach { $0.advance() }
    }
}

extension Schedule: CustomStringConvertible {

    public var description: String {
        return "\(atomic), \(looping)"
    }
}

extension Sequence where Element: Action {
    func removing(identifiers: Set<String>) -> [Element]? {
        let filtered = filter { action in action.hasAnyIdentifiers(identifiers) }
        return filtered.isEmpty ? nil : filtered
    }
}
