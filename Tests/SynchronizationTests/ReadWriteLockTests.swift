import Assertions
import XCTest

@testable import Synchronization

final class ReadWriteLockTests: XCTestCase {
    @MainActor
    func testExclusiveLockable() async throws {
        let possibleValues = (0..<5)
            .map { _ in Int.random(in: 5..<15) }
        
        let lock = ReadWriteLock().exclusiveLockable
        
        @UnsafeBox
        var value = possibleValues.randomElement()!
        
        @UnsafeBox
        var values: [Int] = []
        
        // See first test in `SynchronizedTests` for explanation of this.
        await withTaskGroup(of: Void.self) { [_values, _value] taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask {
                    let value = lock.lock { _value.wrappedValue }
                    await MainActor.run { _values.wrappedValue.append(value) }
                }
                
                taskGroup.addTask { lock.lock { _value.wrappedValue = possibleValues.randomElement()! } }
            }
        }
        
        for value in values {
            try assertTrue(possibleValues.contains(value))
        }
    }
}
