public protocol Lockable: ~Copyable, Sendable {
    func lock()
    func unlock()
}

public extension Lockable {
    func lock<R: ~Copyable, E: Error>(_ work: () throws(E) -> R) throws(E) -> R {
        lock()
        defer { unlock() }
        
        return try work()
    }
}
