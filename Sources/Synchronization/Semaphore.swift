public final class Semaphore: @unchecked Sendable {
    public init(value: Int) {
        self.value = value
    }
    
    public func wait() {
        lock.lock()
        defer { lock.unlock() }
        
        condition.wait(lock: lock) {
            value > 0
        }
        
        value -= 1
    }
    
    public func signal() {
        lock.lock { value += 1 }
        
        condition.notifyOne()
    }
    
    private var value: Int
    private var lock = Lock()
    private var condition = ConditionVariable()
}

public extension Semaphore {
    func acquire<R>(_ work: () throws -> R) rethrows -> R {
        wait()
        defer { signal() }
                
        return try work()
    }
}
