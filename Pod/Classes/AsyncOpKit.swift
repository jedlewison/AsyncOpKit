@objc public protocol AsyncOperationObjectProtocol : NSObjectProtocol {
    
    var value: AnyObject? {get} // use this property to store the results of your operation
    var error: NSError? {get} // use this property to store any error about your operation
    var cancelled: Bool { @objc(isCancelled) get }
    var dependencies: [AnyObject] { get }
    
}

extension NSQualityOfService {
    
    /// returns a global GCD queue for the corresponding QOS
    func globalDispatchQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(dispatchQOS(), 0)
    }
    
    /// returns GCD's corresponding QOS class
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