/// AsyncOperation is provided for compatability with objective c

import Foundation


enum AsyncOperationState: String {
    case Ready = "isReady"
    case Executing = "isExecuting"
    case Finished = "isFinished"
}


/// AsyncOperation takes care of the boilerplate you need for writing asynchronous NSOperations and adds a couple of useful features: An optional results handler that includes the operation, and properties to store results of the operation.

public class AsyncOperation: Operation {
    
    var state = AsyncOperationState.Ready {
        willSet {
            if newValue != state {
                let oldValue = state
                willChangeValue(forKey: newValue.rawValue)
                willChangeValue(forKey: oldValue.rawValue)
            }
        }
        
        didSet {
            if oldValue != state {
                didChangeValue(forKey: oldValue.rawValue)
                didChangeValue(forKey: state.rawValue)
                if isFinished {
                    if let completionHandler = completionHandler {
                        self.completionHandler = nil
                        completionHandlerQueue.async { completionHandler(finishedOp: self) }
                    }
                }
            }
        }
    }
    
    /// The completionHandler is fired once when the operation finishes on the queue specified by `completionHandlerQueue`. It passes in the finished operation which will indicate whethere the operation was cancelled, had an error, or has a value.
    /// :finishedOp: The finished operation. Downcast if needed inside the compleetion handler.
    public final var completionHandler: ((finishedOp: AsyncOperation) -> Void)?
    
    /// The operation queue on which the results handler will fire. Default is mainQueue.
    public final var completionHandlerQueue: DispatchQueue = DispatchQueue.main
    
    /// Override main to start potentially asynchronous work. When the operation is complete, you must call finish(). Do not call super.
    /// This method will not be called it the operation was cancelled before it was started.
    override public func main() {
        finish()
    }
    
    // use this property to store the results of your operation. You can also declare new properties in subclasses
    public var value: AnyObject?
    
    // use this property to store any error about your operation
    public final var error: NSError?
    
    // MARK: Async Operation boilerplate. For more information, read the Concurrency Programming Guide for iOS or OS X.
    override public final var isAsynchronous: Bool {
        return true
    }
    
    override public final func start() {

        if state == .Finished {
            debugPrint("State was unexpectedly finished")
        }

        if state != .Ready {
            debugPrint("State was unexpectedly not ready")
        }

        state = .Executing

        if !isCancelled {
            main()
        } else {
            finish()
        }
    }
    
    override public final var isExecuting: Bool {
        get { return state == .Executing }
    }
    
    override public final var isFinished: Bool {
        get { return state == .Finished }
    }
    
    public final func finish() {
        lockQ.sync {
            self.state = .Finished
        }
    }
    
    private let lockQ = QualityOfService.userInteractive.createSerialDispatchQueue("asyncOperation.lockQ")
    
}
