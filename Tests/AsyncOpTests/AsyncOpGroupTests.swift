//
//  AsyncOpGroupTests.swift
//  AsyncOpKit
//
//  Created by Jed Lewison on 9/30/15.
//  Copyright © 2015 Magic App Factory. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import AsyncOpKit



class AsyncOpGroupTests : QuickSpec {

    override func spec() {

        var opQ = NSOperationQueue()
        var asyncOpGroup = AsyncOpGroup()
        var finalResult: String?
        var cancelled = false
        var randomOutputNumber = 0
        var returnedGroup: AsyncOpGroup?

        fdescribe("asyncOpGroup") {

            beforeEach {
                randomOutputNumber = random()
                finalResult = nil
                cancelled = false
                opQ = NSOperationQueue()
                asyncOpGroup = AsyncOpGroup()
            }

            context("an async op group transforming an int to a double to a string") {

                beforeEach {

                    returnedGroup = asyncOpGroup.beginWith { () -> AsyncOp<Int, Double> in
                        let firstOp = AsyncOp<Int, Double>()
                        firstOp.setInput(randomOutputNumber)
                        firstOp.onStart({ (asyncOp) -> Void in
                            let input = try asyncOp.input.getValue()
                            asyncOp.finish(with: Double(input))
                        })
                        return firstOp
                        }.then({ () -> AsyncOp<Double, String> in
                            let secondOp = AsyncOp<Double, String>()
                            secondOp.onStart({ (asyncOp) -> Void in
                                let input = try asyncOp.input.getValue()
                                asyncOp.finish(with: String(input))
                            })

                            return secondOp
                        }).finally({ (result) -> () in
                            switch result {
                            case .Succeeded(let final):
                                finalResult = final
                            case .Cancelled:
                                cancelled = true
                            case .Failed(let error):
                                debugPrint(error)
                            }
                        })

                }

                it("should return a string version of the input") {
                    opQ.addAsyncOpGroup(returnedGroup)
                    expect(finalResult).toEventually(equal(String(Double(randomOutputNumber))))
                }

                it("should not be cancelled when the group is not cancelled") {
                    opQ.addAsyncOpGroup(returnedGroup)
                    expect(cancelled).toEventually(beFalse())
                }

                it("should be cancelled when the group is cancelled") {
                    returnedGroup?.cancelGroup()
                    opQ.addAsyncOpGroup(returnedGroup)
                    expect(cancelled).toEventually(beTrue())
                }
                
            }
        }
        
    }
    
}
