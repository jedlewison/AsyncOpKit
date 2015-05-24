import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncOpTests: QuickSpec {

    override func spec() {

        describe("Starting an AsyncOperation") {

            var subject : JDAsyncOperation! = nil

            beforeEach {
                subject = JDAsyncOperation()
            }

            context("when it starts normally") {

                beforeEach {
                    subject.start()
                }

                it("should turn to the executing state immediately after being started") {
                    expect(subject.executing).to(beTrue())
                }

            }

            context("when it is canceled before starting") {

                beforeEach {
                    subject.cancel()
                    subject.start()
                }

                it("should be cancelled") {
                    expect(subject.cancelled).to(beTrue())
                }

                it("should be finished") {
                    expect(subject.finished).to(beTrue())
                }

                it("should stop executing") {
                    expect(subject.executing).to(beFalse())
                }

            }

            context("when an operation finishes normally") {

                beforeEach {
                    subject.start()
                    subject.finish()
                }

                it("should not be cancelled") {
                    expect(subject.cancelled).to(beFalse())
                }

                it("should be finished") {
                    expect(subject.finished).to(beTrue())
                }

                it("should stop executing") {
                    expect(subject.executing).to(beFalse())
                }

            }

            context("when an operation is started after being finished") {

                beforeEach {
                    subject.start()
                    subject.finish()
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
                    subject.start()
                    subject.cancel()
                }

                it("should immediatelhy be marked as cancelled") {
                    expect(subject.cancelled).to(beTrue())
                }

                it("should still be executing") {
                    expect(subject.finished).to(beTrue())
                }
            }

        }
    }
}