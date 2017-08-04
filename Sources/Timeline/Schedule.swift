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

public class Schedule {

    private var nextSchedules: [SubSchedule] {
        return [atomic,looping]
            .filter { $0.next != nil }
            .extrema(property: { $0.next!.offset }, areInIncreasingOrder: <)
    }

    public var next: (offset: Seconds, actions: [Action])? {
        guard !nextSchedules.isEmpty else { return nil }
        let offset = nextSchedules.first!.next!.offset
        let actions = nextSchedules.flatMap { schedule in schedule.next!.actions }
        return (offset, actions)
    }

    // Storage of atomic events to be performed, stored by offset in Seconds
    internal var atomic: SubSchedule

    // Storage of looping events to be performed, stored by offset in Seconds
    internal var looping: SubSchedule.Looping

    /// Creates an empty Schedule.
    public init() {
        self.atomic = SubSchedule()
        self.looping = SubSchedule.Looping()
    }

    // MARK: Building a Schedule

    public func schedule(
        at offset: Seconds,
        identifiers: [String] = [],
        performing operation: @escaping Action.Operation
    )
    {
        let action = Action(identifiers: identifiers, performing: operation)
        schedule(action, at: offset)
    }

    public func schedule(_ action: Action, at offset: Seconds) {
        atomic.add(action, at: offset)
    }

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

    public func loop(_ action: Action.Looping, startingAt offset: Seconds) {
        looping.add(action, at: offset)
    }

    public func insert(contentsOf schedule: Schedule) {
        atomic.schedule(contentsOf: schedule.atomic)
        looping.schedule(contentsOf: schedule.looping)
    }

    // Modifying a Schedule

    public func removeAll(identifiers: Set<String> = []) {
        looping.removeAll(identifiers: identifiers)
        atomic.removeAll(identifiers: identifiers)
    }

    // Navigation

    public func advance() {
        nextSchedules.forEach { $0.advance() }
    }
}

extension Timeline {

    /// Schedules the given `operation` to be performed at the given `offset` in `Seconds`.
    public func schedule(at offset: Seconds, performing operation: @escaping Action.Operation) {
        schedule.schedule(at: offset, identifiers: [identifier], performing: operation)
    }

    /// Schedules the given looping `operation`, to be performed every `interval`, offset by the
    /// given `offset`.
    public func loop(
        every interval: Seconds,
        startingAt offset: Seconds = 0,
        operation: @escaping Action.Operation
    )
    {
        schedule.loop(
            every: interval,
            startingAt: offset,
            identifiers: [identifier],
            performing: operation
        )
    }

    public func removeAll(identifiers: Set<String> = []) {
        schedule.removeAll(identifiers: identifiers)
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
