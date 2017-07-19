Pod::Spec.new do |s|
  s.name             = 'YPImagePicker'
  s.version          = "1.1.0"
  s.summary          = "Instagram-like image picker & filters for iOS"
  s.homepage         = "https://github.com/Yummypets/YPImagePicker"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = 'S4cha'
  s.platform         = :ios
  s.source           = { :git => "https://github.com/Yummypets/YPImagePicker.git",
                         :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sachadso'
  s.requires_arc     = true
  s.ios.deployment_target = "8.0"
  s.source_files = 'Source/**/*.swift'
  s.resources    = ['Source/Assets.xcassets', 'Source/**/*.xib']
  s.description  = "Instagram-like image picker & filters for iOS"
end
