//
//  ScheduleAdvancing.swift
//  Timeline
//
//  Created by James Bean on 8/3/17.
//

import Time

// Interface for schedules which are able to provide the next `Action` and its scheduled offset.
internal protocol ScheduleAdvancing: class {

    // The next available action.
    var next: (offset: Seconds, actions: [Action])? { get }

    // Increment the internal counter and manage internal state to proceed to the next action.
    func advance()
}
