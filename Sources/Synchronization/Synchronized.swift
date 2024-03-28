/**
 `Synchronized<T>` is a thread-safe T.  Access is protected by a `ReadWriteLock`.
 Non-mutating operations can be performed concurrently from multiple threads, but mutating operations acquire exclusive access and block all other operations (both mutating and non-mutating)
 */
@propertyWrapper
@dynamicMemberLookup
public final class Synchronized<T>: @unchecked Sendable {
    public init(wrappedValue: T) {
        _value = wrappedValue
    }

    public var projectedValue: Synchronized { self }
    
    /// Access the value for reading or writing.  Reads can be performed concurrently, but writes acquire exclusive access
    public var wrappedValue: T {
        get { lock.read { _value } }
        set { lock.write { _value = newValue } }
    }

    /// Acquire the value to be read for a block of work.
    ///
    /// - Parameter work: A block of work that takes the current (immutable) value as a parameter and optionally returns a value
    /// - Returns: The value, if any, that is returned by the block of work
    /// - Throws: The error, if any, that is thrown by the block of work
    public func read<R>(_ work: (T) throws -> R) rethrows -> R {
        try lock.read { try work(_value) }
    }

    /// Acquire the value to be written to by a block of work.
    ///
    /// - Parameter work: A block of work that takes the current (mutable) value as a parameter and optionally returns a value
    /// - Returns: The value, if any, that is returned by the block of work
    /// - Throws: The error, if any, that is thrown by the block of work
    public func write<R>(_ work: (inout T) throws -> R) rethrows -> R {
        try lock.write { try work(&_value) }
    }

    public func wait(
        _ conditionVariable: AnyConditionVariable<SharedLock>,
        until condition: (T) -> Bool
    ) {
        let cvLock = lock.sharedLockable
        
        cvLock.lock()
        defer { cvLock.unlock() }
        
        conditionVariable.wait(lock: cvLock) {
            condition(_value)
        }
    }
    
    private var _value: T
    private let lock = ReadWriteLock()
}

public extension Synchronized {
    subscript<Member>(dynamicMember keyPath: KeyPath<T, Member>) -> Member {
        _read {
            lock.lock()
            defer { lock.unlock() }
            yield _value[keyPath: keyPath]
        }
    }

    subscript<Member>(dynamicMember keyPath: WritableKeyPath<T, Member>) -> Member {
        _read {
            lock.lock()
            defer { lock.unlock() }
            yield _value[keyPath: keyPath]
        }
        _modify {
            lock.exclusiveLock()
            defer { lock.unlock() }
            yield &_value[keyPath: keyPath] // Yielding is important here because it avoids in-out behavior (locking the value to perform a read, unlocking, mutating the value, then locking again to write the mutated value back), which isn't an atomic operation.  By yielding the value directly, mutation occurs "in place", *before* the `defer` block runs, so that it is entirely contained in a single atomic operation.
        }
    }

    /// Update the current value and return the original value before the update in a single operation.
    /// This ensures that no other mutations of the value can occur between obtaining the current value and updating it
    ///
    /// - Parameter work: A block of work that takes the current (mutable) value as a parameter to update it
    /// - Returns: The original value before the update was performed
    /// - Throws: The error, if any, that is thrown by the block of work
    func getAndSet(_ work: (inout T) throws -> Void) rethrows -> T {
        return try write { value in
            let oldValue = value
            try work(&value)
            return oldValue
        }
    }
    
    func swap(_ otherValue: inout T) {
        otherValue = getAndSet { value in
            value = otherValue
        }
    }
    
    func swap(_ otherValue: T) -> T {
        getAndSet { value in
            value = otherValue
        }
    }
}
