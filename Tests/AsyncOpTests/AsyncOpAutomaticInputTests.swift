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

class AClassInputProvider: AsyncOpInputProvider {
    let asyncOpInput: AsyncOpValue<Int>
    init (asyncOpInput: AsyncOpValue<Int>) {
        self.asyncOpInput = asyncOpInput
    }

    func provideAsyncOpInput() -> AsyncOpValue<Int> {
        return asyncOpInput
    }
}


class AsyncOpAutomaticInputTests : QuickSpec, AsyncOpInputProvider {

    var randomOutputNumber = random()

    override func spec() {

        var randomOutputNumber: Int!

        beforeEach {
            self.randomOutputNumber = random()
            randomOutputNumber = self.randomOutputNumber
        }

        describe("Using another async operation to provide input") {

            var subject: AsyncOp<Int, Int>!
            var inputProvider: AsyncOp<AsyncVoid, Int>!
            var inputValue: Int?
            var opQ: NSOperationQueue!

            beforeEach {
                opQ = NSOperationQueue()
                opQ.maxConcurrentOperationCount = 1
                subject = AsyncOp()
                inputProvider = AsyncOp()
                inputProvider.onStart { operation in
                    operation.finish(with: .Some(randomOutputNumber))
                }

                inputValue = nil
                subject.setInputProvider(inputProvider)

                subject.onStart { operation in
                    guard let outValue = operation.input.value else { throw AsyncOpError.Unspecified }
                    inputValue = outValue
                    operation.finish(with: .Some(outValue))
                }
            }

            context("The input provider is added to the operation queue before the subject") {

                beforeEach {
                    opQ.addOperation(inputProvider)
                    opQ.addOperation(subject)
                }

                it("should start with an input of randomOutputNumber") {
                    expect(inputValue).toEventually(equal(randomOutputNumber))
                }
            }

            context("The subject is added to the queue before the inputProvider") {

                beforeEach {
                    opQ.addOperation(subject)
                    opQ.addOperation(inputProvider)
                }

                it("should start with an input of randomOutputNumber") {
                    expect(inputValue).toEventually(equal(randomOutputNumber))
                }

            }

            context("The inputProvider is repeatedly added ") {

                beforeEach {
                    opQ.addOperation(subject)
                    subject.setInputProvider(inputProvider)
                    subject.setInputProvider(inputProvider)
                    subject.setInputProvider(inputProvider)
                    subject.setInputProvider(inputProvider)
                    opQ.addOperation(inputProvider)
                }

                it("should start with an input of randomOutputNumber") {
                    expect(inputValue).toEventually(equal(randomOutputNumber))
                }
                
            }

        }


        describe("Using an unrelated class to provide input") {

            var subject: AsyncOp<Int, Int>!
            var inputProvider: AClassInputProvider!
            var inputValue: Int?
            var opQ: NSOperationQueue!

            beforeEach {
                opQ = NSOperationQueue()
                subject = AsyncOp()
                inputProvider = AClassInputProvider(asyncOpInput: .Some(randomOutputNumber))
                inputValue = nil
                subject.onStart { operation in
                    guard let outValue = operation.input.value else { throw AsyncOpError.Unspecified }
                    inputValue = outValue
                    operation.finish(with: .Some(outValue))
                }
            }

            context("An Async operation with an input set before the operation is added to a queue") {

                beforeEach {
                    subject.setInputProvider(inputProvider)
                    opQ.addOperations([subject], waitUntilFinished: false)
                }

                it("should start with an input of randomOutputNumber") {
                    expect(inputValue).toEventually(equal(randomOutputNumber))
                }

            }
        }

        describe("Using an AsyncInput Enum to provide input") {

            var subject: AsyncOp<Int, Int>!
            var inputProvider: AsyncOpValue<Int>!
            var inputValue: Int?
            var opQ: NSOperationQueue!

            beforeEach {
                opQ = NSOperationQueue()
                subject = AsyncOp()
                inputProvider = AsyncOpValue.Some(randomOutputNumber)
                inputValue = nil
                subject.onStart { operation in
                    guard let outValue = operation.input.value else { throw AsyncOpError.Unspecified }
                    inputValue = outValue
                    operation.finish(with: .Some(outValue))
                }
            }

            context("An Async operation with an input set before the operation is added to a queue") {

                beforeEach {
                    subject.setInputProvider(inputProvider)
                    opQ.addOperations([subject], waitUntilFinished: false)
                }

                it("should start with an input of randomOutputNumber") {
                    expect(inputValue).toEventually(equal(randomOutputNumber))
                }

            }
        }

        describe("Using a function on the test class to provide input") {
            
            var subject: AsyncOp<Int, Int>!
            var inputProvider: AsyncOpAutomaticInputTests!
            var inputValue: Int?
            var opQ: NSOperationQueue!
            
            beforeEach {
                opQ = NSOperationQueue()
                subject = AsyncOp()
                inputProvider = self
                inputValue = nil
                subject.onStart { operation in
                    guard let outValue = operation.input.value else { throw AsyncOpError.Unspecified }
                    inputValue = outValue
                    operation.finish(with: .Some(outValue))
                }
            }
            
            context("An Async operation with an input set before the operation is added to a queue") {
                
                beforeEach {
                    subject.setInputProvider(inputProvider)
                    opQ.addOperations([subject], waitUntilFinished: false)
                }
                
                it("should start with an input of randomOutputNumber") {
                    expect(inputValue).toEventually(equal(randomOutputNumber))
                }
                
            }
        }
        
    }

    func provideAsyncOpInput() -> AsyncOpValue<Int> {
        return .Some(self.randomOutputNumber)
    }

}
