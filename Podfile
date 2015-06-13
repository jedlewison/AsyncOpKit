target 'AsyncOpKit' do

end

target 'AsyncOpKitTests' do
    use_frameworks!

    use_swift2 = false
    if use_swift2
        pod 'Quick', :git => 'https://github.com/Quick/Quick.git', :branch => 'swift-2.0'
        pod 'Nimble', :git => 'https://github.com/Quick/Nimble.git', :branch => 'swift-2.0'
        else
        pod 'Quick', '~> 0.3.1'
        pod 'Nimble', '~> 0.4.2'
    end
end

