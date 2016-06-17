//
//  AsyncOp.swift
//
//  Created by Jed Lewison
//  Copyright (c) 2015 Magic App Factory. MIT License.

import Foundation

/// AsyncOp is an NSOperation subclass that supports a generic output type and takes care of the boiler plate necessary for asynchronous execution of NSOperations.
/// You can subclass AsyncOp, but because it's a generic subclass and provides convenient closures for performing work as well has handling cancellation, results, and errors, in many cases you may not need to.

public class AsyncOp<InputType, OutputType>: Operation {

    @nonobjc public required override init() {
        super.init()
    }

    public var input: AsyncOpValue<InputType> {
        get {
            return _input
        }
        set {
            guard state == .initial else { debugPrint(WarnSetInput); return }
            _input = newValue
        }
    }

    public private(set) final var output: AsyncOpValue<OutputType> = .none(.noValue)

    // Closures
    public typealias AsyncOpClosure = (asyncOp: AsyncOp<InputType, OutputType>) -> Void
    public typealias AsyncOpThrowingClosure = (asyncOp: AsyncOp<InputType, OutputType>) throws -> Void
    public typealias AsyncOpPreconditionEvaluator = () throws -> AsyncOpPreconditionInstruction

    // MARK: Implementation details
    override public final func start() {
        state = .executing
        if !isCancelled {
            main()
        } else {
            preconditionEvaluators.removeAll()
            implementationHandler = nil
            finish(with: .none(.Cancelled))
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

            var errors = [ErrorProtocol]()
            var preconditionInstruction = AsyncOpPreconditionInstruction.continue

            for evaluator in preconditionEvaluators {
                do {
                    let evaluatorInstruction = try evaluator()
                    switch evaluatorInstruction {
                    case .cancel where errors.count == 0:
                        preconditionInstruction = .cancel
                    case .fail(let error):
                        errors.append(error)
                        preconditionInstruction = AsyncOpPreconditionInstruction(errors: errors)
                    case .continue, .cancel:
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
                finish(with: AsyncOpError.unimplementedOperation)
            }
        }

        // The actual implementation
        autoreleasepool {
            main_prepareInput()
            switch main_evaluatePreconditions() {
            case .continue:
                main_performImplementation() // happy path
            case .cancel:
                implementationHandler = nil
                cancel()
                finish(with: .Cancelled)
            case .fail(let error):
                cancel()
                implementationHandler = nil
                finish(with: error)
            }
        }
    }

    override public final func cancel() {
        performOnce(onceAction: .cancel) {
            super.cancel()
            self.cancellationHandler?(asyncOp: self)
            self.cancellationHandler = nil
        }
    }

    public private(set) final var paused: Bool = false {
        willSet {
            guard state == .initial else { return }
            if paused != newValue {
                willChangeValue(forKey: "isReady")
            }
        }
        didSet {
            guard state == .initial else { return }
            if paused != oldValue {
                didChangeValue(forKey: "isReady")
            }
        }
    }

    private var state = AsyncOpState.initial {
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
    override public final var isAsynchronous: Bool { return true }
    override public final var isExecuting: Bool { return state == .executing }
    override public final var isFinished: Bool { return state == .finished }
    override public var isReady: Bool {
        guard state == .initial else { return true }
        guard super.isReady else { return false }
        return !paused
    }

    // MARK: Private storage
    private typealias AsyncInputRequest = () -> AsyncOpValue<InputType>
    private var handlerForAsyncOpInputRequest: AsyncInputRequest?
    private var preconditionEvaluators = [AsyncOpPreconditionEvaluator]()
    private var implementationHandler: AsyncOpThrowingClosure?
    private var completionHandler: AsyncOpClosure?
    private var completionHandlerQueue: OperationQueue?
    private var cancellationHandler: AsyncOpClosure?

    // Convenience for performing cancel and finish actions once
    private var onceGuards: [OnceAction : Bool] = Dictionary(minimumCapacity: OnceAction.count)
    private let performOnceGuardQ = QualityOfService.userInitiated.createSerialDispatchQueue("asyncOpKit.performOnceGuardQ")
    private func performOnce(onceAction: OnceAction, @noescape action: () -> ()) {
        var canPerformAction: Bool?
        performOnceGuardQ.sync {
            canPerformAction = self.onceGuards[onceAction] ?? true
            self.onceGuards[onceAction] = false
        }

        if canPerformAction == true {
            action()
        }

    }
    private var _input: AsyncOpValue<InputType> = AsyncOpValue.none(.noValue)

}

extension AsyncOp {

    public func onStart(_ implementationHandler: AsyncOpThrowingClosure) {
        guard state == .initial else { return }
        self.implementationHandler = implementationHandler
    }

    public func whenFinished(whenFinishedQueue completionHandlerQueue: OperationQueue = OperationQueue.main(), completionHandler: AsyncOpClosure) {

        performOnce(onceAction: .whenFinished) {
            guard self.completionHandler == nil else { return }
            if self.isFinished {
                completionHandlerQueue.addOperation {
                    completionHandler(asyncOp: self)
                }
            } else {
                self.completionHandlerQueue = completionHandlerQueue
                self.completionHandler = completionHandler
            }
        }
    }

    public func onCancel(_ cancellationHandler: AsyncOpClosure) {
        guard state == .initial else { return }
        self.cancellationHandler = cancellationHandler
    }

}

extension AsyncOp where OutputType: AsyncVoidConvertible {

    public final func finishWithSuccess() {
        finish(with: .some(OutputType(asyncVoid: .void)))
    }

}

// MARK: Functions for finishing operation
extension AsyncOp {

    public final func finish(with value: OutputType) {
        finish(with: .some(value))
    }

    public final func finish(with asyncOpValueError: AsyncOpValueErrorType) {
        finish(with: .none(asyncOpValueError))
    }

    public final func finish(with failureError: ErrorProtocol) {
        finish(with: .none(.Failed(failureError)))
    }

    public final func finish(with asyncOpValue: AsyncOpValue<OutputType>) {
        guard isExecuting else { return }
        performOnce(onceAction: .finish) {

            self.output = asyncOpValue
            self.state = .finished
            guard let completionHandler = self.completionHandler else { return }
            self.completionHandler = nil
            self.implementationHandler = nil
            self.cancellationHandler = nil
            self.handlerForAsyncOpInputRequest = nil
            self.preconditionEvaluators.removeAll()
            guard let completionHandlerQueue = self.completionHandlerQueue else { return }
            self.completionHandlerQueue = nil
            completionHandlerQueue.addOperation {
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

    public func addPreconditionEvaluator(_ evaluator: AsyncOpPreconditionEvaluator) {
        guard state == .initial else { debugPrint(WarnSetInput); return }
        preconditionEvaluators.append(evaluator)
    }

    public func setInputProvider<T where T: AsyncOpInputProvider, T.ProvidedInputValueType == InputType>(_ inputProvider: T) {
        guard state == .initial else { debugPrint(WarnSetInput); return }
        if let inputProvider = inputProvider as? Operation {
            addDependency(inputProvider)
        }
        handlerForAsyncOpInputRequest = inputProvider.provideAsyncOpInput
    }

    public typealias ProvidedInputValueType = OutputType
    public func provideAsyncOpInput() -> AsyncOpValue<OutputType> {
        return output
    }

    public func setInput(_ value: InputType, andResume resume: Bool = false) {
        setInput(AsyncOpValue.some(value), andResume: resume)
    }

    public func setInput(_ input: AsyncOpValue<InputType>, andResume resume: Bool = false) {
        guard state == .initial else { debugPrint(WarnSetInput); return }
        self.input = input
        if resume {
            self.resume()
        }
    }

}

extension AsyncOp {

    public var resultStatus: AsyncOpResultStatus {
        guard state == .finished else { return .pending }
        guard !isCancelled else { return .cancelled }
        switch output {
        case .none:
            return .failed
        case .some:
            return .succeeded
        }
    }

}

private extension AsyncOp {

    func willChangeValueForState(_ state: AsyncOpState) {
        guard let key = state.key else { return }
        willChangeValue(forKey: key)
    }

    func didChangeValueForState(_ state: AsyncOpState) {
        guard let key = state.key else { return }
        didChangeValue(forKey: key)
    }

}

private let WarnSetInput = "Setting input without manual mode automatic or when operation has started has no effect"

private enum AsyncOpState {
    case initial
    case executing
    case finished

    var key: String? {
        switch self {
        case .executing:
            return "isExecuting"
        case .finished:
            return "isFinished"
        case .initial:
            return nil
        }
    }
}

private enum OnceAction: Int {
    case whenFinished
    case finish
    case cancel
    static let count = 3
}
