/// Use an AsyncClosuresOperation to serially run an arbitrary number of potentially asynchronous closures.
/// Although AsyncClosures can run asynchronously from the perspective of the queue or thread managing the operation, the operation object runs them serially, FIFO.
/// For concurrent AsyncClosures, create multiple AsyncClosuresOperation objects

public class AsyncClosuresOperation : AsyncOperation {
    
    /// Used to identify AsyncClosures
    public typealias AsyncClosureIdentifier = Int
    
    /**
    The signature of an AsyncClosure.
    
    :param: op The AsyncClosuresOperation responsible for performing the closures
    :param: closureIdentifier An identifier representing the closure
    
    You must use the parameters to tell the operation when the closure has finished, for example:
    
      let closuresOp = AsyncClosuresOperation()
        closuresOp.addAsyncClosure {
          op, closureIdentifier in
          dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            // do some stuff and then finish
            op.markClosureWithIdentifierFinished(closureIdentifier)
        }
       }
    
    You can also use the parameters to check it the operation has been cancelled:
    
    */
    public typealias AsyncClosure = (op: AsyncClosuresOperation, closureIdentifier: AsyncClosureIdentifier) -> Void
    
    /// Call this method to inform the operation that an AsyncClosure has been finished and that it should execute the next closure or finish the operation.
    /// WARNING: You must call this method on every closure for the operation to finish.
    
    public final func markClosureWithIdentifierFinished(closureIdentifier: AsyncClosureIdentifier) {
        performClosureWithIdentifier(closureIdentifier + 1)
    }
    
    /// Add an AsyncClosure to an AsyncClosuresOperation.
    /// See AsyncClosure documentation for usage.
    
    public final func addAsyncClosure(asyncClosure: AsyncClosure) {
        let key = self.closures.count
        self.closures.updateValue(asyncClosure, forKey: key)
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
                return qos.createSerialDispatchQueue("AsyncClosuresOperationQOS")
            }
        }
    }
    
    // MARK: Private methods/properties
    
    private var _closuresQueueKind = AsyncClosuresQueueKind.Main
    
    private var closuresQueue = dispatch_get_main_queue()
    
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
                    closure(op: self, closureIdentifier: closureIdentifier)
                } else {
                    self.finish()
                }
            }
        }
        
    }
    
}