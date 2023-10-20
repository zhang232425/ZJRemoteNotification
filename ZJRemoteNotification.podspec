#
# Be sure to run `pod lib lint ZJRemoteNotification.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    
  s.name             = 'ZJRemoteNotification'
  s.version          = '0.1.0'
  s.summary          = 'A short description of ZJRemoteNotification.'
  s.homepage         = 'https://github.com/zhang232425/ZJRemoteNotification.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yonathan' => 'yonathan@asetku.com' }
  s.source           = { :git => 'git@github.com:zhang232425/ZJRemoteNotification.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = 'ZJRemoteNotification/Classes/**/*'
  
end
