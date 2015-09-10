<!-- [![CI Status](http://img.shields.io/travis/Jed Lewison/AsyncOpKit.svg?style=flat)](https://travis-ci.org/Jed Lewison/AsyncOpKit) -->
[![Version](https://img.shields.io/cocoapods/v/AsyncOpKit.svg?style=flat)](http://cocoapods.org/pods/AsyncOpKit)
[![License](https://img.shields.io/cocoapods/l/AsyncOpKit.svg?style=flat)](http://cocoapods.org/pods/AsyncOpKit)
[![Platform](https://img.shields.io/cocoapods/p/AsyncOpKit.svg?style=flat)](http://cocoapods.org/pods/AsyncOpKit)

# AsyncOpKit
 
AsyncOpKit helps manage asynchronous operations. It provides:

* AsyncOperation, a Swift NSOperation subclass that handles the boilerplate necessary for asynchronous NSOperations. Just override main() and don't forget to finish your operation.
* AsyncClosuresOperation, an AsyncOperation subclass that lets you manage asynchronous work inside of closures. It's similar to NSBlockOperation, but but closures/blocks do not finish until you mark them as complete.

AsyncOperation also provides a helpful result handler that fires on a queue of your choosing (default mainQueue) and lets you provide result value and error.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

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

<!-- [![CI Status](http://img.shields.io/travis/Jed Lewison/AsyncOperation.svg?style=flat)](https://travis-ci.org/Jed Lewison/AsyncOperation) -->
[![Version](https://img.shields.io/cocoapods/v/AsyncOperation.svg?style=flat)](http://cocoapods.org/pods/AsyncOperation)
[![License](https://img.shields.io/cocoapods/l/AsyncOperation.svg?style=flat)](http://cocoapods.org/pods/AsyncOperation)
[![Platform](https://img.shields.io/cocoapods/p/AsyncOperation.svg?style=flat)](http://cocoapods.org/pods/AsyncOperation)

# AsyncOperation

(Note: This readme is dated -- I'll be updating soon, but probably best way to get ideas of how to use AsyncOperation is by browsing through the tests.)

AsyncOperation brings Swift generics, error handling, and closures to NSOperations. It provides AsyncOperation, a generic NSOperation subclass for executing asynchronous operations.

You can subclass AsyncOperation, but because it uses generics and provides convenient closures for performing work and handling both cancellation and errors, in many cases you probably won't need to.

AsyncOperation requires Swift 2.0 and is not available from Objective-C.

## Why AsyncOperation?

Just like NSOperations, AsyncOperations are intended to be used with NSOperationQueues. Everything that applies to NSOperations also applies to AsyncOperation. Unlike normal NSOperations, however, AsyncOperations are not considered finished until you explicitly end them. That means they can perform work asynchronously outside of the queue that they were invoked on.

AsyncOperation is a work in progress. This README.md attempts to explain some of its features.

## AsyncOpResult

When an AsyncOperation finishes, it is either Cancelled, Failed, or Completed. Inspect the result enum to determine it's finished state. The failed state includes an associated error and the completed state includes an associated value of a generic type you define when initializing the operation.

Let's say you had a parsing operation like this:

```swift
let op = AsyncOperation<MyParsedType>()

op.onStart { operation in
ServiceCall().return { json in 
if let myParsedObject = MyParsedType(json: json) {
operation.finishWithResult(myParsedObject)
} else {
operation.finishWithError(MyParsingError.ErrorParsing)
}
}
}
```

Of course, you want to be able to do something with the output, right? AsyncOperation provides a handy completion handler that fires on a queue of your choosing, by default on the main queue:

```swift
op.whenFinished { operation in
switch operation.output {
case .Cancelled:
// handle
case .Failed(let error):
// handle error
case .Completed(let value):
// do something with your parsed object
// It will be a MyParsedType because AsyncOperation is generic
case .Pending:
// should never be Pending in a completing handler
}
}
```

## Handling cancellation

If you've used NSOperation, you know that if you are cancelled before your operation starts, the operation never executes. AsyncOperations give you two chances to handle that case — either in the completion handler or the cancellation handler.

Your operation can also be cancelled after it starts but before it finishes. In this case, it does not automatically end the operation—you are responsible for checking the operation's cancelled status at appropriate times and handling cancellation as you determine appropriate.

Even if you are cancelled, AsyncOperation lets you finish with success. It's up to you to decide what makes the most sense for your operation.

## Subclassing vs using plain old AsyncOperation

If the closures provide enough customization options for you, you probably don't need to subclass AsyncOperation. But if you do, here's some things to keep in mind:

* If you don't want to use closures, the methods you absolutely need to subclass are performOperation and handleCancellation. Keep in mind however that if a closure is provided, then the only way for performOperation or handleCancellation to run is by manually calling it.

## AsyncOpDependency

Just like with NSOperation, you can add dependencies to AsyncOperation. But with AsyncOperation, dependencies are more powerful. Before an operation begins, AsyncOperation inspects dependencies to see if they successfully completed or not; your operation will not run unless all operations it depends on also completed successfully.

AsyncOperation defines a protocol for these dependencies: AsyncOpDependency. AsyncOperation conforms to that protocol, which means you can add AsyncOperations as asyncOpDependencies. When you add an NSOperation that conforms to AsyncOpDependency as a dependency, it also adds it as an NSOperation dependency, which means that it will execute before your operation. But whether or not it's an NSOperation, when your operation is ready to run, it inspects the AsyncOpDependency to make sure that it can proceed.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 8.0 or later. Currently 

## Installation

AsyncOperation is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
use_frameworks!
pod 'AsyncOperation', :git => 'https://github.com/jedlewison/AsyncOperation.git', :branch => 'swift-2.0'
```

## Author

Jed Lewison

## License

AsyncOperation is available under the MIT license. See the LICENSE file for more info.

