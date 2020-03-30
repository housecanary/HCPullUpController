Pod::Spec.new do |s|
  s.name         = "HCPullUpController"
  s.version      = "1.1.2"
  s.license      = { :type => "MIT" }
  s.homepage     = "https://git.housecanary.net/Mobile-Team/HCPullUpController.git"
  s.author       = { "Justin Nguyen" => "jnguyen@housecanary.com" }
  s.summary      = "Pull Controller for iOS"
  s.source       = { :git => "git@git.housecanary.net:Mobile-Team/HCPullUpController.git", :tag => s.version }
  s.swift_version = '5.0'

  s.ios.deployment_target = "12.0"

  s.source_files = "Sources/**/*.{swift,h}"
end
