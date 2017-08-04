//
//  ScheduleBuilding.swift
//  Timeline
//
//  Created by James Bean on 8/3/17.
//

import DataStructures
import Time

// Interface for Schedules which can be built progressively, holding a specific subclass of Action.
internal protocol ScheduleBuiling: class {

    // Type of the underlying storage for a schedule.
    typealias Base = SortedDictionary<Seconds, [ActionType]>

    // The Action subclass around which this schedule is defined.
    associatedtype ActionType: Action

    // Underlying storage for a schedule.
    var base: Base { get set }

    // The next available action in its specialized type
    var specializedNext: (offset: Seconds, actions: [ActionType])? { get }
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
