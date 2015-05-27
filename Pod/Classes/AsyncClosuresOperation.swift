/// Use an AsyncClosuresOperation to serially run an arbitrary number of potentially asynchronous closures.
/// Although AsyncClosures can run asynchronously from the perspective of the queue or thread managing the operation, the operation object runs them serially, FIFO.
/// For concurrent AsyncClosures, create multiple AsyncClosuresOperation objects

public class AsyncClosuresOperation : AsyncOperation {
    
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
    
    public typealias AsyncClosureFinishingFunction = () -> Void
    public typealias AsyncClosure = (op: AsyncClosuresOperation, finishAsyncClosure: AsyncClosureFinishingFunction) -> Void
    
    /// Add an AsyncClosure to an AsyncClosuresOperation.
    /// See AsyncClosure documentation for usage.
    
    public final func addAsyncClosure(asyncClosure: AsyncClosure) {
        if executing || finished || cancelled {
            return
        }
        let key = self.closures.count
        self.closures.updateValue(asyncClosure, forKey: key)
    }
    
    /// Create a new AsyncClosuresOperation with an AsyncClosure
    
    public convenience init(asyncClosure: AsyncClosure) {
        self.init()
        addAsyncClosure(asyncClosure)
    }
    
    class public func asyncClosuresOperationWithClosure(asyncClosure: AsyncClosure) -> AsyncClosuresOperation {
        return AsyncClosuresOperation(asyncClosure: asyncClosure)
    }
    
    /// The the kind of queue that should be used to manage adding and starting the operation's AsyncClosures.
    /// Note: The AsyncClosure itself can invoke other background threads
    
    public var closuresQueueKind: AsyncClosuresQueueKind {
        get {
            return _closuresQueueKind
        }
        set {
            if (!executing && !finished) {
                _closuresQueueKind = newValue
                closuresQueue = newValue.serialQueueForQOS(qualityOfService)
            }
        }
    }
    
    /// The kind of queue used for managing adding and kicking of async closures.
    
    public enum AsyncClosuresQueueKind {
        case Main
        case Background
        
        public func serialQueueForQOS(qos: NSQualityOfService) -> dispatch_queue_t {
            switch self {
            case .Main:
                return dispatch_get_main_queue()
            case .Background:
                return qos.createSerialDispatchQueue("AsyncClosuresOperationSerialQueue")
            }
        }
    }
    
    // MARK: Private methods/properties
    
    private typealias AsyncClosureIdentifier = Int
    
    private func markClosureWithIdentifierFinished(closureIdentifier: AsyncClosureIdentifier) {
        performClosureWithIdentifier(closureIdentifier + 1)
    }
    
    private var _closuresQueueKind = AsyncClosuresQueueKind.Background
    
    private var closuresQueue = AsyncClosuresQueueKind.Background.serialQueueForQOS(.Default)
    
    private var closures = Dictionary<AsyncClosureIdentifier, AsyncClosure>()
    private var currentClosureIdentifier = 0
    private var numberOfClosures = 0
    
    override public func main() {
        performClosureWithIdentifier(0)
    }
    
    private func performClosureWithIdentifier(closureIdentifier: AsyncClosureIdentifier) {
        
        dispatch_async(closuresQueue) {
            if (!self.finished) {
                if let closure = self.closures[closureIdentifier] {
                    self.closures.removeValueForKey(closureIdentifier)
                    var asyncClosureFinishingFunction = {
                        self.markClosureWithIdentifierFinished(closureIdentifier)
                    }
                    closure(op: self, finishAsyncClosure: asyncClosureFinishingFunction)
                } else if (self.closures.count == 0){
                    self.finish()
                }
            }
        }
        
    }
    
}