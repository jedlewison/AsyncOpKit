Pod::Spec.new do |s|
  s.name             = "AsyncOpKit"
  s.version          = "0.1.0"
  s.summary          = "AsyncOpKit provides Swift subclasses of NSOperation to help manage asynchronous operations"
  s.description      = <<-DESC
                       AsyncOpKit provides Swift subclasses of NSOperation to help manage asynchronous operations
                       DESC
  s.author           = "Jed Lewison"
  s.homepage         = "https://github.com/jedlewison/AsyncOpKit"
  s.license          = 'MIT'
  s.source           = { :git => "https://github.com/jedlewison/AsyncOpKit.git", :branch => "xcode7gm" }
  s.platform         = :ios, '8.0'
  s.requires_arc     = true
  s.source_files     = "{AsyncOp.swift,AsyncOpTypes.swift,Legacy/*.swift}"
end
