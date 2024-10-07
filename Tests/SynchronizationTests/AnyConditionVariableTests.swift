import Assertions
import XCTest

@testable import Synchronization

final class AnyConditionVariableTests: XCTestCase {
    @MainActor
    func testNotifyOne() async throws {
        @UnsafeBox
        var proceed = false
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var completed = 0
        
        for _ in 0..<5 {
            await withCheckedContinuation { [_proceed, _completed] continuation in
                Task.detached {
                    continuation.resume()
                    
                    lock.lock {
                        conditionVariable.wait(lock: lock) {
                            return _proceed.wrappedValue
                        }
                    }
                    
                    Task { @MainActor in
                        _completed.wrappedValue += 1
                    }
                }
            }
        }
        
        try assertEqual(0, completed)
        
        lock.lock { proceed = true }
        conditionVariable.notifyOne()

        try await Task.sleep(nanoseconds: 10_000_00)
        
        try assertEqual(1, completed)
        
        conditionVariable.notifyAll()
    }
    
    @MainActor
    func testNotifyAll() async throws {
        @UnsafeBox
        var proceed = false
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var completed = 0
        
        let total = 5
        
        for _ in 0..<total {
            await withCheckedContinuation { [_proceed, _completed] continuation in
                Task.detached {
                    continuation.resume()
                    
                    lock.lock {
                        conditionVariable.wait(lock: lock) {
                            return _proceed.wrappedValue
                        }
                    }
                    
                    Task { @MainActor in
                        _completed.wrappedValue += 1
                    }
                }
            }
        }
        
        try assertEqual(0, completed)
        
        lock.lock { proceed = true }
        conditionVariable.notifyAll()

        try await Task.sleep(nanoseconds: 10_000_00)
        
        try assertEqual(total, completed)
    }
    
    @MainActor
    func testWaitForTimeInterval() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, for: 10.0) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertNil(result)
        
        value = 100
        conditionVariable.notifyOne()
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertEqual(true, result)
    }
    
    @MainActor
    func testWaitForTimeIntervalTimeout() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, for: 1e-3) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 5_000_000)
        
        try assertEqual(false, result)
    }
    
    @MainActor
    func testWaitForDuration() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, for: SuspendingClock.Duration.seconds(10)) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertNil(result)
        
        value = 100
        conditionVariable.notifyOne()
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertEqual(true, result)
    }
    
    @MainActor
    func testWaitForDurationTimeout() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, for: SuspendingClock.Duration.milliseconds(1)) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 5_000_000)
        
        try assertEqual(false, result)
    }
    
    @MainActor
    func testWaitUntilDatel() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, until: .now.addingTimeInterval(10.0)) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertNil(result)
        
        value = 100
        conditionVariable.notifyOne()
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertEqual(true, result)
    }
    
    @MainActor
    func testWaitUntilDateTimeout() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, until: .now.addingTimeInterval(1e-3)) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 5_000_000)
        
        try assertEqual(false, result)
    }
    
    @MainActor
    func testWaitUntilInstant() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        let clock = SuspendingClock()
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, until: .now + .seconds(10), clock: clock) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertNil(result)
        
        value = 100
        conditionVariable.notifyOne()
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertEqual(true, result)
    }
    
    @MainActor
    func testWaitUntilInstantTimeout() async throws {
        @UnsafeBox
        var value = 0
        
        let conditionVariable = AnyConditionVariable<Lock>()
        let lock = Lock()
        
        @UnsafeBox
        var result: Bool?
        
        let clock = SuspendingClock()
        
        await withCheckedContinuation { [_value, _result] continuation in
            Task.detached {
                continuation.resume()
                let result = conditionVariable.wait(lock: lock, until: .now + .milliseconds(1), clock: clock) {
                    return _value.wrappedValue == 100
                }

                Task { @MainActor in
                    _result.wrappedValue = result
                }
            }
        }
                
        try assertNil(result)
        
        for i in 0..<100 {
            value = i
            conditionVariable.notifyOne()
        }
        
        try await Task.sleep(nanoseconds: 5_000_000)
        
        try assertEqual(false, result)
    }
}
