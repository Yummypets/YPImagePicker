## YPImagePicker

YPImagePicker is an instagram-like photo/video picker for iOS written in pure Swift.
It comes with adjustable square crop and filters.

[![Version](https://img.shields.io/cocoapods/v/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![Platform](https://img.shields.io/cocoapods/p/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![CI Status](http://img.shields.io/travis/ytakzk/Fusuma.svg?style=flat)](https://travis-ci.org/ytakzk/Fusuma)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codebeat badge](https://codebeat.co/badges/6a591267-c444-4c88-a410-56270d8ed9bc)](https://codebeat.co/projects/github-com-yummypets-ypfusuma)
[![GitHub tag](https://img.shields.io/github/release/Yummypets/YPImagePicker.svg)]()

|         | Features  |
----------|-----------------
🌅        | Library
📷        | Photo
🎥        | Video
✂️        | Crop
⚡️        | Flash
🖼        | Filters


## Preview

<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/library.PNG" width="340px">
<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/photo.PNG" width="340px">
<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/video.PNG" width="340px">
<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/filters.PNG" width="340px">


Those features are available just with a few lines of code!

## Improvements
YPImagePicker was built from the great Fusuma library.

Here are the improvements we added :
- Improve Overall Code Quality
- Simplify API
- Added Filters View ala Instagram
- Replaces icons with lighter Text
- Preselect Front camera (e.g for avatars)
- Scroll between tabs which feels smoother
- Grab videos form the library view as well
- Replaces Delegate based with callbacks based api
- Uses Native Navigation bar over custom View (gotta be a good UIKit citizen)

## Installation

Drop in the Classes folder to your Xcode project.  
You can also use CocoaPods or Carthage.

#### Using [CocoaPods](http://cocoapods.org/)

Add `pod 'YPImagePicker'` to your `Podfile` and run `pod install`. Also add `use_frameworks!` to the `Podfile`.

```
target 'MyApp'
pod 'YPImagePicker'
use_frameworks!
```

#### Using [Carthage](https://github.com/Carthage/Carthage)

Add `github "Yummypets/YPImagePicker"` to your `Cartfile` and run `carthage update`. If unfamiliar with Carthage then checkout their [Getting Started section](https://github.com/Carthage/Carthage#getting-started).

```
github "Yummypets/YPImagePicker"
```

## Plist entries

In order for your app to access camera and photo libraries,
you'll need to ad these `plist entries` :

- Privacy - Camera Usage Description (photo/videos)
- Privacy - Photo Library Usage Description (library)
- Privacy - Microphone Usage Description (videos)

```xml
<key>NSCameraUsageDescription</key>
<string>yourWording</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>yourWording</string>
<key>NSMicrophoneUsageDescription</key>
<string>yourWording</string>
```

## Configuration

```swift
var config = YPImagePickerConfiguration()
config.onlySquareImagesFromLibrary = false
config.onlySquareImagesFromCamera = true
config.libraryTargetImageSize = .original
config.showsVideo = true
config.usesFrontCamera = true
config.showsFilters = true
config.shouldSaveNewPicturesToAlbum = true
config.videoCompression = AVAssetExportPresetHighestQuality
config.albumName = "MyGreatAppName"
config.startOnScreen = .library

// Build a picker with your configuration
let picker = YPImagePicker(configuration: config)
```

## Default Configuration

```swift
// Set the default configuration for all pickers
YPImagePicker.setDefaultConfiguration(config)

// And then use the default configuration like so:
let picker = YPImagePicker()
```

## Usage

`import YPImagePicker` then use the following:

```swift
let picker = YPImagePicker()

// unowned is Mandatory since it would create a retain cycle otherwise :)
picker.didSelectImage = { [unowned picker] img in
    // image picked
    print(img.size)
    self.imageView.image = img
    picker.dismiss(animated: true, completion: nil)
}
picker.didSelectVideo = { videoData, videoThumbnailImage in
    // video picked
    self.imageView.image = videoThumbnailImage
    picker.dismiss(animated: true, completion: nil)
}
present(picker, animated: true, completion: nil)
```


## Original Project & Author

This project has been first inspired by [Fusuma](https://github.com/ytakzk/Fusuma)
Considering the big code and design changes, this moved form a fork to a standalone separate repo, also for discoverability purposes.
Original Fusuma author is [ytakz](http://ytakzk.me)

## License
YPImagePicker is released under the MIT license.  
See LICENSE for details.

## Swift Version
Swift 3 -> version **1.2.1**  
Swift 4 -> version **2.3.0**
