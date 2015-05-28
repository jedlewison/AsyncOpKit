/// Use an AsyncClosuresOperation to serially run an arbitrary number of potentially asynchronous closures.
/// Although AsyncClosures can run asynchronously from the perspective of the queue or thread managing the operation, the operation object runs them serially, FIFO.
/// For concurrent AsyncClosures, create multiple AsyncClosuresOperation objects

public typealias AsyncClosure = (closureController: AsyncClosureObjectProtocol) -> Void

public enum AsyncClosuresQueueKind {
    case Main
    case Background
    
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
}

public class AsyncClosuresOperation : AsyncOperation {
    
    /// Create a new AsyncClosuresOperation with an AsyncClosure
    
    public init(queueKind: AsyncClosuresQueueKind) {
        closureOpQ = queueKind.serialOperationQueueForKind()
        super.init()
    }

    public convenience init(queueKind: AsyncClosuresQueueKind, asyncClosure: AsyncClosure) {
        self.init(queueKind: queueKind)
        addAsyncClosure(asyncClosure)
    }
    
    class public func asyncClosuresOperation(queueKind: AsyncClosuresQueueKind, asyncClosure: AsyncClosure) -> AsyncClosuresOperation {
        return AsyncClosuresOperation(queueKind: queueKind, asyncClosure: asyncClosure)
    }
    
    /// The kind of queue used for managing adding and kicking of async closures.
    


    /**
    The signature of an AsyncClosure.
    
    :param: op The AsyncClosuresOperation responsible for performing the closures
    :param: finishAsyncClosure: AsyncClosureFinishingFunction A function that will mark the asyncClosure as finished on the owning operation. This must be called in order to notify the owning operation that the closure has finished, even when operation has been cancelled. Invocations after the first are ignored.
    
    You must use the parameters to tell the operation when the closure has finished, for example:
    
    let closuresOp = AsyncClosuresOperation()
    closuresOp.addAsyncClosure {
    op, finishAsyncClosure in
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
    // do some async stuff and then finish
    finishAsyncClosure()
    }
    }
    
    You can also use the parameters to check it the operation has been cancelled:
    
    */
    
    /// Add an AsyncClosure to an AsyncClosuresOperation.
    /// See AsyncClosure documentation for usage.
    
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
    
    private let closureOpQ: NSOperationQueue
    private var closures = [AsyncClosureOperation]()
    
    // MARK: Private methods/properties
    
    override public func main() {
        if closures.count > 0 {
            closureOpQ.addOperations(closures, waitUntilFinished: false)
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
        
        var operationCancelled: Bool {
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