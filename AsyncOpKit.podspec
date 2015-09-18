Pod::Spec.new do |s|
    s.name             = "AsyncOpKit"
    s.version          = "1.0.0"
    s.summary          = "Generic NSOperation subclass for managing asynchronous code in Swift"
    s.description      = <<-DESC
    AsyncOpKit provides AsyncOp, a generic NSOperation subclass for managing
    asynchronous operations with NSOperationQueues while taking advantage of
    the power of Swift's type system. Async Op is not compatible with Obj-C,
    however a legacy AsyncOperation that is Obj-C compatible is included.'
    DESC
    s.author           = "Jed Lewison"
    s.homepage         = "https://github.com/jedlewison/AsyncOpKit"
    s.license          = 'MIT'
    s.source           = { :git => "https://github.com/jedlewison/AsyncOpKit.git", :tag => s.version.to_s }
    s.platform         = :ios, '8.0'
    s.requires_arc     = true
    s.source_files     = "{AsyncOp.swift,AsyncOpTypes.swift,Legacy/*.swift}"
end
