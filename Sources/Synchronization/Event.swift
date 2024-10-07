import Darwin

public final class Event: @unchecked Sendable {
    public init() {}

    public var signaled: Bool { lock.lock { _signaled } }
    
    // At first it would seem like it's good enough to just maintain the `_signaled` state, and call `conditionVariable.wait` without a predicate, so that when the event is signaled, the thread will simply wake up and proceed without checking any state (it shouldn't check `_signaled` because it should resume even if the event is reset, in which case `_signaled` doesn't change, and temporarily changing `_signaled` before changing it back doesn't produce the desired behavior of ensuring all threads that wait before the signal resume but no threads that wait after the signal resume, there will be a race condition between a new thread coming in and seeing that `_signaled` is still `true` and `signal` setting it back to `false`).  However this risks spurious wakeups.  Generally condition variables don't guarantee that they won't wake up threads even when no `notify` calls were made, because the resumed threads usually need to check state anyways.  Because of this it is really a *requirement* to wait on a condition variable with a predicate.  We need to record which threads are waiting, so that each thread can check if it has been signaled.  We do this by maintaining a set of thread ids.  Maintaining a count isn't good enough because a new thread can come in to wait (incrementing the count) before the already waiting threads wake up and reacquire the lock, at which point they'll see a positive count and continue waiting.  Each thread's condition has to be unique to that thread so that *only* the threads already waiting before a call to `signal` see a "ready" condition.
    public func wait() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !_signaled else { return }
        
        var threadId: UInt64 = 0
        pthread_threadid_np(nil, &threadId);
        
        waiters.insert(threadId)
        
        conditionVariable.wait(lock: lock) {
            !waiters.contains(threadId)
        }
    }

    public func signal(reset: Bool = true) {
        lock.lock {
            _signaled = !reset
            waiters.removeAll()
        }
        
        conditionVariable.notifyAll()
    }

    public func reset() {
        lock.lock {
            _signaled = false
        }
    }

    private let lock = Lock()
    private var _signaled = false
    private var waiters = Set<UInt64>()
    private let conditionVariable = ConditionVariable()
}
