//
//  Timeline.swift
//  Timeline
//
//  Created by James Bean on 5/1/17.
//
//

import Foundation
import DataStructures
import Time

/// Quantization of `Seconds` values by the `rate`.
public typealias Ticks = UInt64

/// Store closures to be performed at offsets.
///
/// Playback can occur at real-time, or modified by the `playbackRate`.
///
public class Timeline {
    
    // MARK: - Nested Types
    
    /// Status of the `Timeline`.
    public enum Status {
        
        /// The `Timeline` is playing.
        case playing
        
        /// The `Timeline` is stopped.
        case stopped
        
        /// The `Timeline` is paused at the given frame offset.
        case paused(Seconds)
    }
    
    // MARK: - Instance Properties

    /// The rate at which the `Timeline` is played-back. Defaults to `1`.
    public var playbackRate: Double {
        didSet {
            guard case .playing = status else { return }
            pause()
            resume()
        }
    }
    
    /// Current state of the `Timeline`.
    public var status: Status = .stopped

    /// The current frame.
    internal var currentFrame: Ticks {
        return frames(
            scheduledDate: clock.elapsed + lastPausedDate,
            lastPausedDate: lastPausedDate,
            rate: rate,
            playbackRate: 1 // always move through time as if playback rate doesn't matter
        )
    }

    /// Scale of `Seconds` to `Frames`.
    internal var rate: Seconds
    
    /// Seconds (in schedule-time) of last pause.
    internal var lastPausedDate: Seconds = 0

    // MARK: - Mechanisms
    
    /// Schedule that store actions to be performed by their offset time.
    ///
    /// At each offset point, any number of `Actions` can be performed.
    public var schedule: Schedule
    
    /// Calls the `advance()` function rapidly.
    public var timer: Timer?

    /// Clock.
    ///
    /// Measures timing between successive shots of the `timer`, to ensure accuracy and to 
    /// prevent drifting.
    public var clock = Clock()
    
    /// Closure to be called when the `Timeline` has reached the end.
    public var completion: (() -> ())?
    
    /// Identifier of `Timeline`.
    public let identifier: String

    // MARK: - Initializers
    
    /// Creates an empty `Timeline`.
    public init(
        identifier: String = "",
        schedule: Schedule = Schedule(),
        rate: Seconds = 1/120,
        playbackRate: Double = 1,
        performingOnCompletion completion: (() -> ())? = nil
    )
    {
        self.identifier = identifier
        self.rate = rate
        self.playbackRate = playbackRate
        self.schedule = schedule
        self.completion = completion
    }

    // MARK: - Creating the Schedule

    /// Schedules the given `operation` to be performed at the given `offset` in `Seconds`.
    public func insert(at offset: Seconds, performing operation: @escaping Action.Operation) {
        schedule.insert(at: offset, identifiers: [identifier], performing: operation)
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

    /// Remove all of the actions that match the given `identifiers`.
    public func removeAll(identifiers: Set<String> = []) {
        schedule.removeAll(identifiers: identifiers)
    }
    
    // MARK: - Playback
    
    /// Starts the `Timeline`.
    public func start() {
        if case .playing = status { return }
        lastPausedDate = 0
        clock.start()
        timer = makeTimer()
        status = .playing
    }
    
    /// Stops the `Timeline` from executing, and is placed at the beginning.
    public func stop() {
        if case .stopped = status { return }
        lastPausedDate = 0
        timer?.stop()
        status = .stopped
    }
    
    /// Pauses the `Timeline`.
    public func pause() {
        if case .paused = status { return }
        lastPausedDate += clock.elapsed * playbackRate
        timer?.stop()
        status = .paused(lastPausedDate)
    }
    
    /// Resumes the `Timeline`.
    public func resume() {
        if case .playing = status { return }
        clock.start()
        timer = makeTimer()
        status = .playing
    }
    
    /// Skips the given `time` in `Seconds`.
    ///
    /// - warning: Not currently available.
    public func skip(to time: Seconds) {
        fatalError()
    }
    
    /// Creates a new `Timer`, making sure that the previous `Timer` has been killed.
    private func makeTimer() -> Timer {
        self.timer?.stop()
        let timer = Timer(interval: 1/120, performing: advance)
        timer.start()
        return timer
    }

    public var next: (Seconds, [Action])? {
        return schedule.next
    }

    /// Called rapidly by the `timer`, a check is made based on the elapsed time whether or not
    /// actions need to be executed.
    ///
    /// If so, `playbackIndex` is incremented.
    private func advance() {

        guard let (seconds, actions) = next else {
            completion?()
            stop()
            return
        }

        if currentFrame >= playbackFrames(scheduledDate: seconds) {
            actions.forEach(perform)
            schedule.advance()
        }
    }

    // FIXME: Refactor, see below
    func playbackFrames(scheduledDate: Seconds) -> Ticks {
        return frames(
            scheduledDate: scheduledDate,
            lastPausedDate: lastPausedDate,
            rate: rate,
            playbackRate: playbackRate
        )
    }
}

public func perform(_ action: Action) {
    action.operation()
}


/// Converts seconds into frames for the given rate.
//
// FIXME: Refactor, see above
internal func frames(
    scheduledDate: Seconds,
    lastPausedDate: Seconds = 0,
    rate: Seconds,
    playbackRate: Double
) -> Ticks
{
    let interval = 1 / rate
    let timeSincePlaybackRateChange = scheduledDate - lastPausedDate
    guard timeSincePlaybackRateChange > 0 else { return 0 }
    let playbackInterval = interval / playbackRate
    return Ticks(round(lastPausedDate * interval + playbackInterval * timeSincePlaybackRateChange))
}

extension Timeline: CustomStringConvertible {

    // MARK: - CustomStringConvertible
    
    /// Printed description.
    public var description: String {
        return schedule.description
    }
}
