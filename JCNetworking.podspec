Pod::Spec.new do |s|
  s.name         = 'JCNetworking'
  s.version      = '1.5.2'
  s.summary      = 'A lightweight iOS networking framework based on AFNetworking.'
  s.homepage     = 'https://github.com/imjoych/JCNetworking'
  s.author       = { 'ChenJianjun' => 'imjoych@gmail.com' }
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.source       = { :git => 'https://github.com/imjoych/JCNetworking.git', :tag => s.version.to_s }
  s.source_files = 'JCNetworking/*.{h,m}'
  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'

  s.dependency 'AFNetworking', '~> 3.2.0'

end
