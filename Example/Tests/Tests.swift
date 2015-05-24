import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncOpKitTests: QuickSpec {

    override func spec() {

        describe("Starting an AsyncOperation") {

            var subject : JDAsyncOperation! = nil
            var opQ : NSOperationQueue! = nil
            var resultsObject : JDAsyncOperationResults!


            beforeEach {
                subject = JDAsyncOperation()
                subject.completionHandler = {
                    result in
                    resultsObject = result
                }
                opQ = NSOperationQueue()
            }

            context("when it starts normally") {

                beforeEach {
                    opQ.addOperation(subject)
                }

                it("should turn to the executing state immediately after being started") {
                    expect(subject.executing).to(beTrue())
                }

                it("should not have completed yet") {
                    expect(resultsObject).to(beNil())
                    expect(resultsObject.operation).toEventually(equal(subject))

                }

            }

            context("when it is canceled before starting") {

                beforeEach {
                    subject.cancel()
                    //                    subject.start()
                    opQ.addOperation(subject)
                }

                it("should be cancelled") {
                    expect(subject.cancelled).to(beTrue())
                }

                it("should be finished") {
                    expect(subject.finished).toEventually(beTrue())
                }

                it("should stop executing") {
                    expect(subject.executing).to(beFalse())
                }

            }

            context("when an operation finishes normally") {

                beforeEach {
                    //                    subject.start()
                    opQ.addOperation(subject)
                    //                    subject.start()
                    //                    subject.finish()
                }

                it("should not be cancelled") {
                    expect(subject.cancelled).to(beFalse())
                }

                it("should eventually be finished") {
                    expect(subject.finished).to(beFalse())
                    expect(subject.finished).toEventually(beTrue())
                }

                it("should start executing and stop executing") {
                    expect(subject.executing).toEventually(beTrue())
                    expect(subject.executing).toEventually(beFalse())
                }

            }

            context("when an operation is started after being finished") {

                beforeEach {
                    opQ.addOperations([subject], waitUntilFinished: true)
                    subject.start()
                }

                it("should still be finished") {
                    expect(subject.finished).to(beTrue())
                }

                it("should not be executing") {
                    expect(subject.executing).to(beFalse())
                }

            }

            context("When an operation is cancelled after being started but before completion") {

                beforeEach {
                    //                    subject.start()
                    opQ.addOperation(subject)
                    subject.cancel()
                }

                it("should immediatelhy be marked as cancelled") {
                    expect(subject.cancelled).to(beTrue())
                }
                
                it("should not still be executing if handleCancellation synchronously finishes the op") {
                    expect(subject.executing).to(beFalse())
                    expect(subject.finished).to(beTrue())
                }
            }
            
            context("the completion block should fire with a results object in all scenarios") {
                
                var resultsObject : JDAsyncOperationResults!
                
            }
            
        }
    }
}