//
//  Action.swift
//  Timeline
//
//  Created by James Bean on 8/3/17.
//

import Structure
import DataStructures
import Time

extension Timeline {

    public class Action {

        public typealias Operation = () -> Void

        public final class Atomic: Action { }

        public final class Looping: Action {

            let interval: Seconds

            init(
                every interval: Seconds,
                identifiers: [String] = [],
                performing operation: @escaping Operation
            )
            {
                self.interval = interval
                super.init(identifiers: identifiers, performing: operation)
            }
        }

        var identifiers: [String]
        let operation: Operation

        init(identifiers: [String] = [], performing operation: @escaping Operation) {
            self.identifiers = identifiers
            self.operation = operation
        }

        func addIdentifier(_ identifier: String) {
            identifiers.append(identifier)
        }

        func hasIdentifier(_ identifier: String) -> Bool {
            return identifiers.contains(identifier)
        }

        func hasAnyIdentifiers <S> (_ identifiers: S) -> Bool where S: Sequence, S.Element == String {
            return identifiers.any(satisfy: hasIdentifier)
        }
    }
}

public func perform(_ action: Timeline.Action) {
    action.operation()
}
