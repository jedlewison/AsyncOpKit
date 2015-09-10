//
//  AsyncOpInferringInputTests.swift
//  AsyncOp
//
//  Created by Jed Lewison on 9/3/15.
//  Copyright © 2015 Magic App Factory. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import AsyncOpKit

let StringForTest = "Subclass Done!"

class AnAsyncOpSubclass : AsyncOp<AsyncVoid, String> {

    let testValue: String
    required init(testData: String) {
        testValue = testData
        super.init()
        onStart( performOperation )
    }

    func performOperation(asyncOp: AsyncOp<AsyncVoid, String>) throws -> Void {
        usleep(50050)
        finish(with: .Some(testValue))
    }
}

class AsyncOpSubclassTests : QuickSpec {

    override func spec() {

        describe("AsyncOp subclass") {

            var subject: AnAsyncOpSubclass!
            var opQ: NSOperationQueue!
            var outputValue: String?

            beforeEach {
                opQ = NSOperationQueue()
                opQ.maxConcurrentOperationCount = 1
                subject = AnAsyncOpSubclass(testData: StringForTest)
                subject.whenFinished { operation in
                    outputValue = operation.output.value
                }
                opQ.addOperation(subject)
            }

            context("Normal operation") {
                it("should out the correct value") {
                    expect(outputValue).toEventually(equal(StringForTest))
                }
            }
            
        }
    }
}
