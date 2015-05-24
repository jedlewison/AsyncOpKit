import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncOpKitTests: QuickSpec {
    
    override func spec() {
        describe("The behavior of an AsyncOperation") {
            
            var subject : JDAsyncOperation? = nil
            var resultsObject : JDAsyncOperationResults? = nil
            var resultsHandlerCompleted : Bool? = nil
            
            beforeEach {
                resultsObject = nil
                resultsHandlerCompleted = false
                
                subject = JDAsyncOperation()
                subject?.completionHandler = {
                    result in
                    resultsObject = result
                    resultsHandlerCompleted = true
                }
            }
            
            afterEach {
                resultsObject = nil
                resultsHandlerCompleted = nil
            }
            
            context("when it starts normally") {
                
                beforeEach {
                    subject?.start()
                }
                
                describe("immediately after starting") {
                    it("should be executing") {
                        expect(subject?.executing).to(beTrue())
                    }
                    
                    it("should not be finished") {
                        expect(subject?.finished).to(beFalse())
                    }
                    
                    it("should not execute its results handler") {
                        expect(resultsHandlerCompleted).to(beFalse())
                    }
                    
                    it("should still have a results handler") {
                        expect(subject?.completionHandler).toNot(beNil())
                    }
                }
                
                describe("asynchronously after starting") {
                    it("should stop executing") {
                        expect(subject?.executing).toEventually(beFalse())
                    }
                    
                    it("should finish") {
                        expect(subject?.finished).toEventually(beTrue())
                    }
                    
                    it("should execute its results handler") {
                        expect(resultsHandlerCompleted).toEventually(beTrue())
                    }
                    
                    it("should nil out the results handler") {
                        expect(subject?.completionHandler).toEventually(beNil())
                    }
                    
                    it("should return itself in its results handler resultsObject") {
                        expect(resultsObject?.operation).toEventually(equal(subject))
                    }
                }
                
                context("when an operation finishes normally") {
                    
                    beforeEach {
                        subject?.finish()
                    }
                    
                    it("should not be cancelled") {
                        expect(subject?.cancelled).toEventuallyNot(beTrue())
                    }
                    
                    it("should eventually be finished") {
                        expect(subject?.finished).toEventually(beTrue())
                    }
                    
                    it("should start executing and stop executing") {
                        expect(subject?.executing).toEventually(beFalse())
                    }
                    
                    context("when an operation is started after being finished") {
                        
                        beforeEach {
                            subject?.start()
                        }
                        
                        it("should still be finished") {
                            expect(subject?.finished).to(beTrue())
                        }
                        
                        it("should not be executing") {
                            expect(subject?.executing).to(beFalse())
                        }
                        
                    }

                }
                
                context("When an operation is cancelled after being started but before completion") {
                    
                    beforeEach {
                        subject?.cancel()
                    }
                    
                    it("should immediatelhy be marked as cancelled") {
                        expect(subject?.cancelled).to(beTrue())
                    }
                    
                    it("should not still be executing if handleCancellation synchronously finishes the op") {
                        expect(subject?.executing).to(beFalse())
                        expect(subject?.finished).to(beTrue())
                    }
                }

            }
            
            context("when it is canceled before starting") {
                
                beforeEach {
                    subject?.cancel()
                    subject?.start()
                }
                
                it("should immediately cancel") {
                    expect(subject?.cancelled).to(beTrue())
                }
                
                it("should be finished") {
                    expect(subject?.finished).to(beTrue())
                }
                
                it("should not start executing") {
                    expect(subject?.executing).to(beFalse())
                }
                
                it("should never be executing") {
                    expect(subject?.executing).toEventuallyNot(beTrue())
                }
                
                it("the resultsHandler's resultsObject should mark it as cancelled") {
                    expect(resultsObject?.cancelled).toEventually(beTrue())
                }
            }
            
            context("the completion block should fire with a results object in all scenarios") {
                
                var resultsObject : JDAsyncOperationResults!
                
            }
            
        }
    }
}