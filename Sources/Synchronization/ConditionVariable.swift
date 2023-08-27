import Darwin
import Foundation

public final class ConditionVariable {
    public init() {
        var attr = pthread_condattr_t()
        defer { pthread_condattr_destroy(&attr) }
        
        pthread_condattr_init(&attr)
        
        pthread_cond_init(&conditionVariable, &attr)
    }
    
    deinit {
        pthread_cond_destroy(&conditionVariable)
    }
    
    public func wait(
        lock: Lock
    ) {
        pthread_cond_wait(&conditionVariable, &lock.mutex)
    }
    
    public func wait(
        lock: Lock,
        for timeout: TimeInterval
    ) {
        let seconds = Int(timeout)
        let nanoseconds = Int((timeout - TimeInterval(seconds)) * 1e9)
        
        wait(
            lock: lock,
            timespec: .init(tv_sec: seconds, tv_nsec: nanoseconds)
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func wait(
        lock: Lock,
        for timeout: Duration
    ) {
        wait(
            lock: lock,
            timespec: .init(timeout)
        )
    }
    
    public func wait(
        lock: Lock,
        until timeout: Date
    ) {
        wait(
            lock: lock,
            for: timeout.timeIntervalSinceNow
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func wait<C: Clock>(
        lock: Lock,
        until timeout: C.Instant,
        tolerance: C.Duration? = nil,
        clock: C
    ) where C.Duration == Duration {
        wait(
            lock: lock,
            for: timeout.duration(to: clock.now)
        )
    }
    
    public func notifyOne() {
        pthread_cond_signal(&conditionVariable)
    }
    
    public func notifyAll() {
        pthread_cond_broadcast(&conditionVariable)
    }

    private var conditionVariable = pthread_cond_t()
    
    private func wait(
        lock: Lock,
        timespec: timespec
    ) {
        var timespec = timespec
        pthread_cond_timedwait(&conditionVariable, &lock.mutex, &timespec)
    }
}

public extension ConditionVariable {
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
