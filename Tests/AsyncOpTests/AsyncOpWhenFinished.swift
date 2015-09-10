import Foundation
import Quick
import Nimble
@testable import AsyncOpKit


class AsyncOpWhenFinished : QuickSpec {


    override func spec() {


        var randomOutputNumber = 0
        var outputValue: Int?

        describe("whenFinished") {

            beforeEach {
                randomOutputNumber = random()
            }


            context("whenFinished set before the operation starts") {

                beforeEach {
                    let subject = AsyncOp<AsyncVoid, Int>()

                    subject.onStart { operation in
                        operation.finish(with: .Some(randomOutputNumber))
                    }

                    subject.whenFinished { operation in
                        outputValue = operation.output.value
                    }

                    let opQ = NSOperationQueue()
                    opQ.addOperations([subject], waitUntilFinished: false)
                }

                it("should eventually have a output equal to randomOutputNumber") {
                    expect(outputValue).toEventually(equal(randomOutputNumber))
                }

            }

            context("whenFinished closure set after the operation is added to a queue") {

                beforeEach {
                    let subject = AsyncOp<AsyncVoid, Int>()

                    subject.onStart { operation in
                        operation.finish(with: .Some(randomOutputNumber))
                    }

                    let opQ = NSOperationQueue()
                    opQ.addOperations([subject], waitUntilFinished: false)
                    opQ.addOperationWithBlock {
                        subject.whenFinished { operation in
                            outputValue = operation.output.value
                        }
                        
                    }
                    
                }

                it("should eventually have a output equal to randomOutputNumber") {
                    expect(outputValue).toEventually(equal(randomOutputNumber))
                }

            }

            context("whenFinished closure set after the operation has finished and its queue has deallocated") {

                beforeEach {

                    let subject = AsyncOp<AsyncVoid, Int>()

                    subject.onStart { operation in
                        operation.finish(with: .Some(randomOutputNumber))
                    }


                    var opQ = NSOperationQueue()
                    opQ.addOperations([subject], waitUntilFinished: true)
                    opQ = NSOperationQueue()

                    opQ.addOperationWithBlock {
                        subject.whenFinished { operation in
                            outputValue = operation.output.value
                        }
                        
                    }


                }

                it("should eventually have a output equal to randomOutputNumber") {
                    expect(outputValue).toEventually(equal(randomOutputNumber))
                }
                
            }
        }
    }
}
