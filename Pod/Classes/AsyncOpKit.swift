// Packages up all the boring stuff in potentially async operations
// To subclass, just implement main and don't forget to call finished and check for cancellation!

/*
opq doasyncoperationwithblock

asyncblockoperation

finishExecutionBlock


*/

public class JDAsyncClosureOperation : JDAsyncOperation {
    
    public typealias JDAsyncClosureIdentifier = Int
    public typealias JDAsyncClosure = (op: JDAsyncClosureOperation, closureIdentifier: JDAsyncClosureIdentifier) -> Void
    
    private var closures = Dictionary<JDAsyncClosureIdentifier, JDAsyncClosure>()
    private var currentClosureIdentifier = 0
    private var numberOfClosures = 0
    
    public func addAsyncClosure(asyncClosure : JDAsyncClosure) {
        let key = closures.count
        closures.updateValue(asyncClosure, forKey: key)
    }
    
    public func markClosureWithIdentifierFinished(closureIdentifier : JDAsyncClosureIdentifier) {
        performClosureWithIdentifier(closureIdentifier + 1)
    }
    
    override public func main() {
        performClosureWithIdentifier(0)
    }
    
    private func performClosureWithIdentifier(closureIdentifier : JDAsyncClosureIdentifier) {
        
        if let closure = closures[closureIdentifier] {
            closures.removeValueForKey(closureIdentifier)
            closure(op: self, closureIdentifier: closureIdentifier)
        } else {
            self.finish()
        }
        
    }
    
}


@objc public protocol JDAsyncOperationResults : NSObjectProtocol {

//    var result : AnyObject? {get set} // use this property to store the results of your operation
    var error : NSError?  {get} // use this property to store any error about your operation
    var operation : JDAsyncOperation {get}
    var cancelled : Bool {get}
}

public class JDAsyncOperation: NSOperation {

    // TODO: Call this a resultHandler
    public var completionHandler : ((finishedOp: JDAsyncOperationResults) -> Void)?

    public func handleCancellation() {
        // intended to be subclassed.
        // invoked at most once, after cancel is invoked on an operation that has begun execution
        // must call finish after handling cancellation
        // do not call super
        finish()
    }

    public var result : NSString? // use this property to store the results of your operation
    public var error : NSError? // use this property to store any error about your operation


    override public final func cancel() {
        if cancelled { return }

        super.cancel()
        if executing {
            handleCancellation()
        }
    }

    override public final var asynchronous : Bool {
        return true
    }

    override public final func start() {
        if cancelled {
            finish()
            return
        }

        if finished {
            return
        }

        willChangeValueForKey("isExecuting")

        dispatch_async(qualityOfService.globalDispatchQueue(), {
            if (!self.finished && !self.cancelled) {
                self.main()
            } else {
                self.finish()
            }
        })

        _executing = true
        didChangeValueForKey("isExecuting")
    }

    override public func main() {
        // subclass this and kick off potentially asynchronous work
        // call finished = true when done
        // do not call super as super does nothing but finish the task
        println("Error: \(self) Must subclass main to do anything useful")
        finish()
    }

    override public final var executing : Bool {
        get { return _executing }
    }

    override public final var finished : Bool {
        get { return _finished }
    }

    func getResults() -> DefaultAsyncOperationResults {
        return DefaultAsyncOperationResults(op: self);
    }

    public final func finish(operationResults : JDAsyncOperationResults? = nil) {

        if finished { return }

        if let completionHandler = completionHandler {
            self.completionHandler = nil

            let finishedResults : JDAsyncOperationResults

            if let operationResults = operationResults {
                finishedResults = operationResults
            } else {
                finishedResults = DefaultAsyncOperationResults(op: self)
            }

            completionOpQ.addOperationWithBlock {
                completionHandler(finishedOp: finishedResults)
            }
        }

        willChangeValueForKey("isFinished")
        willChangeValueForKey("isExecuting")
        _executing = false
        _finished = true
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")

    }

    public var completionOpQ : NSOperationQueue = NSOperationQueue.mainQueue()

    private var _executing = false
    private var _finished = false

    class DefaultAsyncOperationResults : NSObject, JDAsyncOperationResults {

        init(op: JDAsyncOperation) {
            error = nil;
            operation = op
        }
        let error : NSError?
        let operation : JDAsyncOperation
        var cancelled : Bool {
            get { return operation.cancelled }
        }

    }

}

extension NSQualityOfService {

    func globalDispatchQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(dispatchQOS(), 0)
    }

    func dispatchQOS() -> qos_class_t {
        switch (self) {
        case .Background:
            return QOS_CLASS_BACKGROUND
        case .Default:
            return QOS_CLASS_DEFAULT
        case .UserInitiated:
            return QOS_CLASS_USER_INITIATED
        case .UserInteractive:
            return QOS_CLASS_USER_INTERACTIVE
        case .Utility:
            return QOS_CLASS_UTILITY
        }
    }
}
