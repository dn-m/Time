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

// atomic action schedule
// next: (Offset, Action.Atomic)?
// just give sorted dictionary

// looping action schedule
// bump(action) // re-stores action at current time + interval
// next:

extension Timeline {

    public struct Schedule {

        // Storage of atomic events to be performed, stored by offset in Seconds
        public var atomic: SortedDictionary<Seconds, [Action.Atomic]>

        // Storage of looping events to be performed, stored by offset in Seconds
        //
        // FIXME: Probably doesnt need to be a SortedDictionary
        // FIXME: Consider creating a LoopingActionSequence
        public var looping: SortedDictionary<Seconds, [Action.Looping]>

        /// Creates an empty Schedule.
        public init() {
            self.atomic = [:]
            self.looping = [:]
        }

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
            atomic.safelyAppend(action, toArrayWith: offset)
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
            looping.safelyAppend(action, toArrayWith: offset)
        }

        public mutating func insert(contentsOf schedule: Schedule) {
            atomic.insert(contentsOf: schedule.atomic)
            looping.insert(contentsOf: schedule.looping)
        }

        public mutating func removeAll(identifiers: Set<String> = []) {
            if identifiers.isEmpty {
                atomic = [:]
                looping = [:]
                return
            }
            removeAllAtomic(identifiers: identifiers)
            removeAllLooping(identifiers: identifiers)
        }

        public mutating func removeAllAtomic(identifiers: Set<String> = []) {
            for (key, actions) in atomic {
                atomic[key] = actions.removing(identifiers: identifiers)
            }
        }

        public mutating func removeAllLooping(identifiers: Set<String> = []) {
            for (key, actions) in looping {
                looping[key] = actions.removing(identifiers: identifiers)
            }
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

//    
//    public func add(_ timelines: Timeline...) {
//        timelines.forEach(add)
//    }
//    
//    /// Removes all of the `Actions` from the `Timeline` with the given identifiers
//    ///
//    /// - TODO: Refactor to `Schedule` struct
//    public func removeAll(identifiers: [String] = []) {
//        
//        // If no identifiers are provided, clear schedule entirely
//        guard !identifiers.isEmpty else {
//            schedule = [:]
//            return
//        }
//        
//        // Otherwise, remove the actions with matching the given identifiers
//        for (offset, actions) in schedule {
//            
//            // Remove the actions with identifiers that match those requested for removal
//            let filtered = actions.filter { action in
//                !Set(identifiers).intersection(action.identifierPath).isEmpty
//            }
//            
//            // If no actions are left in an array, remove value at given offset
//            schedule[offset] = !filtered.isEmpty ? filtered : nil
//        }
//    }
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
