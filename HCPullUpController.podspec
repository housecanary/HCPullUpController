Pod::Spec.new do |s|
  s.name         = "HCPullUpController"
  s.version      = "1.0.3"
  s.license      = { :type => "MIT" }
  s.homepage     = "https://github.com/housecanary/HCPullUpController"
  s.author       = { "Justin Nguyen" => "jnguyen@housecanary.com" }
  s.summary      = "Pull Controller for iOS"
  s.source       = { :git => "https://github.com/housecanary/HCPullUpController.git", :tag => s.version }

  s.ios.deployment_target = "11.0"

  s.source_files = "Sources/**/*.{swift,h}"
end
