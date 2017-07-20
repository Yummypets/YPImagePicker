## YPImagePicker

YPImagePicker is an instagram-like photo/video picker for iOS written in pure Swift.
It comes with adjustable square crop and filters.

[![Version](https://img.shields.io/cocoapods/v/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![Platform](https://img.shields.io/cocoapods/p/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![CI Status](http://img.shields.io/travis/ytakzk/Fusuma.svg?style=flat)](https://travis-ci.org/ytakzk/Fusuma)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codebeat badge](https://codebeat.co/badges/6a591267-c444-4c88-a410-56270d8ed9bc)](https://codebeat.co/projects/github-com-yummypets-ypfusuma)

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
use_frameworks!
pod 'YPImagePicker'
```

#### Using [Carthage](https://github.com/Carthage/Carthage)

Add `github "Yummypets/YPImagePicker"` to your `Cartfile` and run `carthage update`. If unfamiliar with Carthage then checkout their [Getting Started section](https://github.com/Carthage/Carthage#getting-started).

```
github "Yummypets/YPImagePicker"
```

## Usage

`import YPImagePicker` then use the following:

```swift
let picker = YPImagePicker()
// picker.onlySquareImages = true
// picker.showsFilters = false
// picker.startsOnCameraMode = true
// picker.usesFrontCamera = true
// picker.showsVideo = true
picker.didSelectImage = { img in
    // image picked
}
picker.didSelectVideo = { videoData in
    // video picked
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
