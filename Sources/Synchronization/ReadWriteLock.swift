import Darwin

/**
 `ReadWriteLock` enables thread-safe execution of code.
 Blocks passed to `read` and `write` will be synchronized according to the following rules:
  • Multiple `read` blocks are allowed to execute concurrently,
  • `write` blocks are given exclusive access (neither reads nor other writes can execute concurrently with a write).
 Since thread safety is typically about protecting *resources*, rather than *code*, `ReadWriteLock` should rarely be used directly.
 Instead, `Synchronized` satisfies most use cases for ensuring thread-safe access to resources.
 */
public final class ReadWriteLock: @unchecked Sendable {
    public init() {
        var attr = pthread_rwlockattr_t()
        defer { pthread_rwlockattr_destroy(&attr) }

        pthread_rwlockattr_init(&attr)

        pthread_rwlock_init(&mutex, &attr)
    }
    
    deinit {
        pthread_rwlock_destroy(&mutex)
    }

    public func lock() {
        pthread_rwlock_rdlock(&mutex)
    }
    
    public func exclusiveLock() {
        pthread_rwlock_wrlock(&mutex)
    }
    
    public func unlock() {
        pthread_rwlock_unlock(&mutex)
    }

    private var mutex = pthread_rwlock_t()
}

public extension ReadWriteLock {
    /// Perform a "read" type block of work.  The submitted block can execute concurrently with other submitted "read" blocks, but not with submitted "write" blocks
    ///
    /// - Parameter work: The block of work to submit
    /// - Returns: The value, if any, that is returned by the block of work
    /// - Throws: The error, if any, that is thrown by the block of work
    func read<R>(_ work: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        
        return try work()
    }

    /// Perform a "write" type block of work.  The submitted block will execute exclusively, blocking all other submitted blocks (both "read" and "write") until it completes.
    ///
    /// - Parameter work: The block of work to submit
    /// - Returns: The value, if any, that is returned by the block of work
    /// - Throws: The error, if any, that is thrown by the block of work
    func write<R>(_ work: () throws -> R) rethrows -> R {
        exclusiveLock()
        defer { unlock() }
        
        return try work()
    }
}

public struct SharedLock: Lockable {
    let _lock: ReadWriteLock
    
    public func lock() {
        _lock.lock()
    }
    
    public func unlock() {
        _lock.unlock()
    }
}

public struct ExclusiveLock: Lockable {
    let _lock: ReadWriteLock
    
    public func lock() {
        _lock.exclusiveLock()
    }
    
    public func unlock() {
        _lock.unlock()
    }
}

public extension ReadWriteLock {
    var sharedLockable: SharedLock {
        SharedLock(_lock: self)
    }
    
    var exclusiveLockable: ExclusiveLock {
        ExclusiveLock(_lock: self)
    }
}
