public final class Event: @unchecked Sendable {
    public init() {}

    public var signaled: Bool { lock.lock { signaledInternal } }
    
    public func wait() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !signaledInternal else { return }
        
        conditionVariable.wait(lock: lock)
    }

    public func signal(reset: Bool = true) {
        lock.lock {
            signaledInternal = !reset
            conditionVariable.notifyAll()
        }
    }

    public func reset() {
        lock.lock {
            signaledInternal = false
        }
    }

    private let lock = Lock()
    private var signaledInternal = false
    private let conditionVariable = ConditionVariable()
}
