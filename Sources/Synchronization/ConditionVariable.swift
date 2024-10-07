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
    ) -> Bool {
        wait(
            lock: lock,
            until: .init().addingTimeInterval(timeout)
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func wait(
        lock: Lock,
        for timeout: Duration
    ) -> Bool {
        var ts = timespec(timeout)
        
        var tsNow = timespec()
        clock_gettime(CLOCK_REALTIME, &tsNow);
        
        ts.tv_sec += tsNow.tv_sec
        ts.tv_nsec += tsNow.tv_nsec
        
        return wait(
            lock: lock,
            timespec: ts
        )
    }
    
    public func wait(
        lock: Lock,
        until timeout: Date
    ) -> Bool {
        let absTime = timeout.timeIntervalSince1970
        
        let seconds = Int(absTime)
        let nanoseconds = Int((absTime - TimeInterval(seconds)) * 1e9)
        
        return wait(
            lock: lock,
            timespec: .init(tv_sec: seconds, tv_nsec: nanoseconds)
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func wait<C: Clock>(
        lock: Lock,
        until timeout: C.Instant,
        tolerance: C.Duration?,
        clock: C
    ) -> Bool where C.Duration == Duration {
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
    ) -> Bool {
        withUnsafePointer(to: timespec) { timespec in
            pthread_cond_timedwait(&conditionVariable, &lock.mutex, timespec) != ETIMEDOUT
        }
    }
}
