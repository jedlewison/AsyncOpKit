import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncOpKitTests: QuickSpec {
    
    // Create a simple subclass of the base class that does something asynchronously
    internal class TestAsyncOperation : AsyncOperation {
        let dispatchQ = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Double(NSEC_PER_SEC)))

        override final func main() {
            dispatch_after(delayTime, dispatchQ) {
                self.finish()
            }
        }
    }
    
    internal func createTestInstance() -> AsyncOperation {
        return TestAsyncOperation()
    }
    
    override func spec() {
        performTest()
    }
    
    func performTest() {
        describe("The behavior of an AsyncOperation") {
            
            var subject: AsyncOperation! = nil
            var finishedOperation: AsyncOperation? = nil
            var completionHandlerCompleted: Bool? = nil
            
            beforeEach {
                finishedOperation = nil
                completionHandlerCompleted = false
                
                subject = self.createTestInstance()
                subject.completionHandler = {
                    finishedOp in
                    finishedOperation = finishedOp
                    completionHandlerCompleted = true
                }
            }
            
            afterEach {
                finishedOperation = nil
                completionHandlerCompleted = nil
                subject?.completionHandler = nil
                subject = nil
            }
            
            context("before it starts") {
                
                it("should be ready to start") {
                    expect(subject.ready).to(beTrue())
                }
                
                it("should not be executing") {
                    expect(subject.executing).to(beFalse())
                }

                it("should not be cancelled") {
                    expect(subject.cancelled).to(beFalse())
                }
                
                it("should not be finished") {
                    expect(subject.finished).to(beFalse())
                }
                
            }
            
            context("when it starts normally") {
                
                beforeEach {
                    subject.start()
                }
                
                afterEach {
                    subject = nil
                }
                
                describe("immediately after starting") {
                    it("should be executing") {
                        expect(subject.executing).to(beTrue())
                    }

                    it("should not be finished") {
                        expect(subject.finished).to(beFalse())
                    }

                    it("should not be cancelled") {
                        expect(subject.cancelled).to(beFalse())
                    }

                    it("should not execute its results handler") {
                        expect(completionHandlerCompleted).to(beFalse())
                    }
                    
                }
                
                describe("asynchronously after starting") {
                    it("should stop executing") {
                        expect(subject.executing).toEventually(beFalse())
                    }
                    
                    it("should finish") {
                        expect(subject.finished).toEventually(beTrue())
                    }
                    
                    it("should execute its results handler") {
                        expect(completionHandlerCompleted).toEventually(beTrue())
                    }
                    
                    it("should nil out the results handler") {
                        expect(subject.completionHandler).toEventually(beNil())
                    }
                    
                    it("should return itself in its results handler resultsObject") {
                        expect(finishedOperation).toEventually(equal(subject))
                    }
                    
                    it("should return a results object that does not indicate it is canceled") {
                        expect(finishedOperation?.cancelled).toEventually(beFalse())
                    }
                }
                
                context("when an operation finishes normally") {
                    
                    it("should not be cancelled") {
                        expect(subject.cancelled).toEventuallyNot(beTrue())
                    }
                    
                    it("should eventually be finished") {
                        expect(subject.finished).toEventually(beTrue())
                    }
                    
                    it("should not be executing") {
                        expect(subject.executing).toEventually(beFalse())
                    }
                    
                    context("when an operation is started after being finished") {
                        
                        beforeEach {
                            subject.finish()
                            subject.start()
                        }
                        
                        it("should still be finished") {
                            expect(subject.finished).to(beTrue())
                        }
                        
                        it("should not be executing") {
                            expect(subject.executing).to(beFalse())
                        }
                        
                    }

                }
                
                context("When an executing operation is cancelled after being started") {
                    
                    beforeEach {
                        subject.cancel()
                    }
                    
                    it("should eventually be marked as cancelled") {
                        expect(subject.cancelled).toEventually(beTrue())
                    }
                    
                    it("should eventually stop executing and finish") {
                        expect(subject.executing).toEventually(beFalse())
                        expect(subject.finished).toEventually(beTrue())
                    }
                    
                    it("should invoke the results closure when finished") {
                        expect(completionHandlerCompleted).toEventually(beTrue())
                    }
                    
                    it("the results closure results object should mark it as cancelled") {
                        expect(finishedOperation?.cancelled).toEventually(beTrue())
                    }
                }

            }
            
            context("when it is canceled before starting") {
                
                beforeEach {
                    subject.cancel()
                    subject.start()
                }
                
                it("should immediately cancel") {
                    expect(subject.cancelled).to(beTrue())
                }
                
                it("should be finished") {
                    expect(subject.finished).to(beTrue())
                }
                
                it("should never start executing") {
                    expect(subject.executing).to(beFalse())
                }
                
                it("should never be executing") {
                    expect(subject.executing).toEventuallyNot(beTrue())
                }
                
                it ("the result handler's completion block should still fire") {
                    expect(completionHandlerCompleted).toEventually(beTrue())
                }
                
                it("the completionHandler's resultsObject should mark it as cancelled") {
                    expect(finishedOperation?.cancelled).toEventually(beTrue())
                }
            }
            
        }
    }
}