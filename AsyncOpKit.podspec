Pod::Spec.new do |s|
    s.name             = "AsyncOpKit"
    s.version          = "1.2.0"
    s.summary          = "NSOperation for Swift with generic input/output, chaining, error handling, and closures"
    s.description      = <<-DESC
    AsyncOpKit brings Swift generics, error handling, and closures to NSOperations with `AsyncOp`, a Swift-only generic NSOperation subclass for composing asynchronous code.
    `AsyncOp` supports:

    * Generic input and output
    * Closures for starting and cancelling work, handling results
    * Closures for evaluating preconditions
    * Making an AsyncOp dependent on input from another

    You can subclass AsyncOp, but because it provides built-in storage for generic input and output and allows you to customize behavior with closures, in many if not most cases you can just use AsyncOp as-is.
    DESC
    s.author           = "Jed Lewison"
    s.homepage         = "https://github.com/jedlewison/AsyncOpKit"
    s.license          = 'MIT'
    s.source           = { :git => "https://github.com/jedlewison/AsyncOpKit.git", :tag => s.version.to_s }
    s.platform         = :ios, '8.0'
    s.requires_arc     = true
    s.source_files     = "{AsyncOp.swift,AsyncOpTypes.swift,AsyncOpGroup.swift,Legacy/*.swift}"
end
