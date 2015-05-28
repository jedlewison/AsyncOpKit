import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncClosureOpKitConvenienceInitTests: AsyncOpKitTests {

    override internal func createTestInstance() -> AsyncOperation {
        
        // make the init closures object can pass all the current tests

        let closuresOp = AsyncClosuresOperation(queueKind: .Main) {
            closureController in
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                closureController.finishClosure()
            }
        }
        
        return closuresOp
    }
}

//class AsyncClosureOpKitClassFactoryTests: AsyncOpKitTests {
//    
//    override internal func createTestInstance() -> AsyncOperation {
//        
//        // make the factory created closures object can pass all the current tests
//
//        let closuresOp = AsyncClosuresOperation.asyncClosuresOperationWithClosure(.Main) {
//            closureController in
//            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
//                closureController.finishClosure()
//            }
//        }
//        
//        return closuresOp
//    }
//}

class AsyncClosureOpKitTests: QuickSpec {
    
    override func spec() {
        
        describe("Handle Async Closures") {
            
            var subject: AsyncClosuresOperation! = nil
            var finishedOperation: AsyncOperationObjectProtocol? = nil
            var resultsHandlerCompleted: Bool? = nil
            var numberOfAsyncClosuresFinished: Int?
            var resultValue = "Should change"

            beforeEach {
                numberOfAsyncClosuresFinished = 0
                finishedOperation = nil
                resultsHandlerCompleted = false
                
                subject = AsyncClosuresOperation(queueKind: .Main)
                subject.resultsHandler = {
                    result in
                    finishedOperation = result
                    resultsHandlerCompleted = true
                    if let opValue = finishedOperation?.value as? String {
                        resultValue = opValue
                    }
                }
            }
            
            afterEach {
                resultValue = "Should change"
                finishedOperation = nil
                resultsHandlerCompleted = nil
                subject?.resultsHandler = nil
                subject = nil
                numberOfAsyncClosuresFinished = nil
            }
            
            context("when there is one closure that finishes synchronously") {
                
                var expectedValue = "AsyncClosuresOperation result value"
                
                beforeEach {
                    subject.addAsyncClosure {
                        closureController in
                        numberOfAsyncClosuresFinished?++
                        closureController.value = expectedValue
                        closureController.finishClosure()

                    }
                    
                    subject.resultsHandler = {
                        finishedOp in
                        if let value = finishedOp.value as? String {
                           resultValue = value
                        }
                    }

                    subject.start()
                }
                
                it("should execute one closure") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(1))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
                
                it("should have the same value that was assigned in the closure") {
                    expect(resultValue).toEventually(equal(expectedValue))
                }
            }
            
            context("when there are ten closures that finish synchronously") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            numberOfAsyncClosuresFinished?++
                            closureController.finishClosure()
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute ten closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(10))
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
                            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                numberOfAsyncClosuresFinished?++
                                closureController.finishClosure()
                            }
                        }
                    }
                    
                    subject.start()
                }
                
                it("should execute ten closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(10))
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
                            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                numberOfAsyncClosuresFinished?++
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
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(10))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
            }

            
            context("when the operation is cancelled after executing five closures but the closures simply opt-out by marking the closure finished") {
                
                var numberOfCancellations = 0
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            if closureController.operationCancelled {
                                numberOfCancellations++
                                closureController.finishClosure()
                                return
                            }
                            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                numberOfAsyncClosuresFinished?++
                                if (numberOfAsyncClosuresFinished == 5) {
                                    closureController.cancelOperation()
                                }
                                closureController.finishClosure()
                                
                            }
                        }
                    }
                    
                    subject.start()
                }
                
                afterEach {
                    numberOfCancellations = 0
                    subject?.finish()
                    subject = nil
                }
                
                it("should execute five uncancelled closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(5))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
                
                it("should eventually mark itself as canceled") {
                    expect(subject.cancelled).toEventually(beTrue())
                }
                
                it("should tell 5 of the closures that it was cancelled") {
                    expect(numberOfCancellations).toEventually(equal(5))
                }
            }
            
            context("when the operation is cancelled after executing five closures and the async block finishes after cancellation") {
                
                var numberOfCancellations = 0
                
                beforeEach {
                    for _ in 0...9 {
                        subject.addAsyncClosure {
                            closureController in
                            if closureController.operationCancelled {
                                numberOfCancellations++
                                closureController.finishClosure()
                                return
                            }
                            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                numberOfAsyncClosuresFinished?++
                                if (numberOfAsyncClosuresFinished == 5) {
                                    closureController.cancelOperation()
                                }
                                closureController.finishClosure()
                            }
                        }
                    }
                    
                    subject.start()
                }
                
                afterEach {
                    numberOfCancellations = 0
                    subject?.finish()
                    subject = nil
                }
                
                it("should execute five uncancelled closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(5))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject.finished).toEventually(beTrue())
                }
                
                it("should eventually mark itself as canceled") {
                    expect(subject.cancelled).toEventually(beTrue())
                }
                
                it("should tell 5 of the closures that it was cancelled and not execute the remaining 5") {
                    expect(numberOfCancellations).toEventually(equal(5))
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(5))
                }
            }

        }
        
    }
    
}
