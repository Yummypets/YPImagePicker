// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "YPImagePicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "YPImagePicker", targets: ["YPImagePicker"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/freshOS/Stevia",
            .exact("5.1.2")
        ),
        .package(
            url: "https://github.com/rewardStyle/PryntTrimmerView",
            .branch("CC-505-creators-can-view-video-lengths-when-editing-in-storytelling-posts")
        )

    ],
    targets: [
        .target(
            name: "YPImagePicker",
            dependencies: ["Stevia", "PryntTrimmerView"],
            path: "Source",
            exclude: ["Info.plist", "YPImagePickerHeader.h"]
        )
    ]
)
