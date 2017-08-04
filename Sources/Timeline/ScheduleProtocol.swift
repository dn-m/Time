//
//  ScheduleProtocol.swift
//  Timeline
//
//  Created by James Bean on 8/3/17.
//

import Time

// Interface for schedules composed of building and advancing properties.
internal protocol ScheduleProtocol: class, ScheduleAdvancing, ScheduleBuiling { }

extension ScheduleProtocol {

    /// Casts the specialized form of the action (e.g., `Atomic` / `Looping`) up to their shared
    /// superclass, while preserving the offset time.
    public var next: (offset: Seconds, actions: [Action])? {
        return specializedNext.flatMap { (offset, action) in (offset, action as [Action]) }
    }
}
