![Stevia](https://raw.githubusercontent.com/s4cha/Stevia/master/banner.png)

[![Documentation](https://img.shields.io/badge/Read_the-Docs-67ad5c.svg)](http://freshos.org/SteviaDocs/)
[![Language: Swift 2, 3 and 4](https://img.shields.io/badge/language-swift%204-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platform: iOS 8+](https://img.shields.io/badge/platform-iOS%20|%20tvOS-blue.svg?style=flat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/badge/Cocoapods-compatible-4BC51D.svg?style=flat)](https://cocoapods.org/pods/SteviaLayout)
[![Build Status](https://www.bitrise.io/app/4478e29045c5f12e.svg?token=pti6g-HVKBUPv9mIR3baIw&branch=master)](https://www.bitrise.io/app/4478e29045c5f12e)
[![Join the chat at https://gitter.im/freshoss/Stevia](https://badges.gitter.im/s4cha/Stevia.svg)](https://gitter.im/freshoss/Stevia)
[![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/s4cha/Stevia/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/dt/SteviaLayout.svg)]()
[![CocoaPods](https://img.shields.io/cocoapods/at/SteviaLayout.svg)]()
[![GitHub contributors](https://img.shields.io/github/contributors/freshos/Stevia.svg)](https://github.com/freshos/Stevia/graphs/contributors)
[![GitHub tag](https://img.shields.io/github/release/freshos/Stevia.svg)]()


<p align="center">
    <a href="https://www.hackingwithswift.com/articles/9/best-alternatives-to-auto-layout">
        <img src="https://www.hackingwithswift.com/uploads/recommended@2x.png" alt="Drawing" width="300px;" />
    </a>
</p>

<p align="center">
    <a href="https://www.hackingwithswift.com/articles/9/best-alternatives-to-auto-layout">
        Winner of Hacking with Swift Recommended award
    </a>
</p>

## You + Stevia = 🦄
- [x] 💡 Write **concise**, **readable** layouts
- [x] 🏖 **Reduce** your **maintenance** time
- [x] 🎨 **Compose** your styles, **CSS-like**
- [x] 🔴 Plug **Live reload** and **boost** your iteration cycles


[Reason](#reason) - [Example](#login-view-example) - [Live Reload](#live-reload) - [Installation](#installation) - [Documentation](#documentation)


### 🖼 Visual Layout Api
```swift
layout(
    100,
    |-email-| ~ 80,
    8,
    |-password-forgot-| ~ 80,
    >=20,
    |login| ~ 80,
    0
)
```
### ⛓ Chainable Api
```swift
email.top(100).left(8).right(8).width(200).height(44)
alignHorizontally(password, forgot)
image.fillContainer()
button.centerInContainer().size(50%)
equalWidths(email, password)
image.width(>=80)
```

### 📐 Equation-Based Api
```swift
email.Top == 100
password.CenterY == forgot.CenterY
login.Top >= password.Bottom + 20
login.Width == 75 % Width
(image.Height == 100).priority = UILayoutPriority(rawValue: 999)
```

All Generate **native** NSLayoutConstraints 🎉

### 👨‍🔬Try it!

Stevia is part of [freshOS](http://freshos.org) iOS toolset. Try it in an example App ! <a class="github-button" href="https://github.com/freshOS/StarterProject/archive/master.zip" data-icon="octicon-cloud-download" data-style="mega" aria-label="Download freshOS/StarterProject on GitHub">Download Starter Project</a>

### 💡 Reason
Because **nothing holds more truth than pure code** 🤓  
Xibs and storyboards are **heavy, hard to maintain, hard to merge.**  
They split the view concept into 2 separate files making debugging a **nightmare**    
*There must be a better way*

#### How
By creating a tool that makes Auto layout code finally **readable by a human being**.  
By coupling it with live code injection such as *[injectionForXcode](http://johnholdsworth.com/injection.html)* we can **design views in real time**  
View layout becomes **fun**, **concise**, **maintainable** and dare I say, *beautiful* ❤️

### Login View Example
In the project folder, you can find an example of a typical login view laid out in both native and Stevia for you to understand and compare the two approaches.

As a spoiler alert, the **number of characters** goes from 2380 to 1239 **( ~ divided by 2)**

Write **Half the code** that is actually **10X more expressive and maintainable** !

### 🔴 Live Reload

Live reload enables you to develop your views live without relaunching the app everytime.

Stevia + [InjectionForXcode](http://johnholdsworth.com/injection.html) = #WhoNeedsReactNative?? 🚀

<img src="http://g.recordit.co/i6kQfTMEpg.gif" height="300" width="360" />

*Just `Cmd+S` and you can dev live in the simulator !*

Learn more about how to set up live reload [here](http://freshos.org/SteviaDocs/liveReload/).


### ⚙️ Installation
Get started [here](http://freshos.org/SteviaDocs/installation/).

### 📖 Documentation
You can find the full documentation [here](http://freshos.org/SteviaDocs/).

### 👨‍💻 Contributors

[YannickDot](https://github.com/YannickDot),  [S4cha](https://github.com/S4cha),  [Damien](https://github.com/damien-nd),
[Snowcraft](https://github.com/Snowcraft), [Mathieu-o](https://github.com/Mathieu-o),
[Blaz Merela](https://github.com/b1az),
[Theophane Rupin](https://github.com/trupin),
[Jason Liang](https://github.com/jyliang),
[liberty4me](https://github.com/liberty4me),
[Scott Bates](https://github.com/cowgp),
[Sai](https://github.com/sai-prasanna),
[Mike Gallagher](https://github.com/mgallagher),
[WaterNotWords](https://github.com/waternotwords),
[Mick MacCallum](https://github.com/0x7fffffff)

### 👥 Backers
Like the project? Offer coffee or support us with a monthly donation and help us continue our activities :)

<a href="https://opencollective.com/freshos/backer/0/website" target="_blank"><img src="https://opencollective.com/freshos/backer/0/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/1/website" target="_blank"><img src="https://opencollective.com/freshos/backer/1/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/2/website" target="_blank"><img src="https://opencollective.com/freshos/backer/2/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/3/website" target="_blank"><img src="https://opencollective.com/freshos/backer/3/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/4/website" target="_blank"><img src="https://opencollective.com/freshos/backer/4/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/5/website" target="_blank"><img src="https://opencollective.com/freshos/backer/5/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/6/website" target="_blank"><img src="https://opencollective.com/freshos/backer/6/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/7/website" target="_blank"><img src="https://opencollective.com/freshos/backer/7/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/8/website" target="_blank"><img src="https://opencollective.com/freshos/backer/8/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/9/website" target="_blank"><img src="https://opencollective.com/freshos/backer/9/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/10/website" target="_blank"><img src="https://opencollective.com/freshos/backer/10/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/11/website" target="_blank"><img src="https://opencollective.com/freshos/backer/11/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/12/website" target="_blank"><img src="https://opencollective.com/freshos/backer/12/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/13/website" target="_blank"><img src="https://opencollective.com/freshos/backer/13/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/14/website" target="_blank"><img src="https://opencollective.com/freshos/backer/14/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/15/website" target="_blank"><img src="https://opencollective.com/freshos/backer/15/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/16/website" target="_blank"><img src="https://opencollective.com/freshos/backer/16/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/17/website" target="_blank"><img src="https://opencollective.com/freshos/backer/17/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/18/website" target="_blank"><img src="https://opencollective.com/freshos/backer/18/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/19/website" target="_blank"><img src="https://opencollective.com/freshos/backer/19/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/20/website" target="_blank"><img src="https://opencollective.com/freshos/backer/20/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/21/website" target="_blank"><img src="https://opencollective.com/freshos/backer/21/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/22/website" target="_blank"><img src="https://opencollective.com/freshos/backer/22/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/23/website" target="_blank"><img src="https://opencollective.com/freshos/backer/23/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/24/website" target="_blank"><img src="https://opencollective.com/freshos/backer/24/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/25/website" target="_blank"><img src="https://opencollective.com/freshos/backer/25/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/26/website" target="_blank"><img src="https://opencollective.com/freshos/backer/26/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/27/website" target="_blank"><img src="https://opencollective.com/freshos/backer/27/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/28/website" target="_blank"><img src="https://opencollective.com/freshos/backer/28/avatar.svg"></a>
<a href="https://opencollective.com/freshos/backer/29/website" target="_blank"><img src="https://opencollective.com/freshos/backer/29/avatar.svg"></a>

### 🏅 Sponsors
Become a sponsor and get your logo on our README on Github with a link to your site :)

<a href="https://opencollective.com/freshos/sponsor/0/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/1/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/2/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/3/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/4/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/5/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/6/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/7/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/8/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/9/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/9/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/10/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/10/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/11/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/11/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/12/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/12/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/13/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/13/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/14/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/14/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/15/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/15/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/16/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/16/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/17/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/17/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/18/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/18/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/19/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/19/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/20/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/20/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/21/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/21/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/22/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/22/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/23/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/23/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/24/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/24/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/25/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/25/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/26/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/26/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/27/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/27/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/28/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/28/avatar.svg"></a>
<a href="https://opencollective.com/freshos/sponsor/29/website" target="_blank"><img src="https://opencollective.com/freshos/sponsor/29/avatar.svg"></a>

### Swift Version

- Swift 2 -> [v**2.3.0**](https://github.com/freshOS/Stevia/releases/tag/2.3.0)
- Swift 3 -> [v**3.2.0**](https://github.com/freshOS/Stevia/releases/tag/3.2.0)
- Swift 4 -> [v**4.2.0**](https://github.com/freshOS/Stevia/releases/tag/4.2.0)
- Swift 4.1 -> [v**4.3.0**](https://github.com/freshOS/Stevia/releases/tag/4.3.0)
