//
//  YPAdjustableView.swift
//
//
//  Created by Will Saults on 1/15/24.
//

import Photos
import UIKit

public class YPAdjustableView: UIView {
    
    var assetContainer = UIView(frame: .zero)

    public var updateViewFrameAction: ((CGRect) -> Void)?

    public func adjustViewFrameIfNeeded(cropRect: CGRect, asset: PHAsset, targetAspectRatio: CGFloat?) {
        let assetSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))

        if let aspectRatio = targetAspectRatio, aspectRatio != assetSize.width / assetSize.height {
            adjustViewFrameForAspectRatio(cropRect: cropRect, aspectRatio: aspectRatio, assetSize: assetSize)
        } else {
            adjustViewFrame(cropRect: cropRect, assetSize: assetSize)
        }
    }

    public func adjustViewFrameIfNeeded(cropRect: CGRect, assetSize: CGSize, targetAspectRatio: CGFloat?) {
        if let aspectRatio = targetAspectRatio, aspectRatio != assetSize.width / assetSize.height {
            adjustViewFrameForAspectRatio(cropRect: cropRect, aspectRatio: aspectRatio, assetSize: assetSize)
        } else {
            adjustViewFrame(cropRect: cropRect, assetSize: assetSize)
        }
    }

    // Method to adjust the view frame considering the asset's original size
    private func adjustViewFrame(cropRect: CGRect, assetSize: CGSize) {
        let assetRect = CGRect(origin: .zero, size: assetSize)
        fitAspectAssetContainer(assetSize: assetSize)
        let assetFrame = calculateAssetFrame(cropRect: cropRect, assetSize: assetSize)
        DispatchQueue.main.async { [weak self] in
            self?.updateViewFrameAction?(assetFrame)
        }
    }

    // Method to adjust the view frame based on a target aspect ratio
    private func adjustViewFrameForAspectRatio(cropRect: CGRect, aspectRatio: CGFloat, assetSize: CGSize) {
        let adjustedAssetSize = adjustedSizeForAspectRatio(assetSize, aspectRatio: aspectRatio)
        fitAspectAssetContainer(assetSize: adjustedAssetSize)
        let assetFrame = calculateAssetFrame(cropRect: cropRect, assetSize: assetSize)
        DispatchQueue.main.async { [weak self] in
            self?.updateViewFrameAction?(assetFrame)
        }
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
    private func fitAspectAssetContainer(assetSize: CGSize) {
        // Determine the scale factor to fit the asset in the current bounds
        let widthScale = bounds.size.width / assetSize.width
        let heightScale = bounds.size.height / assetSize.height
        let scale = min(widthScale, heightScale)

        var origin: CGPoint = .zero

        if assetSize.width > assetSize.height {
            let yPosition = (bounds.size.height / 2) - (assetSize.height * scale / 2)
            origin = CGPoint(x: 0, y: yPosition)
        } else {
            let xPosition = (bounds.size.width / 2) - (assetSize.width * scale / 2)
            origin = CGPoint(x:xPosition, y: 0)
        }

        let frame = CGRect(origin: origin, size: CGSize(width: assetSize.width * scale, height: assetSize.height * scale))
        
        assetContainer.frame = frame
    }

    // Calculate the target frame based on the crop rectangle and asset size
    private func calculateAssetFrame(cropRect: CGRect, assetSize: CGSize) -> CGRect {
        // Determine the scaling factor needed for cropping
        let scale = assetContainer.frame.width / assetSize.width
        var assetFrame: CGRect = .zero

        if assetContainer.frame.size.width > assetContainer.frame.size.height {
            let zoomScale = assetSize.width / cropRect.size.width

            let scaleFactor = assetContainer.frame.size.width / assetSize.width
            let scaledHeight = scaleFactor * assetSize.height * zoomScale
            assetFrame.size = CGSize(width: assetContainer.frame.size.width * zoomScale, height: scaledHeight)

            assetFrame.origin.x = assetFrame.origin.x - (cropRect.origin.x * scaleFactor * zoomScale)
            assetFrame.origin.y = assetFrame.origin.y - (cropRect.origin.y * scaleFactor * zoomScale)
        } else {
            let zoomScale = assetSize.height / cropRect.size.height
            let scaleFactor = assetContainer.frame.size.height / assetSize.height
            let scaledWidth = scaleFactor * assetSize.width * zoomScale
            assetFrame.size = CGSize(width: scaledWidth, height: assetContainer.frame.size.height * zoomScale)

            assetFrame.origin.x = assetFrame.origin.x - (cropRect.origin.x * scaleFactor * zoomScale)
            assetFrame.origin.y = assetFrame.origin.y - (cropRect.origin.y * scaleFactor * zoomScale)
        }

        return assetFrame
    }
}
