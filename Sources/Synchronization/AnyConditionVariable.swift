import Darwin
import Foundation

/// A condition variable that can be used with any `Lockable` as its mutex.  The OS provided ``ConditionVariable`` can only use the OS provided ``Lock`` as its mutex.  This type allows a condition variable to work with other types of mutexes.
public struct AnyConditionVariable<Lock: Lockable>: ConditionVariableProtocol {
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
    ) -> Bool {
        wait(
            lock: lock,
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, for: timeout) }
        )
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func wait(
        lock: Lock,
        for timeout: Duration
    ) -> Bool {
        wait(
            lock: lock,
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, for: timeout) }
        )
    }
    
    public func wait(
        lock: Lock,
        until timeout: Date
    ) -> Bool {
        wait(
            lock: lock,
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, until: timeout) }
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
            waitInternal: { cv, cvLock in cv.wait(lock: cvLock, until: timeout, tolerance: tolerance, clock: clock) }
        )
    }

    public func notifyOne() {
        cvLock.lock {}
        conditionVariable.notifyOne()
    }
    
    public func notifyAll() {
        cvLock.lock {}
        conditionVariable.notifyAll()
    }

    private let cvLock = Synchronization.Lock()
    private let conditionVariable = ConditionVariable()
    
    // Since the "real" condition variable must use a pthread lock as its mutex, the way we implement this is to use a pthread lock (the `cvLock`) with the condition variable in coordination with the `Lockable` passed in (`lock`).  The lock used by the condition variable ensures that it is not possible for one thread to check for a condition, see that it is not "ready" and call `wait`, but another thread modifies the condition, making it "ready", and then notifies the condition variable, before the other thread gets far enough into the `wait` call to actually "see" the notification.  If this were to happen the first thread would `wait` indefinitely even though the condition is "ready" because it missed the notification (it checked for readiness before the notification was sent then began waiting for a notification after the notification was sent).  This is prevented by having the condition variable work with the same mutex the threads use to protect access to the shared condition.  It expects this lock be locked when `wait` is called, and it unlocks it only after ensuring the thread is "registered" for a notification, and then it locks that lock again before "unregistering" and resuming.  As long as the threads accessing the condition do so while holding the lock, this ensures that either the first thread will register for the notification before the second thread sends the notification (in which case it receives the notification, wakes up, checks the condition and then stops waiting), or the second thread will mark the condition as "ready" before the first thread checks it (in which case the first thread will not `wait` at all).  The problem here is we want to use a `lock` the condition variable doesn't know about, and we can't ensure that the `lock` will remain locked until the condition variable has registered the thread for notifications.  The best we can do is unlock the `lock` right before calling `wait`, and lock it again immediately after `wait` returns, but this creates a space for the race condition where another thread can acquire `lock`, mark the condition as "ready" and send a notification in between our call to `lock.unlock()` and the point inside of `wait` where the notification is registered.  To prevent this we have to use a mutex the condition variable can work with to ensure that no thread can `notify` the condition variable during this time between unlocking our `lock` and the implementation of `wait` registering the notification.  So *before* unlocking `lock` we acquire `cvLock`.  This way, by the time we call `lock.unlock()`, we have already acquired `cvLock`.  So then if another thread was waiting on `lock` to update the condition to "ready" and send a notification, it can only do so *after* we acquire `cvLock`.  That second thread will then, immediately after releasing `lock`, call `notify`.  To ensure this notification is not sent before the first thread is registered for it, we need to hold the same `cvLock` before we forward the `notify` message to the real condition variable (but not during).  That ensures that if another thread has already checked the condition and decided it needs to wait, it will get all the way to the real condition variable registering the notification, after which it releases `cvLock`, before the other thread is able to `notify` the condition variable.  This prevents the race condition.  We don't have to hold the lock around the underlying `notify` call because it's safe to `notify` on a condition variable without holding the lock that protects the state.  A condition variable is "atomic enough" for this to be safe.  We just need to make sure that a thread calling `notify` can't enter the underlying `notify` function in between `lock.unlock()` and `waitInternal(...)`.  Forcing our `notify` to wait on the internal lock before calling down is enough to prevent this because in between those two calls the `cvLock` is held.
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
    
    private func wait(
        lock: Lock,
        waitInternal: (ConditionVariable, Synchronization.Lock) -> Bool
    ) -> Bool {
        cvLock.lock()
        lock.unlock()
        
        defer {
            lock.lock()
            cvLock.unlock()
        }
        
        return waitInternal(conditionVariable, cvLock)
    }
}
