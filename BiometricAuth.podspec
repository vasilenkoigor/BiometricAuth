Pod::Spec.new do |s|
  s.name         = "BiometricAuth"
  s.version      = "2.0.0"
  s.summary      = "Biometric authentication (via TouchID) in your application"
  s.description  = "Framework for biometric authentication (via TouchID) in your application"
  s.homepage     = "https://github.com/vasilenkoigor/BiometricAuth"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Igor Vasilenko" => "spb.vasilenko@icloud.com" }
  s.ios.deployment_target = "9.3"
  s.osx.deployment_target = "10.12.2"
  s.source       = { :git => "https://github.com/vasilenkoigor/BiometricAuth.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = 'LocalAuthentication'
end
