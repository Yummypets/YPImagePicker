Pod::Spec.new do |s|
  s.name             = 'YPImagePicker'
  s.version          = "4.5.0"
  s.summary          = "Instagram-like image picker & filters for iOS"
  s.homepage         = "https://github.com/Yummypets/YPImagePicker"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = 'S4cha, NikKovIos'
  s.platform         = :ios
  s.source           = { :git => "https://github.com/Yummypets/YPImagePicker.git",
                         :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sachadso'
  s.requires_arc     = true
  s.ios.deployment_target = "9.0"
  s.source_files = 'Source/**/*.swift'
  s.dependency 'SteviaLayout', '~> 4.7.3'
  s.dependency 'PryntTrimmerView', '~> 4.0.2'
  s.resources    = ['Resources/*', 'Source/**/*.xib']
  s.description  = "Instagram-like image picker & filters for iOS supporting videos and albums"
  s.swift_versions = ['3', '4.1', '4.2', '5.0', '5.1', '5.2', '5.3']
end
