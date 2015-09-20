# AsyncOpKit
 
AsyncOpKit brings Swift generics, error handling, and closures to NSOperations with `AsyncOp`, a Swift-only generic NSOperation subclass for composing asynchronous code.

`AsyncOp` supports:

* Generic input and output
* Closures for starting and cancelling work, handling results
* Closures for evaluating preconditions
* Making an AsyncOp dependent on input from another

You can subclass AsyncOp, but because it provides built-in storage for generic input and output and allows you to customize behavior with closures, in many if not most cases you can just use AsyncOp as-is.

## Requirements and installation

* AsyncOp has been tested against iOS 8.0 and later. In theory, it should also work for OS X, tvOS, and WatchOS, but I haven't tested it.
* Via CocoaPods: `pod AsyncOpKit` with `use_frameworks!` in your podfile and `import AsyncOpKit` in files where you use it.
* Or just add the `AsyncOp.swift` and `AsyncOpTypes.swift` files to your project.

## License/Author

`AsyncOp` is written by me (Jed Lewison) and has an MIT license. It's still a work in progress as is this documentation, so feedback is welcome.

## Sample usage

Let's say you want to download an image. You could create a simple `AsyncOp` with a input type of NSURL and an output type of UIImage. Start with:

```swift
let imageDownloadOp = AsyncOp<NSURL, UIImage>()
```

Now since we already know our URL, we can simply provide it right away:

```swift
imageDownloadOp.setInput(imageURL)
```
Next, we need specify how the image should be downloaded. We do that in the ``onStart`` closure, which begins like this:

```swift
imageDownloadOp.onStart { asyncOp in
```

Note that in this example, `asyncOp` is identical to `imageDownloadOp`. That's not so useful here, but it can be useful if you're returning operations from a function.

The first thign we have to do is get our input, which is stored in the input property which is an `AsyncOpValue`, an enum that stores the input value or if there was a problem providing the input, an associated error. `onStart` is a throwing closure, so to get our value we can call a throwing function on `AsyncOpValue` which will succeed if the value exists or throw if not. If it throws, the operation will finish with an error (more on that later).

So here's what things should look like now:

```swift
imageDownloadOp.onStart { asyncOp in
    let imageURL = try asyncOp.input.getValue()
```

Next we need to make a network request to get the data stored at the imageURL. For simplicity of this example, let's use a plain old NSURLSession for that:

```swift
imageDownloadOp.onStart { asyncOp in
    let imageURL = try asyncOp.input.getValue()
    let dataTask = NSURLSession.sharedSession().dataTaskWithURL(imageURL) { data, response, error in
        // response handling here
    }
    dataTask.resume()
}
```

Notice that I've cheated here by not handling the response. That's not only important for the obvious reasons, but it's also important because if we don't tell the operation when it's finished, it will never complete once it starts.

### Finish `AsyncOp`s with a `finish(with:)` function

*Once an `AsyncOp` begins executing, **it must be manually finished***.*

You can finish with an error by throwing. In our example, note that if `try asyncOp.input.getValue()` fails, that will finish the operation because it throws. Keep in mind that you can't throw from inside another closure unless that closure rethrows.

Aside from throwing, how do you finish `AsyncOp`s? Here's a simple implementation extending the previous example:

```swift
imageDownloadOp.onStart { asyncOp in
    let imageURL = try asyncOp.input.getValue()
    let dataTask = NSURLSession.sharedSession().dataTaskWithURL(imageURL) { data, _, error in
        if let data = data, image = UIImage(data: data) {
            asyncOp.finish(with: image)
        } else {
            asyncOp.finish(with: error ?? AsyncOpError.Unspecified)
        }
    }
    dataTask.resume()
}
```

The key thing to take from that is that to finish an operation you call its `finish` function. `finish` has several convenient overloads that let you supply an error, the output value, or mark cancellation. **If you have an operation that does not product any output, you can use the `AsyncVoid` type and use `finishWithSuccess()` instead of doing something like `finish(with: Void())`.**

### Get `AsyncOp` results with `whenFinished`

Once our operation finishes, how then do we get the image from the operation? We use the `whenFinished` closure. If we don't care about errors, the implementation might look like this:

```swift
imageDownloadOp.whenFinished { asyncOp in
    guard let image = try? asyncOp.output.getValue() else { return }
    imageView.image = image
}
```

Because AsyncOp uses generics and because we specified the output type as a UIImage, `image` is guaranteed to be a UIImage if it exists. If we wanted to handle errors, we could have switched on the output like this:

