//
//  YPCoverImageView.swift
//
//
//  Created by Will Saults on 1/15/24.
//

import UIKit
import Photos

public class YPCoverImageView: YPAdjustableView {

    var coverImageView = UIImageView()

    var cropRect: CGRect?
    var asset: PHAsset?
    var videoUrl: URL?

    public var image: UIImage? {
        get {
            coverImageView.image
        }
        set {
            coverImageView.image = newValue
        }
    }

    public var targetAspectRatio: CGFloat?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateViewFrameAction = { [weak self] frame in
            self?.coverImageView.layer.frame = frame
            self?.coverImageView.contentMode = .scaleAspectFill
            self?.coverImageView.clipsToBounds = true
        }
        // Ensure necessary properties are available
        guard let cropRect = cropRect else { return }
        if let asset = asset {
            adjustViewFrameIfNeeded(cropRect: cropRect, asset: asset, targetAspectRatio: targetAspectRatio)
        } else if let videoUrl = videoUrl {
            let videoAsset = AVAsset(url: videoUrl)
            guard let track = videoAsset.tracks(withMediaType: AVMediaType.video).first else { return }
            let size = track.naturalSize.applying(track.preferredTransform)
            let fixedSize = CGSize(width: abs(size.width), height: abs(size.height))
            adjustViewFrameIfNeeded(cropRect: cropRect, assetSize: fixedSize, targetAspectRatio: targetAspectRatio)
        }
    }

    internal func setup() {
        assetContainer.subviews(coverImageView)
        coverImageView.fillContainer()
        subviews(
            assetContainer
        )

        assetContainer.fillContainer()
        assetContainer.clipsToBounds = true
    }
}
