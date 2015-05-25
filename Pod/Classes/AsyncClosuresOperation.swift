public class AsyncClosuresOperation : JDAsyncOperation {
    
    public typealias AsyncClosuresOperationResultsHandler = (finishedOp: AsyncClosuresOperationObjectProtocol) -> Void
        
    public typealias AsyncClosureIdentifier = Int
    public typealias AsyncClosure = (op: AsyncClosuresOperation, closureIdentifier: AsyncClosureIdentifier) -> Void
    
    private var closures = Dictionary<AsyncClosureIdentifier, AsyncClosure>()
    private var currentClosureIdentifier = 0
    private var numberOfClosures = 0
    public var closureQueue = dispatch_get_main_queue() // must be a serial queue!
    
    public func addAsyncClosure(asyncClosure : AsyncClosure) {
        dispatch_async(closureQueue) {
            let key = self.closures.count
            self.closures.updateValue(asyncClosure, forKey: key)
        }
    }
    
    public func markClosureWithIdentifierFinished(closureIdentifier : AsyncClosureIdentifier) {
        performClosureWithIdentifier(closureIdentifier + 1)
    }
    
    override public func main() {
        performClosureWithIdentifier(0)
    }
    
    private func performClosureWithIdentifier(closureIdentifier : AsyncClosureIdentifier) {
        
        dispatch_async(closureQueue) {
            if let closure = self.closures[closureIdentifier] {
                self.closures.removeValueForKey(closureIdentifier)
                closure(op: self, closureIdentifier: closureIdentifier)
            } else {
                self.finish()
            }
        }
        
    }
    
}