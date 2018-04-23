//
//  VideoCropView.swift
//  PryntTrimmerView
//
//  Created by Henry on 07/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

private let margin: CGFloat = 16

/// A view to preview a video inside an `AVPlayer`, with a scroll view to be able to select a specific area of the video.
/// Simply set the `asset` property to load you video inside the view, and use the `getImageCropFrame` method to retrieve the
/// selected frame of the video.
public class VideoCropView: UIView {

    let videoScrollView = VideoScrollView()
    let cropMaskView = CropMaskView()

    /// The asset being cropped. Setting the property will load the asset in the `AVPlayer` contained in the scroll view.
    public var asset: AVAsset? {
        didSet {
            if let asset = asset {
                videoScrollView.setupVideo(with: asset)
            }
        }
    }

    var cropFrame = CGRect.zero

    /// The current aspect ratio of the crop view.
    public private(set) var aspectRatio = CGSize(width: 1, height: 1)

    /// The player used in the scroll view. Use it if you want to seek a specific time of your video.
    public var player: AVPlayer? {
        return videoScrollView.player
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {

        videoScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(videoScrollView)

        videoScrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        videoScrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        videoScrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        videoScrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        cropMaskView.isUserInteractionEnabled = false
        cropMaskView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cropMaskView)

        cropMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        cropMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        cropMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        cropMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        setAspectRatio(aspectRatio, animated: false)
    }

    /// Set the aspect ratio for the cropping box.
    ///
    /// [Issue #3]: https://github.com/prynt/PryntTrimmerView/issues/3
    /// - Parameters:
    ///   - aspectRatio: The desired aspect ratio.
    ///   - animated: true if you want to animate the change. TODO: the animation glitches sometimes. See [Issue #3]
    public func setAspectRatio(_ aspectRatio: CGSize, animated: Bool) {

        self.aspectRatio = aspectRatio
        let ratio = aspectRatio.width / aspectRatio.height
        let cropBoxWidth = ratio > 1 ? (bounds.width - 2 * margin) : (bounds.height - 2 * margin)  * ratio
        let cropBoxHeight = cropBoxWidth / ratio
        let origin = CGPoint(x: (bounds.width - cropBoxWidth) / 2, y: (bounds.height - cropBoxHeight) / 2)
        cropFrame = CGRect(origin: origin, size: CGSize(width: cropBoxWidth, height: cropBoxHeight))

        let edgeInsets = UIEdgeInsets(top: origin.y, left: origin.x, bottom: origin.y, right: origin.x)
        let duration: TimeInterval = animated ? 0.15 : 0.0

        cropMaskView.setCropFrame(cropFrame, animated: animated)
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.videoScrollView.scrollView.contentInset = edgeInsets
        }, completion: nil)
        videoScrollView.setZoomScaleAndCenter(animated: animated)
    }

    /// Get the currently selected frame of the asset. You can then use it to perform the actual cropping of the video or of an
    /// isolated image
    public func getImageCropFrame() -> CGRect {

        let imageSize = videoScrollView.assetSize
        let contentSize = videoScrollView.scrollView.contentSize
        let cropBoxFrame = cropFrame
        let contentOffset = videoScrollView.scrollView.contentOffset
        let edgeInsets = videoScrollView.scrollView.contentInset

        var frame = CGRect.zero
        frame.origin.x = floor((contentOffset.x + edgeInsets.left) * (imageSize.width / contentSize.width))
        frame.origin.x = max(0, frame.origin.x)

        frame.origin.y = floor((contentOffset.y + edgeInsets.top) * (imageSize.height / contentSize.height))
        frame.origin.y = max(0, frame.origin.y)

        frame.size.width = ceil(cropBoxFrame.size.width * (imageSize.width / contentSize.width))
        frame.size.width = min(imageSize.width, frame.size.width)

        frame.size.height = ceil(cropBoxFrame.size.height * (imageSize.height / contentSize.height))
        frame.size.height = min(imageSize.height, frame.size.height)
        return frame
    }
}
