import Assertions
import XCTest

@testable import Synchronization

final class CountdownLatchTests: XCTestCase {
    func testCountdownLatch() async throws {
        let count = 5
        let countdownLatch = CountdownLatch(value: count)
        
        struct State {
            var remaining: Int
            var remainingAfterWait: Int?
        }
        
        @Synchronized
        var state = State(remaining: count)
        
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask { [_state] in
                countdownLatch.wait()
                
                _state.write { state in
                    state.remainingAfterWait = state.remaining
                }
            }
            
            for _ in 0..<5 {
                taskGroup.addTask { [_state] in
                    try! await Task.sleep(nanoseconds: 1_000_000)
                    
                    _state.remaining -= 1
                    
                    countdownLatch.signal()
                }
            }
        }
        
        try assertEqual(0, _state.remainingAfterWait)
    }
}
