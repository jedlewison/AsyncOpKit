import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncOpKitTests: QuickSpec {
    
    internal func createTestInstance() -> AsyncOperation {
        return AsyncOperation()
    }
    
    override func spec() {
        describe("The behavior of an AsyncOperation") {
            
            var subject: AsyncOperation! = nil
            var finishedOperation: AsyncOperation? = nil
            var resultsHandlerCompleted: Bool? = nil
            
            beforeEach {
                finishedOperation = nil
                resultsHandlerCompleted = false
                
                subject = self.createTestInstance()
                subject.resultsHandler = {
                    finishedOp in
                    finishedOperation = finishedOp as? AsyncOperation
                    resultsHandlerCompleted = true
                }
            }
            
            afterEach {
                finishedOperation = nil
                resultsHandlerCompleted = nil
                subject?.resultsHandler = nil
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
                    xit("should be executing") {
                        // TODO: Figure out why this test registers false positives
                        // Might be an error with Quick/Nimble/XCTest ... or AOK
                        expect(subject.executing).to(beTrue())
                    }

                    xit("should not be finished") {
                        // TODO: Figure out why this test registers false positives
                        // Might be an error with Quick/Nimble/XCTest ... or AOK
                        expect(subject.finished).to(beFalse())
                    }

                    it("should not be cancelled") {
                        expect(subject.cancelled).to(beFalse())
                    }

                    it("should not execute its results handler") {
                        expect(resultsHandlerCompleted).to(beFalse())
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
                        expect(resultsHandlerCompleted).toEventually(beTrue())
                    }
                    
                    it("should nil out the results handler") {
                        expect(subject.resultsHandler).toEventually(beNil())
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
                    
                    it("should immediatelhy be marked as cancelled") {
                        expect(subject.cancelled).to(beTrue())
                    }
                    
                    it("should eventually stop executing and finish") {
                        expect(subject.executing).toEventually(beFalse())
                        expect(subject.finished).toEventually(beTrue())
                    }
                    
                    it("should invoke the results closure when finished") {
                        expect(resultsHandlerCompleted).toEventually(beTrue())
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
                    expect(resultsHandlerCompleted).toEventually(beTrue())
                }
                
                it("the resultsHandler's resultsObject should mark it as cancelled") {
                    expect(finishedOperation?.cancelled).toEventually(beTrue())
                }
            }
            
        }
    }
}