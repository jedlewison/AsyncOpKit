//
//  AsyncOpPreconditionEvaluatorTests.swift
//  AsyncOp
//
//  Created by Jed Lewison on 9/6/15.
//  Copyright © 2015 Magic App Factory. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import AsyncOpKit


class AsyncOpPreconditionEvaluatorTests : QuickSpec {

    override func spec() {

        var randomOutputNumber = 0
        var subject: AsyncOp<AsyncVoid, Int>?
        var opQ: NSOperationQueue?

        describe("Precondition Evaluator") {

            beforeEach {
                randomOutputNumber = random()
                subject = AsyncOp()
                subject?.onStart { op in
                    op.finish(with: randomOutputNumber)
                }
                opQ = NSOperationQueue()
            }

            afterEach {
                subject = nil
                opQ = nil
            }

            describe("Single precondition scenarios") {

                context("evaluator that instructs operation to continue") {

                    beforeEach {
                        subject?.addPreconditionEvaluator {
                            return .Continue
                        }
                        opQ?.addOperations([subject!], waitUntilFinished: false)
                    }

                    it("the subject should finish normally") {
                        expect(subject?.output.value).toEventually(equal(randomOutputNumber))
                    }

                }

                context("evaluator that instructs operation to cancel") {

                    beforeEach {
                        subject?.addPreconditionEvaluator {
                            return .Cancel
                        }
                        opQ?.addOperations([subject!], waitUntilFinished: false)
                    }

                    it("the subject should be a cancelled operation") {
                        expect(subject?.cancelled).toEventually(beTrue())
                    }

                    it("the subject should be cancelled") {
                        expect(subject?.output.noneError?.cancelled).toEventually(beTrue())
                    }

                }

                context("evaluator that instructs operation to fail") {

                    beforeEach {
                        subject?.addPreconditionEvaluator {
                            return .Fail(AsyncOpError.PreconditionFailure)
                        }
                        opQ?.addOperations([subject!], waitUntilFinished: false)
                    }

                    it("the subject should be a cancelled operation") {
                        expect(subject?.cancelled).toEventually(beTrue())
                    }

                    it("the subject should be a failed asyncop") {
                        expect(subject?.output.noneError?.failed).toEventually(beTrue())
                    }
                    
                    it("the subject shouldhave the same error that it was failed with") {
                        expect(subject?.output.noneError?.failureError?._code).toEventually(equal(AsyncOpError.PreconditionFailure._code))
                    }
                    
                }

            }

            describe("Multiple precondition scenarios") {

                context("multiple evaluators that instruct operation to continue") {

                    beforeEach {
                        subject?.addPreconditionEvaluator {
                            return .Continue
                        }
                        subject?.addPreconditionEvaluator {
                            return .Continue
                        }
                        subject?.addPreconditionEvaluator {
                            return .Continue
                        }
                        subject?.addPreconditionEvaluator {
                            return .Continue
                        }
                        subject?.addPreconditionEvaluator {
                            return .Continue
                        }
                        opQ?.addOperations([subject!], waitUntilFinished: false)
                    }

                    it("the subject should finish normally") {
                        expect(subject?.output.value).toEventually(equal(randomOutputNumber))
                    }
                    
                }
            }

            context("multiple evaluators that instruct operation to continue, but one instructs canceling") {

                beforeEach {
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Cancel
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: false)
                }

                it("the subject should be a cancelled operation") {
                    expect(subject?.cancelled).toEventually(beTrue())
                }

                it("the subject should be cancelled") {
                    expect(subject?.output.noneError?.cancelled).toEventually(beTrue())
                }

            }

            context("multiple evaluators that instruct operation to continue, but one instructs Failing") {

                beforeEach {
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Fail(AsyncOpError.PreconditionFailure)
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: false)
                }

                it("the subject should be a cancelled operation") {
                    expect(subject?.cancelled).toEventually(beTrue())
                }

                it("the subject should be a failed asyncop") {
                    expect(subject?.output.noneError?.failed).toEventually(beTrue())
                }

                it("the subject shouldhave the same error that it was failed with") {
                    expect(subject?.output.noneError?.failureError?._code).toEventually(equal(AsyncOpError.PreconditionFailure._code))
                }

            }

            context("multiple evaluators that instruct operation to continue, but one instructs canceling and one instructs Failing") {

                beforeEach {
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Cancel
                    }
                    subject?.addPreconditionEvaluator {
                        return .Fail(AsyncOpError.PreconditionFailure)
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: false)
                }

                it("the subject should be a cancelled operation") {
                    expect(subject?.cancelled).toEventually(beTrue())
                }

                it("the subject should be a failed asyncop") {
                    expect(subject?.output.noneError?.failed).toEventually(beTrue())
                }

                it("the subject shouldhave the same error that it was failed with") {
                    expect(subject?.output.noneError?.failureError?._code).toEventually(equal(AsyncOpError.PreconditionFailure._code))
                }
                
            }

            context("multiple evaluators that instruct operation to continue, but one instructs canceling and multiple instruct Failing") {

                beforeEach {
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Continue
                    }
                    subject?.addPreconditionEvaluator {
                        return .Cancel
                    }
                    subject?.addPreconditionEvaluator {
                        return .Fail(AsyncOpError.PreconditionFailure)
                    }
                    subject?.addPreconditionEvaluator {
                        return .Fail(AsyncOpError.PreconditionFailure)
                    }
                    subject?.addPreconditionEvaluator {
                        return .Fail(AsyncOpError.PreconditionFailure)
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: false)
                }

                it("the subject should be a cancelled operation") {
                    expect(subject?.cancelled).toEventually(beTrue())
                }

                it("the subject should be a failed asyncop") {
                    expect(subject?.output.noneError?.failed).toEventually(beTrue())
                }

            }


        }
    }
}
