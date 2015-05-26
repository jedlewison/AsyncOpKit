public class AsyncClosuresOperation : AsyncOperation {
    
    public typealias AsyncClosureIdentifier = Int
    public typealias AsyncClosure = (op: AsyncClosuresOperation, closureIdentifier: AsyncClosureIdentifier) -> Void
    
    public func markClosureWithIdentifierFinished(closureIdentifier: AsyncClosureIdentifier) {
        performClosureWithIdentifier(closureIdentifier + 1)
    }
    
    public func addAsyncClosure(asyncClosure: AsyncClosure) {
        dispatch_async(closureQueue) {
            let key = self.closures.count
            self.closures.updateValue(asyncClosure, forKey: key)
        }
    }
    
    public var closureQueue: dispatch_queue_t {
        get {
            if let _ = _closureQueue {
                return _closureQueue!
            } else {
                return dispatch_get_main_queue()
            }
        }
        set {
            if let _ = _closureQueue {
                println("Cannot reassign closure queue")
            } else {
                _closureQueue = newValue
            }
        }
    }
    
    private var closures = Dictionary<AsyncClosureIdentifier, AsyncClosure>()
    private var currentClosureIdentifier = 0
    private var numberOfClosures = 0

    private var _closureQueue: dispatch_queue_t? = nil
    
    override public func main() {
        performClosureWithIdentifier(0)
    }
    
    private func performClosureWithIdentifier(closureIdentifier: AsyncClosureIdentifier) {
        
        dispatch_async(closureQueue) {
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