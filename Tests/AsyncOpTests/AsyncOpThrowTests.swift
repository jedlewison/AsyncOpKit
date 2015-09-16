import Foundation
import Quick
import Nimble
@testable import AsyncOpKit

private enum TestError : ErrorType {
    case UnusedError
    case ThrewInClosure
}

class AsyncOpThrowingTests : QuickSpec {

    var operationQueue = NSOperationQueue()

    override func spec() {

        describe("An Async operation throwing an error from its onStart closure") {

            let subject = AsyncOp<AsyncVoid, Bool>()
            let thrownError = TestError.ThrewInClosure

            subject.onStart { operation in
                usleep(5000)
                throw thrownError
            }

            subject.onCancel { operation in
                operation.finish(with: .None(.Cancelled))
            }

            subject.whenFinished { operation in
                print(operation.output)
            }

            let opQ = NSOperationQueue()
            opQ.addOperations([subject], waitUntilFinished: false)

            it("should eventually have a failed output") {
                expect(subject.output.noneError?.failed).toEventually(equal(true))
            }

            it("the output should eventually be the thrown error") {
                expect(subject.output.noneError?.failureError?._code).toEventually(equal(thrownError._code))
            }

        }

    }
}
