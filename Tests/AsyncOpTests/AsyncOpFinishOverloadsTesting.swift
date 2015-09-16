import Foundation
import Quick
import Nimble
@testable import AsyncOpKit


class AsyncOpFinishOverloadsTesting : QuickSpec {

    override func spec() {
        universalOverloadSpec()
        voidOverloadSpec()
    }

    func universalOverloadSpec() {

        var randomOutputNumber = 0
        var subjectNoOverloads: AsyncOp<AsyncVoid, Int>?
        var subjectUsingOverloads: AsyncOp<AsyncVoid, Int>?
        var opQ: NSOperationQueue?

        describe("Finish Overloads") {

            beforeEach {
                randomOutputNumber = random()
                subjectNoOverloads = AsyncOp()
                subjectUsingOverloads = AsyncOp()
                opQ = NSOperationQueue()
            }

            afterEach {
                subjectNoOverloads = nil
                subjectUsingOverloads = nil
                opQ = nil
            }

            context("Success") {

                beforeEach {
                    subjectNoOverloads?.onStart { op in
                        op.finish(with: .Some(randomOutputNumber))
                    }
                    subjectUsingOverloads?.onStart { op in
                        op.finish(with: randomOutputNumber)
                    }
                    randomOutputNumber = random()
                    opQ?.addOperations([subjectNoOverloads!, subjectUsingOverloads!], waitUntilFinished: true)
                }

                it("both subjects should have the same output") {
                    expect(subjectNoOverloads?.output.value).to(equal(randomOutputNumber))
                    expect(subjectUsingOverloads?.output.value).to(equal(randomOutputNumber))
                }

            }

            context("Cancelled") {

                beforeEach {
                    subjectNoOverloads?.onStart { op in
                        op.finish(with: .None(.Cancelled))
                    }
                    subjectUsingOverloads?.onStart { op in
                        op.finish(with: .Cancelled)
                    }
                    opQ?.addOperations([subjectNoOverloads!, subjectUsingOverloads!], waitUntilFinished: true)
                }

                it("both subjects should have the same output") {
                    expect(subjectNoOverloads?.output.noneError?.cancelled).to(beTrue())
                    expect(subjectUsingOverloads?.output.noneError?.cancelled).to(beTrue())
                }
                
            }

            context("Failed") {

                beforeEach {
                    subjectNoOverloads?.onStart { op in
                        op.finish(with: .None(.Failed(AsyncOpError.Unspecified)))
                    }
                    subjectUsingOverloads?.onStart { op in
                        op.finish(with: .Failed(AsyncOpError.Unspecified))
                    }
                    opQ?.addOperations([subjectNoOverloads!, subjectUsingOverloads!], waitUntilFinished: true)
                }

                it("both subjects should have the same output") {
                    expect(subjectNoOverloads?.output.noneError?.failureError?._code).to(equal(AsyncOpError.Unspecified._code))
                    expect(subjectUsingOverloads?.output.noneError?.failureError?._code).to(equal(AsyncOpError.Unspecified._code))
                }
            }
        }
    }

    func voidOverloadSpec() {

        var subject: AsyncOp<AsyncVoid, AsyncVoid>?
        var opQ: NSOperationQueue?

        describe("AsyncVoid") {

            beforeEach {
                subject = AsyncOp()
                opQ = NSOperationQueue()
            }

            afterEach {
                subject = nil
                opQ = nil
            }

            context("Success") {

                beforeEach {
                    subject?.onStart { asyncOp in
                        asyncOp.finishWithSuccess()
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: true)
                }

                it("should finish as succeeded") {
                    expect(subject?.resultStatus).to(equal(AsyncOpResultStatus.Succeeded))
                }
            }
        }
    }
}
