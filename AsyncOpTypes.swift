//
//  AsyncOpTypes.swift
//
//  Created by Jed Lewison
//  Copyright (c) 2015 Magic App Factory. MIT License.

import Foundation

public enum AsyncOpResult<ValueType> {

    case Succeeded(ValueType)
    case failed(ErrorProtocol)
    case cancelled

    init(asyncOpValue: AsyncOpValue<ValueType>) {
        switch asyncOpValue {
        case .some(let value):
            self = .Succeeded(value)
        case .none(let asyncOpError):
            switch asyncOpError {
            case .noValue:
                self = .failed(AsyncOpError.noResultBecauseOperationNotFinished)
            case .Cancelled:
                self = .cancelled
            case .Failed(let error):
                self = .failed(error)
            }
        }
    }

    var succeeded: Bool {
        switch self {
        case .Succeeded:
            return true
        default:
            return false
        }
    }
}

extension AsyncOp {

    public var result: AsyncOpResult<OutputType> {
        return AsyncOpResult(asyncOpValue: output)
    }

}

public protocol AsyncVoidConvertible: NilLiteralConvertible {
    init(asyncVoid: AsyncVoid)
}

extension AsyncVoidConvertible {
    public init(nilLiteral: ()) {
        self.init(asyncVoid: .void)
    }
}

public enum AsyncVoid: AsyncVoidConvertible {
    case void
    public init(asyncVoid: AsyncVoid) {
        self = .void
    }
}

public protocol AsyncOpResultStatusProvider {
    var resultStatus: AsyncOpResultStatus { get }
}

public enum AsyncOpResultStatus {
    case pending
    case succeeded
    case cancelled
    case failed
}

public protocol AsyncOpInputProvider {
    associatedtype ProvidedInputValueType
    func provideAsyncOpInput() -> AsyncOpValue<ProvidedInputValueType>
}

public enum AsyncOpValue<ValueType>: AsyncOpInputProvider {
    case none(AsyncOpValueErrorType)
    case some(ValueType)

    public typealias ProvidedInputValueType = ValueType
    public func provideAsyncOpInput() -> AsyncOpValue<ProvidedInputValueType> {
        return self
    }
}

public enum AsyncOpValueErrorType: ErrorProtocol {
    case noValue
    case Cancelled
    case Failed(ErrorProtocol)
}

extension AsyncOpValue {

    public func getValue() throws -> ValueType {
        switch self {
        case .none:
            throw AsyncOpValueErrorType.noValue
        case .some(let value):
            return value
        }
    }

    public var value: ValueType? {
        switch self {
        case .none:
            return nil
        case .some(let value):
            return value
        }
    }

    public var noneError: AsyncOpValueErrorType? {
        switch self {
        case .none(let error):
            return error
        case .some:
            return nil
        }
    }

}

extension AsyncOpValueErrorType {

    public var cancelled: Bool {
        switch self {
        case .Cancelled:
            return true
        default:
            return false
        }
    }

    public var failed: Bool {
        switch self {
        case .Failed:
            return true
        default:
            return false
        }
    }

    public var failureError: ErrorProtocol? {
        switch self {
        case .Failed(let error):
            return error
        default:
            return nil
        }
    }

}

public enum AsyncOpError: ErrorProtocol {
    case unspecified
    case noResultBecauseOperationNotFinished
    case unimplementedOperation
    case multiple([ErrorProtocol])
    case preconditionFailure
}

public enum AsyncOpPreconditionInstruction {
    case `continue`
    case cancel
    case fail(ErrorProtocol)

    init(errors: [ErrorProtocol]) {
        if errors.count == 1 {
            self = .fail(errors[0])
        } else {
            self = .fail(AsyncOpError.multiple(errors))
        }
    }
}
