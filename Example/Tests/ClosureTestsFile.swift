import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncClosureOpKitConvenienceInitTests: AsyncOpKitTests {
    
    override internal func createTestInstance() -> AsyncOperation {
        
        // make sure the init closures object can pass all the current tests
        let dispatchQ = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Double(NSEC_PER_SEC)))

        let closuresOp = AsyncClosuresOperation(queueKind: .Background) {
            closureController in
            dispatch_after(delayTime, dispatchQ) {
                closureController.finishClosure()
            }
        }
        
        return closuresOp
    }
}

class AsyncClosureOpKitClassFactoryTests: AsyncOpKitTests {
    
    override internal func createTestInstance() -> AsyncOperation {
        
        // make sure the factory created closures object can pass all the current tests
        let dispatchQ = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Double(NSEC_PER_SEC)))
        
        let closuresOp = AsyncClosuresOperation.asyncClosuresOperation(.Main) {
            closureController in
            dispatch_after(delayTime, dispatchQ) {
                closureController.finishClosure()
            }
        }
        
        return closuresOp
    }
}

class AsyncClosureOpKitTests: QuickSpec {
    
    // Using a reference type to make it easier to cleanup
    internal class TestAssistant {
        var numberOfAsyncClosuresFinished = 0
        var resultValue = "Should change"
        var numberOfCancellations = 0
    }
    
    override func spec() {
        specWithQueueKind(.Background)
        specWithQueueKind(.Main)
    }
    
    func specWithQueueKind(queueKind: AsyncClosuresQueueKind) {
        
        describe("Handle Async Closures") {
            
            var subject: AsyncClosuresOperation! = nil
            var dispatchQ: dispatch_queue_t!
            var testAssistant: TestAssistant! = nil
            
            beforeEach {
                dispatchQ = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
                testAssistant = TestAssistant()
                
                subject = AsyncClosuresOperation(queueKind: queueKind)
            }
            
            afterEach {
                if let subject = subject {
                    subject.cancel()
                    subject.finish()
                    subject.completionBlock = nil
                    subject.resultsHandler = nil
                    
                }
                subject = nil
                dispatchQ = nil
                testAssistant = nil
            }
            
            context("when there is one closure that finishes synchronously") {
                
                let expectedValue = "AsyncClosuresOperation result value"
                
                beforeEach {
                    subject.addAsyncClosure {
                        closureController in
                        testAssistant.numberOfAsyncClosuresFinished++
                        closureController.value = expectedValue
                        closureController.finishClosure()
                        
                    }
                    
                    subject.resultsHandler = {
                        finishedOp in
                        if let value = finishedOp.value as? String {
                            testAssistant.resultValue = value
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute one closure") {
                    expect(testAssistant.numberOfAsyncClosuresFinished).toEventually(equal(1))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
                
                it("should have the same value that was assigned in the closure") {
                    expect(testAssistant.resultValue).toEventually(equal(expectedValue))
                }
            }
            
            context("when there are ten closures that finish synchronously") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            testAssistant.numberOfAsyncClosuresFinished++
                            closureController.finishClosure()
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute ten closures") {
                    expect(testAssistant.numberOfAsyncClosuresFinished).toEventually(equal(10))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
            }
            
            context("when there are ten closures that finish asynchronously") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            dispatch_async(dispatchQ) {
                                testAssistant.numberOfAsyncClosuresFinished++
                                closureController.finishClosure()
                            }
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute ten closures") {
                    expect(testAssistant.numberOfAsyncClosuresFinished).toEventually(equal(10))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
            }
            
            context("when there are ten closures that finish asynchronously with multiple finishAsyncClosure commands") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            dispatch_async(dispatchQ) {
                                testAssistant.numberOfAsyncClosuresFinished++
                                closureController.finishClosure()
                                closureController.finishClosure()
                                closureController.finishClosure()
                                closureController.finishClosure()
                                
                            }
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute ten closures") {
                    expect(testAssistant.numberOfAsyncClosuresFinished).toEventually(equal(10))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
            }
            
            
            context("when the operation is cancelled after executing five closures but the closures simply opt-out by marking the closure finished") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            if closureController.operationCancelled {
                                testAssistant.numberOfCancellations++
                                closureController.finishClosure()
                                return
                            }
                            dispatch_async(dispatchQ) {
                                testAssistant.numberOfAsyncClosuresFinished++
                                if (testAssistant.numberOfAsyncClosuresFinished == 5) {
                                    closureController.cancelOperation()
                                }
                                closureController.finishClosure()
                                
                            }
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute five uncancelled closures") {
                    expect(testAssistant.numberOfAsyncClosuresFinished).toEventually(equal(5))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
                
                it("should eventually mark itself as canceled") {
                    expect(subject.cancelled).toEventually(beTrue())
                }
                
                it("should tell 5 of the closures that it was cancelled") {
                    expect(testAssistant.numberOfCancellations).toEventually(equal(5))
                }
            }
            
            context("when the operation is cancelled after executing five closures and the async block finishes after cancellation") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            if closureController.operationCancelled {
                                testAssistant.numberOfCancellations++
                                closureController.finishClosure()
                                return
                            }
                            dispatch_async(dispatchQ) {
                                testAssistant.numberOfAsyncClosuresFinished++
                                if (testAssistant.numberOfAsyncClosuresFinished == 5) {
                                    closureController.cancelOperation()
                                }
                                closureController.finishClosure()
                            }
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute five uncancelled closures") {
                    expect(testAssistant.numberOfAsyncClosuresFinished).toEventually(equal(5))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
                
                it("should eventually mark itself as canceled") {
                    expect(subject.cancelled).toEventually(beTrue())
                }
                
                it("should tell 5 of the closures that it was cancelled and not execute the remaining 5") {
                    expect(testAssistant.numberOfCancellations).toEventually(equal(5))
                    expect(testAssistant.numberOfAsyncClosuresFinished).toEventually(equal(5))
                }
            }
            
        }
        
    }
    
}
