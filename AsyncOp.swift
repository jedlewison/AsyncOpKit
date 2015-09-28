//
//  AsyncOp.swift
//
//  Created by Jed Lewison
//  Copyright (c) 2015 Magic App Factory. MIT License.

import Foundation

/// AsyncOp is an NSOperation subclass that supports a generic output type and takes care of the boiler plate necessary for asynchronous execution of NSOperations.
/// You can subclass AsyncOp, but because it's a generic subclass and provides convenient closures for performing work as well has handling cancellation, results, and errors, in many cases you may not need to.

public class AsyncOp<InputType, OutputType>: NSOperation {

    @nonobjc public required override init() {
        super.init()
    }

    public var input: AsyncOpValue<InputType> {
        get {
            return _input
        }
        set {
            guard state == .Initial else { debugPrint(WarnSetInput); return }
            _input = newValue
        }
    }

    public private(set) final var output: AsyncOpValue<OutputType> = .None(.Nil)

    // Closures
    public typealias AsyncOpClosure = (asyncOp: AsyncOp<InputType, OutputType>) -> Void
    public typealias AsyncOpThrowingClosure = (asyncOp: AsyncOp<InputType, OutputType>) throws -> Void
    public typealias AsyncOpPreconditionEvaluator = () throws -> AsyncOpPreconditionInstruction

    // MARK: Implementation details
    override public final func start() {
        state = .Executing
        if !cancelled {
            main()
        } else {
            preconditionEvaluators.removeAll()
            implementationHandler = nil
            finish(with: .None(.Cancelled))
        }
    }

    override public final func main() {
        // Helper functions to decompose the work
        func main_prepareInput() {
            if let handlerForAsyncOpInputRequest = handlerForAsyncOpInputRequest {
                _input = handlerForAsyncOpInputRequest()
                self.handlerForAsyncOpInputRequest = nil
            }
        }

        func main_evaluatePreconditions() -> AsyncOpPreconditionInstruction {

            var errors = [ErrorType]()
            var preconditionInstruction = AsyncOpPreconditionInstruction.Continue

            for evaluator in preconditionEvaluators {
                do {
                    let evaluatorInstruction = try evaluator()
                    switch evaluatorInstruction {
                    case .Cancel where errors.count == 0:
                        preconditionInstruction = .Cancel
                    case .Fail(let error):
                        errors.append(error)
                        preconditionInstruction = AsyncOpPreconditionInstruction(errors: errors)
                    case .Continue, .Cancel:
                        break
                    }
                } catch {
                    errors.append(error)
                    preconditionInstruction = AsyncOpPreconditionInstruction(errors: errors)
                }
            }

            preconditionEvaluators.removeAll()

            return preconditionInstruction
        }

        func main_performImplementation() {
            if let implementationHandler = self.implementationHandler {
                self.implementationHandler = nil
                do {
                    try implementationHandler(asyncOp: self)
                } catch {
                    finish(with: error)
                }
            } else {
                finish(with: AsyncOpError.UnimplementedOperation)
            }
        }

        // The actual implementation
        autoreleasepool {
            main_prepareInput()
            switch main_evaluatePreconditions() {
            case .Continue:
                main_performImplementation() // happy path
            case .Cancel:
                implementationHandler = nil
                cancel()
                finish(with: .Cancelled)
            case .Fail(let error):
                cancel()
                implementationHandler = nil
                finish(with: error)
            }
        }
    }

    override public final func cancel() {
        dispatch_once(&cancelOnceToken) {
            super.cancel()
            self.cancellationHandler?(asyncOp: self)
            self.cancellationHandler = nil
        }
    }

    public private(set) final var paused: Bool = false {
        willSet {
            guard state == .Initial else { return }
            if paused != newValue {
                willChangeValueForKey("isReady")
            }
        }
        didSet {
            guard state == .Initial else { return }
            if paused != oldValue {
                didChangeValueForKey("isReady")
            }
        }
    }

    private var state = AsyncOpState.Initial {
        willSet {
            if newValue != state {
                willChangeValueForState(newValue)
                willChangeValueForState(state)
            }
        }
        didSet {
            if oldValue != state {
                didChangeValueForState(oldValue)
                didChangeValueForState(state)
            }
        }
    }

    /// Overrides for required NSOperation properties
    override public final var asynchronous: Bool { return true }
    override public final var executing: Bool { return state == .Executing }
    override public final var finished: Bool { return state == .Finished }
    override public var ready: Bool { return !paused && super.ready || state != .Initial }

    // MARK: Private storage
    private typealias AsyncInputRequest = () -> AsyncOpValue<InputType>
    private var handlerForAsyncOpInputRequest: AsyncInputRequest?
    private var preconditionEvaluators = [AsyncOpPreconditionEvaluator]()
    private var implementationHandler: AsyncOpThrowingClosure?
    private var completionHandler: AsyncOpClosure?
    private var completionHandlerQueue: NSOperationQueue?
    private var cancellationHandler: AsyncOpClosure?
    private var finishOnceToken: dispatch_once_t = 0
    private var whenFinishedOnceToken: dispatch_once_t = 0
    private var cancelOnceToken: dispatch_once_t = 0
    private var _input: AsyncOpValue<InputType> = AsyncOpValue.None(.Nil)

}

