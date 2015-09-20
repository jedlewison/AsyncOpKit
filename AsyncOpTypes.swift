//
//  AsyncOpTypes.swift
//
//  Created by Jed Lewison
//  Copyright (c) 2015 Magic App Factory. MIT License.

import Foundation

public protocol AsyncVoidConvertible: NilLiteralConvertible {
    init(asyncVoid: AsyncVoid)
}

extension AsyncVoidConvertible {
    public init(nilLiteral: ()) {
        self.init(asyncVoid: .Void)
    }
}

public enum AsyncVoid: AsyncVoidConvertible {
    case Void
    public init(asyncVoid: AsyncVoid) {
        self = .Void
    }
}

public protocol AsyncOpResultStatusProvider {
    var resultStatus: AsyncOpResultStatus { get }
}

public enum AsyncOpResultStatus {
    case Pending
    case Succeeded
    case Cancelled
    case Failed
}

public protocol AsyncOpInputProvider {
    typealias ProvidedInputValueType
    func provideAsyncOpInput() -> AsyncOpValue<ProvidedInputValueType>
}

public enum AsyncOpValue<ValueType>: AsyncOpInputProvider {
    case None(AsyncOpValueErrorType)
    case Some(ValueType)

    public typealias ProvidedInputValueType = ValueType
    public func provideAsyncOpInput() -> AsyncOpValue<ProvidedInputValueType> {
        return self
    }
}

public enum AsyncOpValueErrorType: ErrorType {
    case Nil
    case Cancelled
    case Failed(ErrorType)
}

extension AsyncOpValue {

    public func getValue() throws -> ValueType {
        switch self {
        case .None:
            throw AsyncOpValueErrorType.Nil
        case .Some(let value):
            return value
        }
    }

    public var value: ValueType? {
        switch self {
        case .None:
            return nil
        case .Some(let value):
            return value
        }
    }

    public var noneError: AsyncOpValueErrorType? {
        switch self {
        case .None(let error):
            return error
        case .Some:
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

    public var failureError: ErrorType? {
        switch self {
        case .Failed(let error):
            return error
        default:
            return nil
        }
    }
    
}

public enum AsyncOpError: ErrorType {
    case Unspecified
    case UnimplementedOperation
    case Multiple([ErrorType])
    case PreconditionFailure
}

public enum AsyncOpPreconditionInstruction {
    case Continue
    case Cancel
    case Fail(ErrorType)

    init(errors: [ErrorType]) {
        if errors.count == 1 {
            self = .Fail(errors[0])
        } else {
            self = .Fail(AsyncOpError.Multiple(errors))
        }
    }
}
