import Assertions
import XCTest

@testable import Synchronization

final class SemaphoreTests: XCTestCase {
    @MainActor
    func testSemaphore() async throws {
        let semaphore = Semaphore(value: 5)
        
        struct State {
            var occupancy = 0
            var maxOccupancy = 0
        }
        
        @Synchronized
        var state = State()
        
        await withTaskGroup(of: Void.self) { taskGroup in
            for _ in 0..<50 {
                taskGroup.addTask { [_state] in
                    semaphore.acquire {
                        defer { _state.occupancy -= 1 }
                        
                        _state.write { state in
                            state.occupancy += 1
                            state.maxOccupancy = max(state.occupancy, state.maxOccupancy)
                        }
                        
                        Thread.sleep(forTimeInterval: 1e-3)
                    }
                }
            }
        }
        
        try assertEqual(5, _state.maxOccupancy)
    }
}
