//
//  Timeline.Schedule.swift
//  Timeline
//
//  Created by James Bean on 5/4/17.
//
//

import Foundation
import StructureWrapping
import DataStructures
import Time

private protocol ScheduleBuiling: class {
    typealias Base = SortedDictionary<Seconds, [ActionType]>
    associatedtype ActionType: Timeline.Action
    var base: Base { get set }
    var specializedNext: (offset: Seconds, actions: [ActionType])? { get }
}

private protocol ScheduleAdvancing: class {
    var next: (offset: Seconds, actions: [Timeline.Action])? { get }
    func advance()
}

private protocol ScheduleProtocol: class, ScheduleAdvancing, ScheduleBuiling { }

extension ScheduleProtocol {

    public var next: (offset: Seconds, actions: [Timeline.Action])? {
        return specializedNext.flatMap { (offset, action) in (offset, action as [Timeline.Action]) }
    }
}

extension ScheduleBuiling {

    public func schedule(_ action: ActionType, at offset: Seconds) {
        base.safelyAppend(action, toArrayWith: offset)
    }

    public func schedule(contentsOf schedule: Self) {
        base.insert(contentsOf: schedule.base)
    }

    public func removeAll(identifiers: Set<String> = []) {
        for (key, actions) in base {
            base[key] = actions.removing(identifiers: identifiers)
        }
    }
}

public class AtomicActionSchedule: ScheduleProtocol {

    public var specializedNext: (offset: Seconds, actions: [Timeline.Action.Atomic])? {
        guard index < base.count else { return nil }
        return base[index]
    }

    public var base: SortedDictionary<Seconds, [Timeline.Action.Atomic]>
    public private(set) var index: Int

    public init() {
        base = [:]
        index = 0
    }

    public func advance() {
        index += 1
    }
}

public class LoopingActionSchedule: ScheduleProtocol {

    public var specializedNext: (offset: Seconds, actions: [Timeline.Action.Looping])? {
        return base.first
    }

    public var base: SortedDictionary<Seconds, [Timeline.Action.Looping]>
    public private(set) var index: Int

    public init() {
        base = [:]
        index = 0
    }

    // MARK: Navigation

    public func advance() {
        defer { index += 1 }
        guard let (offset, actions) = specializedNext else { return }
        bump(actions, from: offset)
    }

    private func bump(_ actions: [Timeline.Action.Looping], from offset: Seconds) {
        actions
            .map { action in (offset + action.interval, action) }
            .forEach { offset, action in base.safelyAppend(action, toArrayWith: offset) }
        base[offset] = nil
    }
}

extension Timeline {

    public struct Schedule {

        private var nextSchedules: [ScheduleAdvancing] {
            let advanceable: [ScheduleAdvancing] = [atomic,looping]
            return advanceable
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
        public var atomic: AtomicActionSchedule

        // Storage of looping events to be performed, stored by offset in Seconds
        public var looping: LoopingActionSchedule

        /// Creates an empty Schedule.
        public init() {
            self.atomic = AtomicActionSchedule()
            self.looping = LoopingActionSchedule()
        }

        // MARK: Building a Schedule

        public mutating func schedule(
            at offset: Seconds,
            identifiers: [String] = [],
            performing operation: @escaping Action.Operation
        )
        {
            let action = Action.Atomic(identifiers: identifiers, performing: operation)
            schedule(action, at: offset)
        }

        public mutating func schedule(_ action: Action.Atomic, at offset: Seconds) {
            atomic.schedule(action, at: offset)
        }

        public mutating func loop(
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

        public mutating func loop(_ action: Action.Looping, startingAt offset: Seconds) {
            looping.schedule(action, at: offset)
        }

        public mutating func insert(contentsOf schedule: Schedule) {
            atomic.schedule(contentsOf: schedule.atomic)
            looping.schedule(contentsOf: schedule.looping)
        }

        // Modifying a Schedule

        public mutating func removeAll(identifiers: Set<String> = []) {
            looping.removeAll(identifiers: identifiers)
            atomic.removeAll(identifiers: identifiers)
        }

        // Navigation

        public func advance() {
            nextSchedules.forEach { $0.advance() }
        }
    }

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

extension Timeline.Schedule: CustomStringConvertible {

    public var description: String {
        return "\(atomic), \(looping)"
    }
}

extension Sequence where Element: Timeline.Action {
    func removing(identifiers: Set<String>) -> [Element]? {
        let filtered = filter { action in action.hasAnyIdentifiers(identifiers) }
        return filtered.isEmpty ? nil : filtered
    }
}
