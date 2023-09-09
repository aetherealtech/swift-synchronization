import Darwin
import Foundation

public final class AnyConditionVariable<Lock: Lockable>: ConditionVariableProtocol {
    public init() {}

    public func wait(
        lock: Lock
    ) {
        wait(
            lock: lock,
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock) }
        )
    }
    
    public func wait(
        lock: Lock,
        for timeout: TimeInterval
    ) {
        wait(
            lock: lock,
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, for: timeout) }
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func wait(
        lock: Lock,
        for timeout: Duration
    ) {
        wait(
            lock: lock,
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, for: timeout) }
        )
    }
    
    public func wait(
        lock: Lock,
        until timeout: Date
    ) {
        wait(
            lock: lock,
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, until: timeout) }
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
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, until: timeout, tolerance: tolerance, clock: clock) }
        )
    }
    
    public func notifyOne() {
        conditionVariable.notifyOne()
    }
    
    public func notifyAll() {
        conditionVariable.notifyAll()
    }

    private let cvLock = Synchronization.Lock()
    private let conditionVariable = ConditionVariable()
    
    private func wait(
        lock: Lock,
        waitInternal: (ConditionVariable, Synchronization.Lock) -> Void
    ) {
        cvLock.lock()
        
        lock.unlock()
        
        waitInternal(conditionVariable, cvLock)
        
        lock.lock()
        
        cvLock.unlock()
    }
    
}
