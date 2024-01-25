//
//  YPAdjustableView.swift
//
//
//  Created by Will Saults on 1/15/24.
//

import Photos
import UIKit

public class YPAdjustableView: UIView {
    public var updateViewFrameAction: ((CGRect) -> Void)?

    public func adjustViewFramesIfNeeded(cropRect: CGRect, asset: PHAsset, targetAspectRatio: CGFloat?) {
        let assetSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))

        if let aspectRatio = targetAspectRatio, aspectRatio != assetSize.width / assetSize.height {
            adjustViewFrameForAspectRatio(cropRect: cropRect, aspectRatio: aspectRatio, assetSize: assetSize)
        } else {
            adjustViewFrame(cropRect: cropRect, assetSize: assetSize)
        }
    }

    // Method to adjust the view frame considering the asset's original size
    private func adjustViewFrame(cropRect: CGRect, assetSize: CGSize) {
        let assetRect = CGRect(origin: .zero, size: assetSize)
        let fitFrame = calculateAspectFitFrame(assetSize: assetSize)
        let targetFrame = calculateTargetFrame(cropRect: cropRect, assetRect: assetRect, fitFrame: fitFrame)
        updateViewFrameAction?(targetFrame)
    }

    // Method to adjust the view frame based on a target aspect ratio
    private func adjustViewFrameForAspectRatio(cropRect: CGRect, aspectRatio: CGFloat, assetSize: CGSize) {
        let adjustedAssetSize = adjustedSizeForAspectRatio(assetSize, aspectRatio: aspectRatio)
        let fitFrame = calculateAspectFitFrame(assetSize: adjustedAssetSize)
        let targetFrame = calculateTargetFrame(cropRect: cropRect, assetRect: CGRect(origin: .zero, size: adjustedAssetSize), fitFrame: fitFrame, adjustForAspectRatio: true)
        updateViewFrameAction?(targetFrame)
    }

    // Calculate the adjusted size for the asset based on the target aspect ratio
    private func adjustedSizeForAspectRatio(_ assetSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        // Adjust the asset size to maintain the target aspect ratio
        if assetSize.width / assetSize.height > aspectRatio {
            return CGSize(width: assetSize.height * aspectRatio, height: assetSize.height)
        } else {
            return CGSize(width: assetSize.width, height: assetSize.width / aspectRatio)
        }
    }

    // Calculate the frame for aspect fit scaling of the asset
    private func calculateAspectFitFrame(assetSize: CGSize) -> CGRect {
        // Determine the scale factor to fit the asset in the current bounds
        let widthScale = bounds.size.width / assetSize.width
        let heightScale = bounds.size.height / assetSize.height
        let scale = min(widthScale, heightScale)
        return CGRect(origin: .zero, size: CGSize(width: assetSize.width * scale, height: assetSize.height * scale))
    }

    // Calculate the target frame based on the crop rectangle and asset size
    private func calculateTargetFrame(cropRect: CGRect, assetRect: CGRect, fitFrame: CGRect, adjustForAspectRatio: Bool = false) -> CGRect {
        // Determine the scaling factor needed for cropping
        let scale = max(assetRect.size.width / cropRect.size.width, assetRect.size.height / cropRect.size.height)
        var targetFrame = fitFrame.applying(CGAffineTransform(scaleX: scale, y: scale))

        // Calculate offset scaling relative to the crop rectangle and asset rectangle centers
        let xOffsetScale = (cropRect.midX - assetRect.midX) / assetRect.size.width
        let yOffsetScale = (cropRect.midY - assetRect.midY) / assetRect.size.height

        // Adjust the target frame origin based on the calculated offsets
        if adjustForAspectRatio {
            targetFrame.origin.x = 0.5 * (bounds.size.width - targetFrame.size.width) - xOffsetScale
            targetFrame.origin.y = 0.5 * (bounds.size.height - targetFrame.size.height) - yOffsetScale
        } else {
            targetFrame.origin.x = 0.5 * (bounds.size.width - targetFrame.size.width) - xOffsetScale * targetFrame.size.width
            targetFrame.origin.y = 0.5 * (bounds.size.height - targetFrame.size.height) - yOffsetScale * targetFrame.size.height
        }

        return targetFrame
    }
}
