
/// Pass an AsyncClosure to a AsyncClosuresOperation to perform a potentially asynchronous work inside a closure, marking it as finished when done.
///
/// :param: closureController Use the closureController to mark the closure finished, to cancel the parent closures operation, or to check operation status.
public typealias AsyncClosure = (closureController: AsyncClosureObjectProtocol) -> Void

/// AsyncClosureObjectProtocol defines the interface for the object passed into AsyncClosures by AsyncClosuresOperations
@objc public protocol AsyncClosureObjectProtocol : NSObjectProtocol {
    /// Set a value on the AsyncClosuresOperation to pass among closures
    var value: AnyObject? {get set}
    
    /// Check if the operation is cancelled
    var isOperationCancelled: Bool { get }
    
    /// Mark the closure finished
    func finishClosure() -> Void
    
    /// Cancel the operation
    func cancelOperation() -> Void
}

/// The kind of serial operation queue the AsyncClosuresOperation should manage.
@objc public enum AsyncClosuresQueueKind: Int {
    /// Use a mainQueue operation queue
    case Main
    /// Create a background queue
    case Background
}

/// AsyncClosuresOperation manages a queue of AsyncClosure closures.

public class AsyncClosuresOperation : AsyncOperation {
    
    ///:queueKind: Whether the closures should execute on the mainQueue or a background queue.
    ///:returns: A new AsyncClosuresOperation
    @objc override public convenience init() {
        self.init(queueKind: .Main, qualityOfService: .Default)
    }
    
    @objc public convenience init(queueKind: AsyncClosuresQueueKind) {
        self.init(queueKind: queueKind, qualityOfService: .Default)
    }

    @objc public init(queueKind: AsyncClosuresQueueKind, qualityOfService: NSQualityOfService) {
        closureQueueKind = queueKind
        closureDispatchQueue = closureQueueKind.serialDispatchQueue(qualityOfService)
        
        super.init()
        self.qualityOfService = qualityOfService
    }
    
    /// Create a new AsyncClosuresOperation with a closure
    ///
    /// 1. Because the queue is performed serially, closures must be marked finished. (See addAsyncClosure).
    /// 2. Once started, an AsyncClosuresOperation will not finish until all its closures have been marked as finished, even if it has been cancelled. It is the programmer's responsibility to check for cancellation.
    /// 3. If an AsyncClosuresOperation is cancelled before it is started, its AsyncClosures will not be called.
    /// 4. For executing closures concurrently, use a concurrent operation queue with multiple AsyncClosuresOperations. You can add dependencies.
    ///
    /// :queueKind: Whether the closures should execute on the mainQueue or a background queue.
    /// :asyncClosure: The AsyncClosure.
    /// :see: addAsyncClosure.
    
    @objc public convenience init(queueKind: AsyncClosuresQueueKind, asyncClosure: AsyncClosure) {
        self.init(queueKind: queueKind, qualityOfService: .Default)
        addAsyncClosure(asyncClosure)
    }
    
    @objc class public func asyncClosuresOperation(queueKind: AsyncClosuresQueueKind, asyncClosure: AsyncClosure) -> AsyncClosuresOperation {
        return AsyncClosuresOperation(queueKind: queueKind, asyncClosure: asyncClosure)
    }
    
    /// Adds a new AsyncClosure to the AsyncClosuresOperation. Has no effect if the operation has begun executing or has already finished or been cancelled.
    /// Usage:
    ///   closuresOp.addAsyncClosure {
    ///     closureController in
    ///     if closureController.isOperationCancelled {
    ///     closureController.finishClosure()
    ///     return
    ///     }
    ///     dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
    ///     // do some async stuff and then finish
    ///     closureController.finishClosure()
    ///     }
    ///   }
    ///
    /// :param: asyncClosure The AsyncClosure to add. For the operation to proceed to
    /// the next closure or to finish, you must use asyncClosure's closureController
    /// parameter mark it as finished.
    /// :see: AsyncClosureObjectProtocol
    
    public final func addAsyncClosure(asyncClosure: AsyncClosure) {
        if executing || finished || cancelled {
            return
        }
        
        let asyncClosureOp = AsyncClosureOperation(asyncClosure: asyncClosure, masterOperation: self)
        
        if let previousOp = closures.last {
            asyncClosureOp.addDependency(previousOp)
        }
        
        closures.append(asyncClosureOp)
        
        asyncClosureOp.completionBlock = {
            if let lastOp = self.closures.last {
                if lastOp.finished {
                    self.closures.removeAll()
                    self.finish()
                }
            }
        }
    }
    
    // MARK: Private methods/properties
    private let closureQueueKind: AsyncClosuresQueueKind
    private let closureDispatchQueue: dispatch_queue_t

    private var closures = [AsyncClosureOperation]()
    
    override public func main() {
        
        self.performNextClosureOperationOrFinish()
    }
    
    private final func performNextClosureOperationOrFinish() {
        
        if let nextClosureOp = closures.first {
            closures.removeAtIndex(0)
            nextClosureOp.completionBlock = {
                self.performNextClosureOperationOrFinish()
            }
            dispatch_async(closureDispatchQueue) {
                nextClosureOp.start()                
            }
        } else {
            self.finish()
        }

    }

    internal class AsyncClosureOperation : AsyncOperation, AsyncClosureObjectProtocol {
        
        init(asyncClosure: AsyncClosure, masterOperation: AsyncClosuresOperation) {
            self.asyncClosure = asyncClosure
            self.masterOperation = masterOperation
            super.init()
        }
        
        unowned let masterOperation: AsyncClosuresOperation
        
        private var asyncClosure: AsyncClosure?
        
        override func main() {
            if let asyncClosure = asyncClosure {
                asyncClosure(closureController: self)
                self.asyncClosure = nil
            } else {
                self.finishClosure()
            }
        }
        
        var isOperationCancelled: Bool {
            return self.masterOperation.cancelled
        }
        
        func finishClosure() {
            self.finish()
        }
        
        func cancelOperation() {
            self.masterOperation.cancel()
            self.finish()
        }
        
        override var value: AnyObject? {
            get {
                return masterOperation.value
            }
            set {
                masterOperation.value = newValue
            }
        }
    }
}




extension AsyncClosuresQueueKind {
    public func serialOperationQueueForKind() -> NSOperationQueue {
        switch self {
        case .Main:
            return NSOperationQueue.mainQueue()
        case .Background:
            let serialOperationQueueForKind = NSOperationQueue()
            serialOperationQueueForKind.maxConcurrentOperationCount = 1
            return serialOperationQueueForKind
        }
    }
    public func serialDispatchQueue(qos: NSQualityOfService) -> dispatch_queue_t {
        switch self {
        case .Main:
            return dispatch_get_main_queue()
        case .Background:
            return qos.createSerialDispatchQueue("asyncClosuresOperation")
        }
    }
}
