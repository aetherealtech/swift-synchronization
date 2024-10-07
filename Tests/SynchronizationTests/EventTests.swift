import Assertions
import XCTest

@testable import Synchronization

final class EventTests: XCTestCase {
    func testEvent() async throws {
        let event = Event()
        
        defer { event.signal() }

        try assertFalse(event.signaled)
        
        @Synchronized
        var finished: Set<Int> = []
        
        await withCheckedContinuation { [_finished] outerContinuation in
            Task {
                for index in 0..<5 {
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            continuation.resume()
                            event.wait()
                            _finished.write { finished in _ = finished.insert(index) }
                        }
                    }
                }
                
                try! await Task.sleep(nanoseconds: 1_000_000)
                
                await withCheckedContinuation { continuation in
                    Task.detached {
                        continuation.resume()
                        event.signal()
                        try assertFalse(event.signaled)
                        
                        try! await Task.sleep(nanoseconds: 1_000_000)
                        
                        outerContinuation.resume()
                    }
                }
                
                for index in 5..<10 {
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            continuation.resume()
                            event.wait()
                            _finished.write { finished in _ = finished.insert(index) }
                        }
                    }
                }
            }
        }
                
        try assertEqual(Set(0..<5), finished)
    }
    
    func testEventNoReset() async throws {
        let event = Event()
        
        defer { event.signal() }

        @Synchronized
        var finished: Set<Int> = []
        
        await withCheckedContinuation { [_finished] outerContinuation in
            Task {
                for index in 0..<5 {
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            continuation.resume()
                            event.wait()
                            _finished.write { finished in _ = finished.insert(index) }
                        }
                    }
                }
                
                try! await Task.sleep(nanoseconds: 1_000_000)
                
                await withCheckedContinuation { continuation in
                    Task.detached {
                        continuation.resume()
                        event.signal(reset: false)
                        try assertTrue(event.signaled)
                        
                        try! await Task.sleep(nanoseconds: 1_000_000)
                        
                        outerContinuation.resume()
                    }
                }
                
                for index in 5..<10 {
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            continuation.resume()
                            event.wait()
                            _finished.write { finished in _ = finished.insert(index) }
                        }
                    }
                }
            }
        }
                
        try assertEqual(Set(0..<10), finished)
    }
    
    func testEventManualReset() async throws {
        let event = Event()
        
        defer { event.signal() }

        @Synchronized
        var finished: Set<Int> = []
        
        await withCheckedContinuation { [_finished] outerContinuation in
            Task {
                for index in 0..<5 {
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            continuation.resume()
                            event.wait()
                            _finished.write { finished in _ = finished.insert(index) }
                        }
                    }
                }
                
                try! await Task.sleep(nanoseconds: 1_000_000)
                
                await withCheckedContinuation { continuation in
                    Task.detached {
                        continuation.resume()
                        event.signal(reset: false)
                        try assertTrue(event.signaled)
                        
                        try! await Task.sleep(nanoseconds: 1_000_000)
                        
                        outerContinuation.resume()
                    }
                }
                
                for index in 5..<10 {
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            continuation.resume()
                            if index == 8 {
                                event.reset()
                            }
                            
                            event.wait()
                            _finished.write { finished in _ = finished.insert(index) }
                        }
                    }
                }
            }
        }
                
        try assertEqual(Set(0..<8), finished)
    }
}

