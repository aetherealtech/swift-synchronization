import Darwin
import Foundation

public final class ConditionVariable: ConditionVariableProtocol, @unchecked Sendable {
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
