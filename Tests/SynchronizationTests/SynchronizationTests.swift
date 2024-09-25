import XCTest
@testable import Synchronization

final class SynchronizationTests: XCTestCase {
    struct TestError: Error {
        let blahblah: String = ""
    }
    
    struct TestUnique: ~Copyable {
        var value: Int = 0
    }
    
    func test() {
        var value = Synchronized(wrappedValue: TestUnique())
        var otherValue = TestUnique(value: 2)
        
        value.swap(&otherValue)
    }
}
