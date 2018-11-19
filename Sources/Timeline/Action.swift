//
//  Action.swift
//  Timeline
//
//  Created by James Bean on 8/3/17.
//

import DataStructures
import Time

/// Operation to be performed, with identifiers.
public class Action {

    /// Operation to be performed by an Action
    public typealias Operation = () -> Void

    /// Action which repeats at a given interval
    public final class Looping: Action {

        /// Interval at which the action is repeated
        let interval: Seconds

        /// Creates an Action.Looping that will loop every `interval`, with the given `identifiers`.
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

    /// Creates an Action which wraps the given `operation` with the given `identifiers`.
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
        return self.identifiers.contains(where: identifiers.contains)
    }
}
