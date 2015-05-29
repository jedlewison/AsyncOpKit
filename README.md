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
