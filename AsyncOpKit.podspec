Pod::Spec.new do |s|
  s.name             = "AsyncOpKit"
  s.version          = "0.0.8"
  s.summary          = "AsyncOpKit provides Swift subclasses of NSOperation to help manage asynchronous operations"
  s.description      = <<-DESC
                       AsyncOpKit helps manage asynchronous operations.

                       * AsyncOperation is a Swift NSOperation subclass that handles
                       the boilerplate necessary for asynchronous NSOperations. Just
                       override main() and don't forget to finish your operation.
                       * AsyncOperation also provides a helpful result handler that
                       fires on a queue of your choosing (default mainQueue) and lets
                       you provide result value and error.
                       * AsyncClosuresOperation is an AsyncOperation subclass that
                       lets you manage asynchronous work inside of closures. It's similar
                       to NSBlockOperation, but but closures/blocks do not finish until
                           you mark them as complete.
                       DESC
  s.homepage         = "https://github.com/jedlewison/AsyncOpKit"
  s.license          = 'MIT'
  s.author           = { "Jed Lewison" => "jed@.....magic....app....factory.com" }
  s.source           = { :git => "https://github.com/jedlewison/AsyncOpKit.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'AsyncOpKit/*.swift'
end
