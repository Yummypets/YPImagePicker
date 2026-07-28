Pod::Spec.new do |s|
  s.name             = 'YPImagePicker'
  s.version          = "5.3.2"
  s.summary          = "Instagram-like image picker & filters for iOS"
  s.homepage         = "https://github.com/Yummypets/YPImagePicker"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.authors = { 'S4cha'   => 'https://twitter.com/sachadso',
                'NikeKov' => 'nikkovios@gmail.com' }
  s.platform         = :ios
  s.source           = { :git => "https://github.com/Yummypets/YPImagePicker.git",
                         :tag => s.version.to_s }
  s.ios.deployment_target = "15.0"
  s.source_files = 'Source/**/*.swift'
  s.dependency 'SteviaLayout', '= 6.2.2'
  s.dependency 'PryntTrimmerView', '= 4.0.2'
  s.resources    = ['Source/Resources/*', 'Source/**/*.xib']
  s.resource_bundles = { 'YPImagePicker' => ['Source/PrivacyInfo.xcprivacy'] }
  s.description  = "Instagram-like image picker & filters for iOS supporting videos and albums"
  s.swift_versions = ['5.5']
end
