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

        internal override func add(_ action: Action, at offset: Seconds) {
            assert(action is Action.Looping)
            super.add(action, at: offset)
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

    internal var next: (offset: Seconds, actions: [Action])? {
        guard index < base.count else { return nil }
        return base[index]
    }

    internal var base: SortedDictionary<Seconds, [Action]>
    private var index: Int

    internal init() {
        self.base = [:]
        self.index = 0
    }

    internal func advance() {
        index += 1
    }

    internal func add(_ action: Action, at offset: Seconds) {
        base.safelyAppend(action, toArrayWith: offset)
    }

    internal func schedule(contentsOf schedule: SubSchedule) {
        base.insert(contentsOf: schedule.base)
    }

    internal func removeAll(identifiers: Set<String> = []) {
        for (key, actions) in base {
            base[key] = actions.removing(identifiers: identifiers)
        }
    }
}
