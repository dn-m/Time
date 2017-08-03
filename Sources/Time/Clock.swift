//
//  Clock.swift
//  Time
//
//  Created by James Bean on 5/4/17.
//
//

import Foundation

/// Measures time.
public class Clock {

    /// - returns: Current offset in `Seconds`.
    private static var now: Seconds {
        return Date().timeIntervalSince1970
    }

    private var startTime: Seconds

    /// - returns: Time elapsed since `start()`.
    public var elapsed: Seconds {
        return Clock.now - startTime
    }

    /// Creates a `Clock` ready to measure time.
    public init() {
        self.startTime = Clock.now
    }

    /// Stores the current time for measurement.
    public func start() {
        startTime = Clock.now
    }
}
