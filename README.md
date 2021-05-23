<h1 align="center"> <br><img src="Images/logo/logotype_horizontal.png?raw=true" alt="ypimagepicker" width="512"> <br>

<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/visual.jpg" width="400px" >

## YPImagePicker

YPImagePicker is an instagram-like photo/video picker for iOS written in pure Swift. It is feature-rich and highly customizable to match your App's requirements.

[![Language: Swift 5](https://img.shields.io/badge/language-swift%205-f48041.svg?style=flat)](https://developer.apple.com/swift)
[![Version](https://img.shields.io/cocoapods/v/YPImagePicker.svg?style=flat)](http://cocoapods.org/pods/YPImagePicker)
[![Platform](https://img.shields.io/cocoapods/p/YPImagePicker.svg?style=flat)](http://cocoapods.org/pods/YPImagePicker)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codebeat badge](https://codebeat.co/badges/9710a89d-b1e2-4e55-a4a2-3ae1f98f4c53)](https://codebeat.co/projects/github-com-yummypets-ypimagepicker-master)
[![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/Yummypets/YPImagePicker/blob/master/LICENSE)
[![GitHub tag](https://img.shields.io/github/release/Yummypets/YPImagePicker.svg)]()


[Installation](#installation) - [Configuration](#configuration) - [Usage](#usage) - [Languages](#languages) - [UI Customization](#ui-customization)


Give it a quick try :
`pod repo update` then `pod try YPImagePicker`

<img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/library.PNG" width="200px" > <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/photo.PNG" width="200px" > <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/video.PNG" width="200px" > <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/filters.PNG" width="200px" >

Those features are available just with a few lines of code!

## Notable Features

🌅 Library  
📷 Photo  
🎥 Video  
✂️ Crop  
⚡️ Flash  
🖼 Filters  
📁 Albums  
🔢 Multiple Selection  
📏 Video Trimming & Cover selection  
📐 Output image size  
And many more...

## Installation

## Experimental Swift Package Manager (SPM) Support
A first version of SPM support is available :
package `https://github.com/Yummypets/YPImagePicker` branch `spm`.  
This has a minimum target iOS version of `12.0`.  
This is an early release so be sure to thoroughly test the integration and report any issues you'd encounter.

Side note:  
Swift package manager is the future and I would strongly recommend you to migrate as soon as possible.
Once this integration is stable, the other packager managers will be deprecated.

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

All the configuration endpoints are in the [YPImagePickerConfiguration](https://github.com/Yummypets/YPImagePicker/blob/master/Source/Configuration/YPImagePickerConfiguration.swift) struct.
Below are the default value for reference, feel free to play around :)

```swift
var config = YPImagePickerConfiguration()
// [Edit configuration here ...]
// Build a picker with your configuration
let picker = YPImagePicker(configuration: config)
```

### General
```Swift
config.isScrollToChangeModesEnabled = true
config.onlySquareImagesFromCamera = true
config.usesFrontCamera = false
config.showsPhotoFilters = true
config.showsVideoTrimmer = true
config.shouldSaveNewPicturesToAlbum = true
config.albumName = "DefaultYPImagePickerAlbumName"
config.startOnScreen = YPPickerScreen.photo
config.screens = [.library, .photo]
config.showsCrop = .none
config.targetImageSize = YPImageSize.original
config.overlayView = UIView()
config.hidesStatusBar = true
config.hidesBottomBar = false
config.hidesCancelButton = false
config.preferredStatusBarStyle = UIStatusBarStyle.default
config.bottomMenuItemSelectedColour = UIColor(r: 38, g: 38, b: 38)
config.bottomMenuItemUnSelectedColour = UIColor(r: 153, g: 153, b: 153)
config.filters = [DefaultYPFilters...]
config.maxCameraZoomFactor = 1.0
config.preSelectItemOnMultipleSelection = true
config.fonts..
```

### Library
```swift
config.library.options = nil
config.library.onlySquare = false
config.library.isSquareByDefault = true
config.library.minWidthForItem = nil
config.library.mediaType = YPlibraryMediaType.photo
config.library.defaultMultipleSelection = false
config.library.maxNumberOfItems = 1
config.library.minNumberOfItems = 1
config.library.numberOfItemsInRow = 4
config.library.spacingBetweenItems = 1.0
config.library.skipSelectionsGallery = false
config.library.preselectedItems = nil
```

### Video
```swift
config.video.compression = AVAssetExportPresetHighestQuality
config.video.fileType = .mov
config.video.recordingTimeLimit = 60.0
config.video.libraryTimeLimit = 60.0
config.video.minimumTimeLimit = 3.0
config.video.trimmerMaxDuration = 60.0
config.video.trimmerMinDuration = 3.0
```

### Gallery
```swift
config.gallery.hidesRemoveButton = false
```

## Default Configuration

```swift
// Set the default configuration for all pickers
YPImagePickerConfiguration.shared = config

// And then use the default configuration like so:
let picker = YPImagePicker()
```

When displaying picker on iPad, picker will support one size only you should set it before displaying it: 
```
let preferredContentSize = CGSize(width: 500, height: 600);
YPImagePickerConfiguration.widthOniPad = preferredContentSize.width;

// Now you can Display the picker with preferred size in dialog, popup etc

```

## Usage

First things first `import YPImagePicker`.  

The picker only has one callback `didFinishPicking` enabling you to handle all the cases. Let's see some typical use cases 🤓

### Single Photo
```swift
let picker = YPImagePicker()
picker.didFinishPicking { [unowned picker] items, _ in
    if let photo = items.singlePhoto {
        print(photo.fromCamera) // Image source (camera or library)
        print(photo.image) // Final image selected by the user
        print(photo.originalImage) // original image selected by the user, unfiltered
        print(photo.modifiedImage) // Transformed image, can be nil
        print(photo.exifMeta) // Print exif meta data of original image.
    }
    picker.dismiss(animated: true, completion: nil)
}
present(picker, animated: true, completion: nil)
```

### Single video
```swift
// Here we configure the picker to only show videos, no photos.
var config = YPImagePickerConfiguration()
config.screens = [.library, .video]
config.library.mediaType = .video

let picker = YPImagePicker(configuration: config)
picker.didFinishPicking { [unowned picker] items, _ in
    if let video = items.singleVideo {
        print(video.fromCamera)
        print(video.thumbnail)
        print(video.url)
    }
    picker.dismiss(animated: true, completion: nil)
}
present(picker, animated: true, completion: nil)
```

As you can see `singlePhoto` and `singleVideo` helpers are here to help you handle single media which are very common, while using the same callback for all your use-cases \o/

### Multiple selection
To enable multiple selection make sure to set `library.maxNumberOfItems` in the configuration like so:
```swift
var config = YPImagePickerConfiguration()
config.library.maxNumberOfItems = 3
let picker = YPImagePicker(configuration: config)
```
Then you can handle multiple selection in the same callback you know and love :
```swift
picker.didFinishPicking { [unowned picker] items, cancelled in
    for item in items {
        switch item {
        case .photo(let photo):
            print(photo)
        case .video(let video):
            print(video)
        }
    }
    picker.dismiss(animated: true, completion: nil)
}
```

### Handle Cancel event (if needed)
```swift
picker.didFinishPicking { [unowned picker] items, cancelled in
    if cancelled {
        print("Picker was canceled")
    }
    picker.dismiss(animated: true, completion: nil)
}
```
That's it !

## Languages
🇺🇸 English, 🇪🇸 Spanish, 🇫🇷 French 🇷🇺 Russian, 🇵🇱 Polish, 🇳🇱 Dutch, 🇧🇷 Brazilian, 🇹🇷 Turkish, 🇸🇾 Arabic, 🇩🇪 German, 🇮🇹 Italian, 🇯🇵 Japanese, 🇨🇳 Chinese, 🇮🇩 Indonesian, 🇰🇷 Korean, 🇹🇼 Traditional Chinese（Taiwan), 🇻🇳 Vietnamese, 🇹🇭 Thai. 

If your language is not supported, you can still customize the wordings via the `configuration.wordings` api:

```swift
config.wordings.libraryTitle = "Gallery"
config.wordings.cameraTitle = "Camera"
config.wordings.next = "OK"
```
Better yet you can submit an issue or pull request with your `Localizable.strings` file to add a new language !

## UI Customization
We tried to keep things as native as possible, so this is done mostly through native Apis.

### Navigation bar color
```swift
let coloredImage = UIImage(color: .red)
UINavigationBar.appearance().setBackgroundImage(coloredImage, for: UIBarMetrics.default)
// UIImage+color helper https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
```

### Navigation bar fonts
```swift
let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 30, weight: .bold) ]
UINavigationBar.appearance().titleTextAttributes = attributes // Title fonts
UIBarButtonItem.appearance().setTitleTextAttributes(attributes, for: .normal) // Bar Button fonts
```

### Navigation bar Text colors
```swift
UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.yellow ] // Title color
UINavigationBar.appearance().tintColor = .red // Left. bar buttons
config.colors.tintColor = .green // Right bar buttons (actions)
```

## Original Project & Author

This project has been first inspired by [Fusuma](https://github.com/ytakzk/Fusuma)
Considering the big code, design changes and all the additional features added along the way, this moved form a fork to a standalone separate repo, also for discoverability purposes.
Original Fusuma author is [ytakz](http://ytakzk.me)

## Core Team
<a href="https://github.com/S4cha">
  <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/coreTeam1.png" width="70px">
</a>
<a href="https://github.com/NikKovIos">
  <img src="https://raw.githubusercontent.com/Yummypets/YPImagePicker/master/Images/coreTeam2.png" width="70px">
</a>

## Contributors 🙏
[ezisazis](https://github.com/ezisazis),
[hanikeddah](https://github.com/hanikeddah),
[tahaburak](https://github.com/tahaburak),
[ajkolean](https://github.com/ajkolean),
[Anarchoschnitzel](https://github.com/Anarchoschnitzel),
[Emil](https://github.com/heitara),
[Rafael Damasceno](https://github.com/DamascenoRafael),
[cenkingunlugu](https://github.com/https://github.com/cenkingunlugu)
[heitara](https://github.com/heitara)
[portellaa](https://github.com/portellaa)
[Romixery](https://github.com/romixery)
[shotat](https://github.com/shotat)

Special thanks to [ihtiht](https://github.com/ihtiht) for the cool looking logo!

## They helped us one way or another 👏
[userdar](https://github.com/userdar),
[Evgeniy](https://github.com/Ewg777),
[MehdiMahdloo](https://github.com/MehdiMahdloo),
[om-ha](https://github.com/om-ha),
[userdar](https://github.com/userdar),
[ChintanWeapp](https://github.com/ChintanWeapp),
[eddieespinal](https://github.com/eddieespinal),
[viktorgardart](https://github.com/viktorgardart),
[gdelarosa](https://github.com/gdelarosa),
[cwestMobile](https://github.com/cwestMobile),
[Tinyik](https://github.com/Tinyik),
[Vivekthakur647](https://github.com/Vivekthakur647),
[tomasbykowski](https://github.com/tomasbykowski),
[artemsmikh](https://github.com/artemsmikh),
[theolof](https://github.com/theolof),
[dongdong3344](https://github.com/dongdong3344),
[MHX792](https://github.com/MHX792),
[CIronfounderson](https://github.com/CIronfounderson),
[Guerrix](https://github.com/Guerrix),
[Zedd0202](https://github.com/Zedd0202),
[mohammadZ74](https://github.com/mohammadZ74),
[SalmanGhumsani](https://github.com/SalmanGhumsani),
[wegweiser6](https://github.com/wegweiser6),
[BilalAkram](https://github.com/BilalAkram),
[KazimAhmad](https://github.com/KazimAhmad),
[JustinBeBoy](https://github.com/JustinBeBoy),
[SashaMeyer](https://github.com/SashaMeyer),
[GShushanik](https://github.com/GShushanik),
[Cez95](https://github.com/Cez95),
[Palando](https://github.com/Palando),
[sebastienboulogne](https://github.com/sebastienboulogne),
[JigneshParekh7165](https://github.com/JigneshParekh7165),
[Deepakepaisa](https://github.com/Deepakepaisa),
[AndreiBoariu](https://github.com/AndreiBoariu),
[nathankonrad1](https://github.com/nathankonrad1),
[wawilliams003](https://github.com/wawilliams003),
[pngo-hypewell](https://github.com/pngo-hypewell),
[PawanManjani](https://github.com/PawanManjani),
[devender54321](https://github.com/devender54321),
[Didar1994](https://github.com/Didar1994),
[relaxsus](https://github.com/relaxsus)
[restoflash](https://github.com/restoflash)

## Dependency
YPImagePicker relies on [prynt/PryntTrimmerView](https://github.com/prynt/PryntTrimmerView) for provide video trimming and cover features. Big thanks to @HHK1 for making this open source :)

## Obj-C support
Objective-C is not supported and this is not on our roadmap.
Swift is the future and dropping Obj-C is the price to pay to keep our velocity on this library :)

## License
YPImagePicker is released under the MIT license.  
See [LICENSE](LICENSE) for details.

## Swift Version

- Swift 3 -> version [**1.2.0**](https://github.com/Yummypets/YPImagePicker/releases/tag/1.2.0)
- Swift 4.1 -> version [**3.4.1**](https://github.com/Yummypets/YPImagePicker/releases/tag/3.4.0)
- Swift 4.2 -> version [**3.5.2**](https://github.com/Yummypets/YPImagePicker/releases/tag/3.5.2)
releases/tag/3.4.0)
- Swift 5.0 -> version [**4.0.0**](https://github.com/Yummypets/YPImagePicker/releases/tag/4.0.0)
- Swift 5.1 -> version [**4.1.2**](https://github.com/Yummypets/YPImagePicker/releases/tag/4.1.2)
- Swift 5.3 -> version [**4.5.0**](https://github.com/Yummypets/YPImagePicker/releases/tag/4.5.0)
