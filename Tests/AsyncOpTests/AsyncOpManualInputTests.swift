//
//  AsyncOpInput.swift
//  AsyncOp
//
//  Created by Jed Lewison on 9/3/15.
//  Copyright © 2015 Magic App Factory. All rights reserved.
//

import Foundation

import Foundation
import Quick
import Nimble
@testable import AsyncOpKit


class AsyncOpInput : QuickSpec {

    var randomOutputNumber = random()

    override func spec() {

        describe("Setting async operation input") {

            var subject: AsyncOp<Int, Int>!
            var inputValue: Int?
            var opQ: NSOperationQueue!
            var randomOutputNumber: Int!

            beforeEach {
                self.randomOutputNumber = random()
                randomOutputNumber = self.randomOutputNumber
                opQ = NSOperationQueue()
                subject = AsyncOp<Int, Int>()
                inputValue = nil
                subject.onStart { operation in
                    let outValue = try operation.input.getValue()
                    inputValue = outValue
                    operation.finish(with: .Some(outValue))
                }
            }

            context("An Async operation with an input set before the operation is added to a queue") {

                beforeEach {
                    subject.setInput(.Some(randomOutputNumber))
                    opQ.addOperations([subject], waitUntilFinished: false)
                }

                it("should have an input value of randomOutputNumber in the onStart closure") {
                    expect(subject.input.value).toEventually(equal(randomOutputNumber))
                }

            }

            context("An Async operation with an input set after the operation has started") {

                beforeEach {
                    opQ.maxConcurrentOperationCount = 1
                    subject.onStart { operation in
                        guard let outValue = operation.input.value else { throw AsyncOpError.Unspecified }
                        inputValue = outValue
                        operation.finish(with: .Some(outValue))
                    }
                    opQ.addOperations([subject], waitUntilFinished: false)
                    opQ.addOperationWithBlock {
                        subject.setInput(.Some(randomOutputNumber))
                    }
                }

                it("should have an input value of randomOutputNumber in the onStart closure") {
                    expect(subject.input.value).toEventually(beNil())
                }
            }

            context("A paused Async operation with input set after it has been added to an operation queue, and then resumed") {

                beforeEach {
                    opQ.maxConcurrentOperationCount = 1
                    subject.pause()
                    subject.onStart { operation in
                        guard let outValue = operation.input.value else { throw AsyncOpError.Unspecified }
                        inputValue = outValue
                        operation.finish(with: .Some(outValue))
                    }
                    opQ.addOperations([subject], waitUntilFinished: false)
                    opQ.addOperationWithBlock {
                        subject.setInput(randomOutputNumber, andResume: true)
                    }
                }

                it("should have an input value of randomOutputNumber in the onStart closure") {
                    expect(subject.input.value).toEventually(equal(randomOutputNumber))
                }
            }

            context("An async operation without any input set") {

                describe("Automatic Input Mode") {

                    beforeEach {
                        opQ.addOperations([subject], waitUntilFinished: false)
                    }

                    it("should not have an input value") {
                        expect(inputValue).toEventually(beNil())
                    }

                }

                describe("Manual Input Mode") {

                    beforeEach {
                        opQ.addOperations([subject], waitUntilFinished: false)
                    }

                    it("should have an input value of nil when it starts") {
                        expect(inputValue).toEventually(beNil())
                    }
                    
                }
                
            }
        }
    }
}
