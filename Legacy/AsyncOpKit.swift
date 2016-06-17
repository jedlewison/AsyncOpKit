/// AsyncOperation is provided for compatability with objective c

import Foundation

extension QualityOfService {
    
    /// returns a GCD serial queue for the corresponding QOS
    func createSerialDispatchQueue(_ label: String) -> DispatchQueue {
        return DispatchQueue(label: label, attributes: [.serial, dispatchQueueAttributes()])
    }

    /// returns GCD's corresponding QOS class
    private func dispatchQueueAttributes() -> DispatchQueueAttributes {
        switch (self) {
        case .background:
            return .qosBackground
        case .default:
            return .qosDefault
        case .userInitiated:
            return .qosUserInitiated
        case .userInteractive:
            return .qosUserInteractive
        case .utility:
            return .qosUtility
        }
    }
    
}
