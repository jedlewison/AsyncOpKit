//
//  AsyncOpResultStatus.swift
//  AsyncOp
//
//  Created by Jed Lewison on 9/7/15.
//  Copyright © 2015 Magic App Factory. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import AsyncOpKit


class AsyncOpResultStatusTests : QuickSpec {

    override func spec() {

        var randomOutputNumber = 0
        var subject: AsyncOp<AsyncVoid, Int>?
        var opQ: NSOperationQueue?

        describe("Result status") {

            beforeEach {
                randomOutputNumber = random()
                subject = AsyncOp()
                opQ = NSOperationQueue()
            }

            afterEach {
                subject = nil
                opQ = nil
            }

            context("Operation hasn't finished") {

                beforeEach {
                    subject?.onStart { op in
                        usleep(200000)
                        op.finish(with: randomOutputNumber)
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: false)
                }

                it("the result status should be pending") {
                    expect(subject?.resultStatus).to(equal(AsyncOpResultStatus.Pending))
                }

            }

            context("Operation has finished with success") {

                beforeEach {
                    subject?.onStart { op in
                        op.finish(with: randomOutputNumber)
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: true)
                }

                it("the result status should be succeeded") {
                    expect(subject?.resultStatus).to(equal(AsyncOpResultStatus.Succeeded))
                }
                
            }
            
            context("Operation has finished because it was cancelled") {

                beforeEach {
                    subject?.addPreconditionEvaluator { return .Cancel }
                    opQ?.addOperations([subject!], waitUntilFinished: true)
                }

                it("the result status should be cancelled") {
                    expect(subject?.resultStatus).to(equal(AsyncOpResultStatus.Cancelled))
                }
                
            }

            context("Operation has finished because it failed") {

                beforeEach {
                    subject?.onStart { op in
                        op.finish(with: AsyncOpError.Unspecified)
                    }
                    opQ?.addOperations([subject!], waitUntilFinished: true)
                }

                it("the result status should be failed") {
                    expect(subject?.resultStatus).to(equal(AsyncOpResultStatus.Failed))
                }
                
            }

        }
    }
}
