public final class CountdownLatch: @unchecked Sendable {
    public init(value: Int) {
        self.value = value
    }
    
    public func wait() {
        lock.lock()
        defer { lock.unlock() }
        
        guard value > 0 else { return }
        
        condition.wait(lock: lock) {
            value == 0
        }
    }
    
    public func signal() {
        let value = lock.lock {
            self.value -= 1
            return self.value
        }
        
        if value == 0 {
            condition.notifyAll()
        }
    }
    
    private var value: Int
    private var lock = Lock()
    private var condition = ConditionVariable()
}
