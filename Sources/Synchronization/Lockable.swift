public protocol Lockable: Sendable {
    func lock()
    func unlock()
}

public extension Lockable {
    func lock<R>(_ work: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        
        return try work()
    }
}
