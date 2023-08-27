import Darwin

public final class Lock: Lockable {
    public init() {
        var attr = pthread_mutexattr_t()
        defer { pthread_mutexattr_destroy(&attr) }
        
        pthread_mutexattr_init(&attr)
        
        pthread_mutex_init(&mutex, &attr)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    public func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    public func unlock() {
        pthread_mutex_unlock(&mutex)
    }

    var mutex = pthread_mutex_t()
}
