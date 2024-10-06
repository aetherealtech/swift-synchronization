import Assertions
import XCTest

@testable import Synchronization

@propertyWrapper
final class UnsafeBox<T>: @unchecked Sendable {
    var wrappedValue: T
    
    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

final class SynchronizedTests: XCTestCase {
    struct TestStruct {
        var intValue: Int
        let stringValue: String
    }
    
    @MainActor
    func testWrappedValue() async throws {
        let possibleValues = (0..<5)
            .map { _ in Int.random(in: 5..<15) }
        
        let value = Synchronized(wrappedValue: possibleValues.randomElement()!)
        
        @UnsafeBox
        var values: [Int] = []
        
        // We're basically spamming the synchronized value with reads and writes to test that it synchronizes them properly.  If it does, not only will this not crash, but the values read back out will always be well-formed and equal to one of the values we wrote.
        await withTaskGroup(of: Void.self) { [_values] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    let value = value.wrappedValue
                    await MainActor.run { _values.wrappedValue.append(value) }
                }
                
                taskGroup.addTask { value.wrappedValue = possibleValues.randomElement()! }
            }
        }
        
        for value in values {
            try assertTrue(possibleValues.contains(value))
        }
    }
    
    @MainActor
    func testReadWriteBlocks() async throws {
        let possibleValues = (0..<5)
            .map { _ in Int.random(in: 5..<15) }
                
        let value = Synchronized(wrappedValue: TestStruct(intValue: possibleValues.randomElement()!, stringValue: "Something") )
        
        @UnsafeBox
        var values: [Int] = []
        
        // See first test for explanation of this
        await withTaskGroup(of: Void.self) { [_values] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    let value = value.read(\.intValue)
                    await MainActor.run { _values.wrappedValue.append(value) }
                }
                
                taskGroup.addTask { value.write { value in value.intValue = possibleValues.randomElement()! } }
            }
        }
 
        for value in values {
            try assertTrue(possibleValues.contains(value))
        }
    }
    
    @MainActor
    func testWaitUntil() async throws {
        let value = Synchronized(wrappedValue: 0)
        let conditionVariable = AnyConditionVariable<SharedLock>()
        
        @UnsafeBox
        var completed = false
        
        Task.detached { [_completed] in
            value.wait(conditionVariable) { value in
                value == 100
            }
            
            Task { @MainActor in
                _completed.wrappedValue = true
            }
        }
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertFalse(completed)
        
        for i in 0..<100 {
            value.wrappedValue = i
            conditionVariable.notifyAll()
        }
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertFalse(completed)
        
        value.wrappedValue = 100
        conditionVariable.notifyAll()
        
        try await Task.sleep(nanoseconds: 10_000)
        
        try assertTrue(completed)
    }
    
    @MainActor
    func testReadOnlyMember() async throws {
        let expectedValue = "Something"
        
        let value = Synchronized(wrappedValue: TestStruct(intValue: .random(in: 0..<100), stringValue: expectedValue) )
        
        @UnsafeBox
        var values: [String] = []
        
        // See first test for explanation of this
        await withTaskGroup(of: Void.self) { [_values] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    let value = value.stringValue
                    await MainActor.run { _values.wrappedValue.append(value) }
                }
                
                taskGroup.addTask { value.write { value in value.intValue = .random(in: 0..<100) } }
            }
        }
  
        for value in values {
            try assertTrue(value == expectedValue)
        }
    }
    
    @MainActor
    func testReadWriteMember() async throws {
        let possibleValues = (0..<5)
            .map { _ in Int.random(in: 5..<15) }
                
        let value = Synchronized(wrappedValue: TestStruct(intValue: possibleValues.randomElement()!, stringValue: "Something") )
        
        @UnsafeBox
        var values: [Int] = []
        
        // See first test for explanation of this
        await withTaskGroup(of: Void.self) { [_values] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    let value = value.intValue
                    await MainActor.run { _values.wrappedValue.append(value) }
                }
                
                taskGroup.addTask { value.intValue = possibleValues.randomElement()! }
            }
        }

        for value in values {
            try assertTrue(possibleValues.contains(value))
        }
    }
    
    @MainActor
    func testGetAndSet() async throws {
        let possibleValues = (0..<5)
            .map { _ in Int.random(in: 5..<15) }
                
        let initialValue = Int.random(in: 0..<5)
        let nextValue = possibleValues.randomElement()!
        
        let value = Synchronized(wrappedValue: initialValue)
        
        let initialResult = value.getAndSet { value in
            value = nextValue
        }
        
        try assertEqual(initialValue, initialResult)
        try assertEqual(nextValue, value.wrappedValue)
        
        @UnsafeBox
        var values: [Int] = []
        
        // See first test for explanation of this
        await withTaskGroup(of: Void.self) { [_values] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    let value = value.getAndSet { value in value = possibleValues.randomElement()! }
                    await MainActor.run { _values.wrappedValue.append(value) }
                }
            }
        }
 
        for value in values {
            try assertTrue(possibleValues.contains(value))
        }
    }
    
    @MainActor
    func testSwap() async throws {
        let initialValue = Int.random(in: 0..<5)
        let nextValue = Int.random(in: 5..<15)
        
        let value = Synchronized(wrappedValue: initialValue)
        
        @UnsafeBox
        var swappedValue = nextValue

        value.swap(&swappedValue)
        
        try assertEqual(initialValue, swappedValue)
        try assertEqual(nextValue, value.wrappedValue)
        
        @UnsafeBox
        var values: [Int] = []
        
        // See first test for explanation of this
        await withTaskGroup(of: Void.self) { [_values, _swappedValue] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    value.swap(&_swappedValue.wrappedValue)
                    await MainActor.run { _values.wrappedValue.append(value.wrappedValue) }
                }
            }
        }

        for value in values {
            try assertTrue([initialValue, nextValue].contains(value))
        }
    }
    
    @MainActor
    func testSwapReturned() async throws {
        let possibleValues = (0..<5)
            .map { _ in Int.random(in: 5..<15) }
        
        let initialValue = Int.random(in: 0..<5)
        let nextValue = possibleValues.randomElement()!
        
        let value = Synchronized(wrappedValue: initialValue)
        
        let swappedValue = value.swap(nextValue)
        
        try assertEqual(initialValue, swappedValue)
        try assertEqual(nextValue, value.wrappedValue)
        
        @UnsafeBox
        var values: [Int] = []
        
        // See first test for explanation of this
        await withTaskGroup(of: Void.self) { [_values] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    let value = value.swap(possibleValues.randomElement()!)
                    await MainActor.run { _values.wrappedValue.append(value) }
                }
            }
        }

        for value in values {
            try assertTrue(possibleValues.contains(value))
        }
    }
}
