extension NSQualityOfService {
    
    /// returns a global GCD queue for the corresponding QOS
    func getGlobalDispatchQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(dispatchQOS(), 0)
    }
    
    /// returns a GCD serial queue for the corresponding QOS
    func createSerialDispatchQueue(label: UnsafePointer<Int8>) -> dispatch_queue_t {
        let attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, dispatchQOS(), 0)
        return dispatch_queue_create(label, attr)
    }

    /// returns a GCD concurrent queue for the corresponding QOS
    func createConcurrentDispatchQueue(label: UnsafePointer<Int8>) -> dispatch_queue_t {
        let attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, dispatchQOS(), 0)
        return dispatch_queue_create(label, attr)
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