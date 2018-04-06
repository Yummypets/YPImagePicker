<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/visual.jpg" width="400px" >

## YPImagePicker

YPImagePicker is an instagram-like photo/video picker for iOS written in pure Swift.
It comes with adjustable square crop and filters.

[![Version](https://img.shields.io/cocoapods/v/YPImagePicker.svg?style=flat)](http://cocoapods.org/pods/YPImagePicker)
[![Platform](https://img.shields.io/cocoapods/p/YPImagePicker.svg?style=flat)](http://cocoapods.org/pods/YPImagePicker)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codebeat badge](https://codebeat.co/badges/9710a89d-b1e2-4e55-a4a2-3ae1f98f4c53)](https://codebeat.co/projects/github-com-yummypets-ypimagepicker-master)
[![GitHub tag](https://img.shields.io/github/release/Yummypets/YPImagePicker.svg)]()

Give it a quick try :
`pod repo update` then `pod try YPImagePicker`

🌅 Library - 📷 Photo - 🎥 Video - ✂️ Crop - ⚡️ Flash - 🖼 Filters

<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/library.PNG" width="200px" > <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/photo.PNG" width="200px" > <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/video.PNG" width="200px" > <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/filters.PNG" width="200px" >

Those features are available just with a few lines of code!

## Improvements
YPImagePicker was built from the great Fusuma library.

Here are the improvements we added :

- Albums
- Filters
- Videos in the library
- Both Square and non-square images
- Permission managenent
- Pan between tabs which feels smoother
- Improve Overall Code Quality
- Simplify API
- Replaces icons with lighter Text
- Preselect Front camera (e.g for avatars)
- Replaces Delegate based with callbacks based api
- Uses Native Navigation bar over custom View (gotta be a good UIKit citizen)
- Faster library load
- Hidden status bar for a more immersive XP
- Flash Auto mode
- Video Torch Mode
- iPhone X support

## Installation

Drop in the Classes folder to your Xcode project.  
You can also use CocoaPods or Carthage.

#### Using [CocoaPods](http://cocoapods.org/)

First be sure to run `pod repo update` to get the latest version available.

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
config.usesFrontCamera = true
config.showsFilters = true
config.shouldSaveNewPicturesToAlbum = true
config.videoCompression = AVAssetExportPresetHighestQuality
config.albumName = "MyGreatAppName"
config.screens = [.library, .photo, .video]
config.startOnScreen = .library
config.videoRecordingTimeLimit = 10
config.videoFromLibraryTimeLimit = 20
config.showsCrop = .rectangle(ratio: (16/9))
config.wordings.libraryTitle = "Gallery"
config.hidesStatusBar = false
config.overlayView = myOverlayView

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
picker.didCancel = {
  print("Did Cancel")
}
present(picker, animated: true, completion: nil)
```

## Languages
Supported languages out of the box:
- English
- Spanish
- French
- Russian
- Dutch
- Brazilian
- Turkish

If your language is not supported, you can still customize the wordings via the `configuration.wordings` api:

```swift
config.wordings.libraryTitle = "Gallery"
config.wordings.cameraTitle = "Camera"
config.wordings.next = "OK"
```
Better yet you can submit an issue or pull request with your `Localizable.strings` file to add a new language !

## Original Project & Author

This project has been first inspired by [Fusuma](https://github.com/ytakzk/Fusuma)
Considering the big code and design changes, this moved form a fork to a standalone separate repo, also for discoverability purposes.
Original Fusuma author is [ytakz](http://ytakzk.me)

## License
YPImagePicker is released under the MIT license.  
See [LICENSE](LICENSE) for details.

## Swift Version

- Swift 3 -> version [**1.2.1**](https://github.com/Yummypets/YPImagePicker/releases/tag/1.2.1)
- Swift 4 -> version [**2.7.3**](https://github.com/Yummypets/YPImagePicker/releases/tag/2.8.1)
