# AsyncOpKit

AsyncOpKit helps manage asynchronous operations. It provides:

* AsyncOperation, a Swift NSOperation subclass that handles the boilerplate necessary for asynchronous NSOperations. Just override main() and don't forget to finish your operation.
* AsyncClosuresOperation, an AsyncOperation subclass that lets you manage asynchronous work inside of closures. It's similar to NSBlockOperation, but but closures/blocks do not finish until you mark them as complete.

AsyncOperation also provides a helpful result handler that fires on a queue of your choosing (default mainQueue) and lets you provide result value and error.

## Requirements

iOS 8.0 or later.

## Installation

AsyncOpKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AsyncOpKit"
```

## Author

Jed Lewison

## License

AsyncOpKit is available under the MIT license. See the LICENSE file for more info.