extension AsyncOp {

    public func onStart(implementationHandler: AsyncOpThrowingClosure) {
        guard state == .Initial else { return }
        self.implementationHandler = implementationHandler
    }

    public func whenFinished(whenFinishedQueue completionHandlerQueue: NSOperationQueue = NSOperationQueue.mainQueue(), completionHandler: AsyncOpClosure) {
        dispatch_once(&whenFinishedOnceToken) {
            guard self.completionHandler == nil else { return }
            if self.finished {
                completionHandlerQueue.addOperationWithBlock {
                    completionHandler(asyncOp: self)
                }
            } else {
                self.completionHandlerQueue = completionHandlerQueue
                self.completionHandler = completionHandler
            }
        }
    }

    public func onCancel(cancellationHandler: AsyncOpClosure) {
        guard state == .Initial else { return }
        self.cancellationHandler = cancellationHandler
    }

}

extension AsyncOp where OutputType: AsyncVoidConvertible {

    public final func finishWithSuccess() {
        finish(with: .Some(OutputType(asyncVoid: .Void)))
    }

}

// MARK: Functions for finishing operation
extension AsyncOp {

    public final func finish(with value: OutputType) {
        finish(with: .Some(value))
    }

    public final func finish(with asyncOpValueError: AsyncOpValueErrorType) {
        finish(with: .None(asyncOpValueError))
    }

    public final func finish(with failureError: ErrorType) {
        finish(with: .None(.Failed(failureError)))
    }

    public final func finish(with asyncOpValue: AsyncOpValue<OutputType>) {
        guard executing else { return }
        dispatch_once(&finishOnceToken) {
            self.output = asyncOpValue
            self.state = .Finished
            guard let completionHandler = self.completionHandler else { return }
            self.completionHandler = nil
            self.implementationHandler = nil
            self.cancellationHandler = nil
            self.handlerForAsyncOpInputRequest = nil
            self.preconditionEvaluators.removeAll()
            guard let completionHandlerQueue = self.completionHandlerQueue else { return }
            self.completionHandlerQueue = nil
            completionHandlerQueue.addOperationWithBlock {
                completionHandler(asyncOp: self)
            }
        }
    }
    
}

extension AsyncOp {

    /// Has no effect on operation readiness once it begins executing
    public final func pause() {
        paused = true
    }

    /// Has no effect on operation readiness once it begins executing
    public final func resume() {
        paused = false
    }

}

extension AsyncOp: AsyncOpInputProvider {

    public func addPreconditionEvaluator(evaluator: AsyncOpPreconditionEvaluator) {
        guard state == .Initial else { debugPrint(WarnSetInput); return }
        preconditionEvaluators.append(evaluator)
    }

    func preconditionInstructionByEvaluatingOutput() throws -> AsyncOpPreconditionInstruction {
        switch output {
        case .None(let error):
            switch error {
            case .Cancelled, .Nil:
                return .Cancel
            case .Failed(let error):
                return .Fail(error)
            }
        case .Some:
            return .Continue
        }
    }

    public func setInputProvider<T where T: AsyncOpInputProvider, T.ProvidedInputValueType == InputType>(inputProvider: T) {
        guard state == .Initial else { debugPrint(WarnSetInput); return }
        if let inputProvider = inputProvider as? NSOperation {
            addDependency(inputProvider)
        }
        handlerForAsyncOpInputRequest = inputProvider.provideAsyncOpInput
    }

    public typealias ProvidedInputValueType = OutputType
    public func provideAsyncOpInput() -> AsyncOpValue<OutputType> {
        return output
    }

    public func setInput(value: InputType, andResume resume: Bool = false) {
        setInput(AsyncOpValue.Some(value), andResume: resume)
    }

    public func setInput(input: AsyncOpValue<InputType>, andResume resume: Bool = false) {
        guard state == .Initial else { debugPrint(WarnSetInput); return }
        self.input = input
        if resume {
            self.resume()
        }
    }

}

extension AsyncOp {

    public var resultStatus: AsyncOpResultStatus {
        guard state == .Finished else { return .Pending }
        guard !cancelled else { return .Cancelled }
        switch output {
        case .None:
            return .Failed
        case .Some:
            return .Succeeded
        }
    }

}

private extension AsyncOp {

    func willChangeValueForState(state: AsyncOpState) {
        guard let key = state.key else { return }
        willChangeValueForKey(key)
    }

    func didChangeValueForState(state: AsyncOpState) {
        guard let key = state.key else { return }
        didChangeValueForKey(key)
    }
    
}

private let WarnSetInput = "Setting input without manual mode automatic or when operation has started has no effect"

private enum AsyncOpState {
    case Initial
    case Executing
    case Finished
    
    var key: String? {
        switch self {
        case .Executing:
            return "isExecuting"
        case .Finished:
            return "isFinished"
        case .Initial:
            return nil
        }
    }
}
