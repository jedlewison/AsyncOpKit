Pod::Spec.new do |s|
  s.name             = "AsyncOperation"
  s.version          = "0.1.0"
  s.summary          = "AsyncOperation is an NSOperation subclass that supports a generic output type and takes care of the boiler plate necessary for asynchronous execution of NSOperations."
  s.description      = <<-DESC
			You can subclass AsyncOperation, but because it's a generic subclass and provides convenient closures for performing work as well has handling cancellation, results, and errors, in many cases you may not need to.
                       DESC
  s.homepage         = "https://github.com/jedlewison/AsyncOperation"
  s.license          = 'MIT'
  s.author           = { "Jed Lewison" => "jed@.....magic....app....factory.com" }
  s.source           = { :git => "https://github.com/jedlewison/AsyncOperation.git" }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'AsyncOperation/*.swift'
end
