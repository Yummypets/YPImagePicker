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
        guard let cropRect = cropRect, let asset = asset else { return }
        adjustViewFramesIfNeeded(cropRect: cropRect, asset: asset, targetAspectRatio: targetAspectRatio)
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