```swift
imageDownloadOp.whenFinished { asyncOp in
    switch asyncOp.output {
    case .None(let asyncOpValueError):
        errorHandler.handleError(asyncOpValueError)
    case .Some(let image):
        imageView.image = image
    }
}
```

The image is still guaranteed to be an image, but now we can inspect the error. Note that we just performed UI work in the `whenFinished` closure. That's because by default, the `whenFinished` closure fires on the mainQueue. To specify a different queue, simply don't accept the default parameter, for example:

```swift
imageDownloadOp.whenFinished(whenFinishedQueue: notMainThreadQueue) { asyncOp in
```

Also keep in mind you can supply a `whenFinished` closure at any time, even after the operation has finished, but you can only do so once.

## Canceling `AsyncOp`s with `cancel()`

Once an `AsyncOp` begins executing, it's up to you to handle cancelation. You can use the `onCancel` closure to specify actions to perform after `cancel()` is invoked, for example canceling the operations `dataTask`, but you must still check the operations `cancelled` property at appropriate times during execution to handle cancellation and finish the operation. If you choose to respect the cancel command, you should `finish(with: .Cancelled)`, usually in the `onStart` implementation after checking for cancellation.

## Chain AsyncOps with input dependencies via `AsyncOpInputProvider`

Let's say we wanted to do something fancier with the data than simply attempting to convert it to a UIImage — perhaps we wanted to resize the image and mask it. We could add code to our operation's `onStart` closure to accomplish that, but that could quickly become very hard to read. Instead, what we'd want to do is to create two or more `AsyncOp`s and chain them together.

Let's say what we want is this (of course catching errors along the way)

1. Get some image data from the network and provide a raw image
2. Process the raw image and provide a final output image

Since CoreImage makes it easier to apply all sorts of filters to images, now we want our image download operation to provide a CIImage:

```swift
let imageDownloadOp = AsyncOp<NSURL, CIImage>()
imageDownloadOp.setInput(imageURL)
```

And we want to create a new operation that takes in a CIImage and returns a UIImage:

```swift
let imageFilteringOp = AsyncOp<CIImage, UIImage>()
```

But there's a problem, right? How can we get the output of the `imageDownloadOp` to the input of the `imageFilteringOp` without a bunch of boilerplate? Fortunately, `AsyncOp` makes it simple: 

```swift
imageFilteringOp.setInputProvider(imageDownloadOp)
```

`setInputProvider` gives the target operation an object conforming to `AsyncOpInputProvider` from which to request its input just as it begins executing. Moreover, if the input provider is also an NSOperation, the target adds the provider as a dependency. What this means is that now that we've set our imageDownloadOp as the inputProvider for our imageFilteringOp, the only thing we need to do is get our input at the beginning of our `onStart` closure. For example:

```swift
imageFilteringOp.onStart { asyncOp in
    let image = try asyncOp.input.getValue()
```

Remember, `getValue()` throws, and `onStart` is a throwing closure, so if the download operation errored out and we have no image, the operation will finish immediately at this point. Otherwise, we can continue on with our image filtering, making sure to `finish(with: outputImage)` when we are done.

AsyncOp conforms to `AsyncOpInputProvider` so any `AsyncOp` can provide input to another `AsyncOp` as long as its output type matches the target's input type. Thanks to the dependency relationship provided by NSOperation, the input provider will neve be asked to provide input until it has completed.

Remember that the input is an `AsyncOpValue` enum. Although it is strongly typed using generics, using an enum wrapper allows for propagating error messages, so you must unwrap input using the syntax above.

## Other features

This documentation is still a work in progress, as is `AsyncOp` itself. Aside from reading theo code, you might want to peruse the tests for other features not yet covered here, including:

* Using `pause()` and `resume()` to suspend the readiness of `AsyncOp`s before they begin executing
* Using `AsyncOpPreconditionEvaluator` functions for evaluating preconditions. These allow you supply functions that are evaluated before `onStart` is called that can prevent an operation from executing if preconditions aren't met.


### AsyncOperation for Objective-C and Swift 1.2 compatibility

AsyncOperation is provided for legacy compatibility with Objective-C. It doesn't provide all the features of AsyncOp, but it does take away the boilerplate involved in async operations and lets you specify a result and error value. AsyncOperation works with Obj-C. For Swift 1.2, either copy the AsyncOperation files only or use `pod AsyncOpKit, '0.0.8'`.
