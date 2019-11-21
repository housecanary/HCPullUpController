Pod::Spec.new do |s|
  s.name         = "HCPullUpController"
  s.version      = "1.0.0"
  s.license      = { :type => "MIT" }
  s.homepage     = "https://github.com/housecanary/HCPullUpController"
  s.author       = { "Justin Nguyen" => "jnguyen@housecanary.com" }
  s.summary      = "Pull Controller for iOS"
  s.source       = { :git => "https://github.com/housecanary/HCPullUpController.git", :tag => s.version }

  s.ios.deployment_target = "10.0"
  s.tvos.deployment_target = "10.0"

  s.source_files = "Source/**/*.{swift,h}"
end
