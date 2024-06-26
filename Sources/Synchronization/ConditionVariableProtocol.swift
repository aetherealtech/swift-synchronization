import Foundation

public protocol ConditionVariableProtocol: Sendable {
    associatedtype Lock: Lockable
    
    func wait(
        lock: Lock
    )
    
    func wait(
        lock: Lock,
        for timeout: TimeInterval
    )
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func wait(
        lock: Lock,
        for timeout: Duration
    )
    
    func wait(
        lock: Lock,
        until timeout: Date
    )
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func wait<C: Clock>(
        lock: Lock,
        until timeout: C.Instant,
        tolerance: C.Duration?,
        clock: C
    ) where C.Duration == Duration
    
    func notifyOne()
    func notifyAll()
}

public extension ConditionVariableProtocol {
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func wait<C: Clock>(
        lock: Lock,
        until timeout: C.Instant,
        clock: C
    ) where C.Duration == Duration {
        wait(
            lock: lock,
            until: timeout,
            tolerance: nil,
            clock: clock
        )
    }
    
    func wait(
        lock: Lock,
        _ condition: () throws -> Bool
    ) rethrows {
        try wait(
            lock: lock,
            wait: self.wait,
            condition
        )
    }
    
    func wait(
        lock: Lock,
        for timeout: TimeInterval,
        _ condition: () throws -> Bool
    ) rethrows {
        try wait(
            lock: lock,
            wait: { lock in wait(lock: lock, for: timeout) },
            condition
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func wait(
        lock: Lock,
        for timeout: Duration,
        _ condition: () throws -> Bool
    ) rethrows {
        try wait(
            lock: lock,
            wait: { lock in wait(lock: lock, for: timeout) },
            condition
        )
    }
    
    func wait(
        lock: Lock,
        until timeout: Date,
        _ condition: () throws -> Bool
    ) rethrows {
        try wait(
            lock: lock,
            wait: { lock in wait(lock: lock, until: timeout) },
            condition
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func wait<C: Clock>(
        lock: Lock,
        until timeout: C.Instant,
        tolerance: C.Duration? = nil,
        clock: C,
        _ condition: () throws -> Bool
    ) rethrows where C.Duration == Duration {
        try wait(
            lock: lock,
            wait: { lock in wait(lock: lock, until: timeout, tolerance: tolerance, clock: clock) },
            condition
        )
    }
    
    private func wait(
        lock: Lock,
        wait: (Lock) -> Void,
        _ condition: () throws -> Bool
    ) rethrows {
        while try !condition() {
            wait(lock)
        }
    }
}
