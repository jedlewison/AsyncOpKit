//
//  AsyncOpGroup.swift
//  AsyncOpKit
//
//  Created by Jed Lewison on 9/30/15.
//  Copyright © 2015 Magic App Factory. All rights reserved.
//

import Foundation

public struct AsyncOpConnector<InputType, OutputType> {

    private let _asyncOpGroup: AsyncOpGroup
    private let _asyncOp: AsyncOp<InputType, OutputType>

    public func then<ValueType>(@noescape _ anOperationProvider: () -> AsyncOp<OutputType, ValueType>) -> AsyncOpConnector<OutputType, ValueType> {

        let op = anOperationProvider()
        op.setInputProvider(_asyncOp)
        op.addPreconditionEvaluator { [weak op] in
            guard let op = op else { return .cancel }
            switch op.input {
            case .some:
                return .continue
            case .none(let asyncOpValueError):
                switch asyncOpValueError {
                case .noValue, .Cancelled:
                    return .cancel
                case .Failed(let error):
                    return .fail(error)
                }
            }
        }
        return _asyncOpGroup.then(op)
    }

    public func finally(_ handler: (result: AsyncOpResult<OutputType>) -> ()) -> AsyncOpGroup {
        let op = operationToProvideResults()
        op.setInputProvider(_asyncOp)
        op.whenFinished { (asyncOp) -> Void in
            handler(result: op.result)
        }
        return _asyncOpGroup.finally(op)
    }

    private func operationToProvideResults() -> AsyncOp<OutputType, OutputType> {
        let op = AsyncOp<OutputType, OutputType>()
        op.onStart { asyncOp in
            asyncOp.finish(with: asyncOp.input)
        }
        return op
    }

}

public class AsyncOpGroup {

    public init() {

    }

    public func beginWith<InputType, OutputType>(@noescape _ anAsyncOpProvider: () -> AsyncOp<InputType, OutputType>) -> AsyncOpConnector<InputType, OutputType> {
        let op = anAsyncOpProvider()
        operations.append(op)
        return AsyncOpConnector<InputType, OutputType>(_asyncOpGroup: self, _asyncOp: op)
    }

    private var operations = [Operation]()


    public func cancelGroup() {
        operations.forEach { $0.cancel() }
    }

    private func then<ValueType, OutputType>(_ operation: AsyncOp<OutputType, ValueType>) -> AsyncOpConnector<OutputType, ValueType> {
        operations.append(operation)
        return AsyncOpConnector<OutputType, ValueType>(_asyncOpGroup: self, _asyncOp: operation)
    }

    private func finally<InputType, OutputType>(_ operation: AsyncOp<InputType, OutputType>) -> AsyncOpGroup {
        operations.append(operation)
        return self
    }

}

extension OperationQueue {
    public func addAsyncOpGroup(_ asyncOpGroup: AsyncOpGroup?, waitUntilFinished: Bool = false) {
        guard let asyncOpGroup = asyncOpGroup else { return }
        addOperations(asyncOpGroup.operations, waitUntilFinished: waitUntilFinished)
    }
}


