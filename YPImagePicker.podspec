Pod::Spec.new do |s|
  s.name             = 'YPImagePicker'
  s.version          = "3.5.0"
  s.summary          = "Instagram-like image picker & filters for iOS"
  s.homepage         = "https://github.com/Yummypets/YPImagePicker"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = 'S4cha'
  s.platform         = :ios
  s.source           = { :git => "https://github.com/Yummypets/YPImagePicker.git",
                         :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sachadso'
  s.requires_arc     = true
  s.ios.deployment_target = "9.0"
  s.source_files = 'Source/**/*.swift'
  s.dependency 'SteviaLayout', '~> 4.4.0'
  s.dependency 'PryntTrimmerView', :git => 'https://github.com/HHK1/PryntTrimmerView.git', :tag => '3.0.0-beta.1'
  s.resources    = ['Resources/*', 'Source/**/*.xib']
  s.description  = "Instagram-like image picker & filters for iOS supporting videos and albums"
end
