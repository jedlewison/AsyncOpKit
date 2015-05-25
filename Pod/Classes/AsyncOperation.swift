public class JDAsyncOperation: NSOperation, JDAsyncOperationObjectProtocol {
    
    public typealias JDAsyncOperationResultsHandler = (finishedOp: JDAsyncOperationObjectProtocol) -> Void
    public var resultsHandler : JDAsyncOperationResultsHandler?
    
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
        // println("Error: \(self) Must subclass main to do anything useful")
        finish()
    }
    
    override public final var executing : Bool {
        get { return _executing }
    }
    
    override public final var finished : Bool {
        get { return _finished }
    }
    
    public final func finish() {
        
        if finished { return }
        
        if let resultsHandler = resultsHandler {
            
            self.resultsHandler = nil
            
            completionOpQ.addOperationWithBlock {
                resultsHandler(finishedOp: self)
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
        
}