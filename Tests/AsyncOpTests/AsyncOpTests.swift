import Foundation
import Quick
import Nimble
@testable import AsyncOpKit

class AsyncOpTests : QuickSpec {

    override func spec() {

        describe("An Async operation avoiding a retain cycle") {

            let subject = AsyncOp<AsyncVoid, Bool>()

            subject.onStart { operation in
                usleep(50000)
                operation.finish(with: .Some(true))
            }

            subject.onCancel { operation in
                operation.finish(with: .None(.Cancelled))
            }

            subject.whenFinished { operation in
                print(operation.output)
            }

            let opQ = NSOperationQueue()
            opQ.addOperations([subject], waitUntilFinished: true)

            it("should let you reference the operation inside the closure without a retain cycle") {
                [weak subject] in
                expect(subject).toEventually(beNil())
            }

        }

        describe("The behavior of an AsyncOp when added to an operation queue") {

            var opQ = NSOperationQueue()
            var subject: AsyncOp<AsyncVoid, Bool>?
            var output: AsyncOpValue<Bool>?
            var onStartHandlerCalled = false
            var cancelHandlerCalled = false

            beforeEach {


                onStartHandlerCalled = false
                cancelHandlerCalled = false

                subject = AsyncOp<AsyncVoid, Bool>()
                opQ.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
                cancelHandlerCalled = false

                subject?.onStart { operation in
                    onStartHandlerCalled = true
                    usleep(5000)
                    operation.finish(with: .Some(true))
                }

                subject?.onCancel { operation in
                    cancelHandlerCalled = true
                    operation.finish(with: .None(.Cancelled))
                }

                subject?.whenFinished { operation in
                    output = operation.output
                }

            }

            afterEach {
                opQ = NSOperationQueue()
                output = nil
            }

            describe("asynchronously after adding to operation queue") {

                beforeEach {
                    guard let subject = subject else { return }
                    opQ.addOperation(subject)
                }

                it("the operation should eventually deinit") {
                    [weak subject] in
                    expect(subject).toEventually(beNil())
                }

                it("should stop executing") {

                    expect(subject?.executing).toEventually(beFalse())
                }

                it("should finish") {
                    expect(subject?.finished).toEventually(beTrue())
                }

                it("should execute its outputs handler") {
                    expect(output).toEventuallyNot(beNil())
                }

                it("should return a outputs object that does not indicate it is canceled") {
                    expect(subject?.cancelled).toEventually(beFalse())
                }
            }

            context("when an operation finishes normally") {

                beforeEach {
                    guard let subject = subject else { return }
                    opQ.addOperation(subject)
                }

                it("should not be cancelled") {
                    expect(subject?.cancelled).toEventuallyNot(beTrue())
                }

                it("should eventually be finished") {
                    expect(subject?.finished).toEventually(beTrue())
                }

                it("should not be executing") {
                    expect(subject?.executing).toEventually(beFalse())
                }

                it("the operation should finish and eventually deinit") {
                    [weak subject] in
                    expect(subject).toEventually(beNil())
                }



            }

            context("When the operation's operation queue immediately cancels all operations") {

                beforeEach {
                    guard let subject = subject else { return }
                    opQ.maxConcurrentOperationCount = 1
                    let blockOp = NSBlockOperation {
                        usleep(32033)
                    }
                    subject.addDependency(blockOp)
                    opQ.addOperations([blockOp, subject], waitUntilFinished: false)
                    opQ.cancelAllOperations()
                }

                it("should not receive an onstart handler callback") {
                    expect(onStartHandlerCalled).to(beFalse())
                }

                it("should receive a cancellation handler callback") {
                    expect(cancelHandlerCalled).to(beTrue())
                }

                it("should eventually be marked as cancelled") {
                    expect(subject?.cancelled).toEventually(beTrue())
                }

                it("should eventually stop executing and finish") {
                    expect(subject?.executing).toEventually(beFalse())
                }
                
                it("the outputs closure outputs object should mark it as cancelled") {
                    expect(subject?.cancelled).toEventually(beTrue())
                }
                
                it("the operation should eventually deinit") {
                    [weak subject] in
                    expect(subject).toEventually(beNil())
                }

            }
            
        }
        
    }
}
