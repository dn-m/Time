//
//  SubSchedule.swift
//  Timeline
//
//  Created by James Bean on 8/3/17.
//

import DataStructures
import Time

internal class SubSchedule {

    internal class Looping: SubSchedule {

        internal override var next: (offset: Seconds, actions: [Action])? {
            return base.first
        }

        internal override func insert(_ action: Action, at offset: Seconds) {
            assert(action is Action.Looping)
            super.insert(action, at: offset)
        }

        internal override func advance() {
            defer { index += 1 }
            guard let (offset, actions) = next else { return }
            bump(actions, from: offset)
        }

        private func bump(_ actions: [Action], from offset: Seconds) {
            (actions as! [Action.Looping])
                .map { action in (offset + action.interval, action) }
                .forEach { offset, action in base.safelyAppend(action, toArrayWith: offset) }
            base[offset] = nil
        }
    }

    /// Next sets of actions with their offset in scheduled-time
    internal var next: (offset: Seconds, actions: [Action])? {
        guard index < base.count else { return nil }
        return base[index]
    }

    /// Storage of actions by their offset in scheduled-time
    internal var base: SortedDictionary<Seconds, [Action]>

    /// Index of current set of actions
    private var index: Int

    /// Creates an empty SubSchedule
    internal init() {
        self.base = [:]
        self.index = 0
    }

    /// Move to the next set of actions
    internal func advance() {
        index += 1
    }

    /// Add the given `action` at the given `offset`.
    internal func insert(_ action: Action, at offset: Seconds) {
        base.safelyAppend(action, toArrayWith: offset)
    }

    /// Insert the contents of the given `schedule` into this one.
    internal func insert(contentsOf schedule: SubSchedule) {
        base.insert(contentsOf: schedule.base)
    }

    /// Remove all of the actions with the given `identifiers`.
    internal func removeAll(identifiers: Set<String> = []) {
        for (key, actions) in base {
            base[key] = actions.removing(identifiers: identifiers)
        }
    }
}
