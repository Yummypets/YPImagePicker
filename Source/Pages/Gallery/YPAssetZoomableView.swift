//
//  YPAssetZoomableView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/16.
//  Edited by Nik Kov || nik-kov.com on 2018/04
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Photos
import Stevia

protocol YPAssetZoomableViewDelegate: AnyObject {
    func ypAssetZoomableViewDidLayoutSubviews(_ zoomableView: YPAssetZoomableView)
    func ypAssetZoomableViewScrollViewDidZoom()
    func ypAssetZoomableViewScrollViewDidEndZooming()
}

final class YPAssetZoomableView: UIScrollView {
    public weak var zoomableViewDelegate: YPAssetZoomableViewDelegate?
    public var cropAreaDidChange = {}
    public var isVideoMode = false
    public var photoImageView = UIImageView()
    public var videoView = YPVideoView()
    public var squaredZoomScale: CGFloat = 1
    public var isMultipleSelectionEnabled = false

    public var minWidthForItem: CGFloat? = YPConfig.library.minWidthForItem
    public var maxAspectRatio: CGFloat? = YPConfig.library.maxAspectRatio
    public var minAspectRatio: CGFloat? = YPConfig.library.minAspectRatio
    
    fileprivate var currentAsset: PHAsset?
    private var originalAssetSize: CGSize = .zero

    // Image view of the asset for convenience. Can be video preview image view or photo image view.
    public var assetImageView: UIImageView {
        return isVideoMode ? videoView.previewImageView : photoImageView
    }

    public var assetView: UIView {
        isVideoMode ? videoView : photoImageView
    }

    /// Set zoom scale to fit the image to square or show the full image
    //
    /// - Parameters:
    ///   - fit: If true - zoom to show squared. If false - show full.
    public func fillImage(_ fill: Bool, animated isAnimated: Bool = false) {
        squaredZoomScale = calculateSquaredZoomScale()
        if fill {
            setZoomScale(squaredZoomScale, animated: isAnimated)
        } else {
            setZoomScale(1, animated: isAnimated)
        }
    }
    
    /// Re-apply correct scrollview settings if image has already been adjusted in
    /// multiple selection mode so that user can see where they left off.
    public func applyStoredCropPosition(_ scp: YPLibrarySelection) {
        // ZoomScale needs to be set first.
        if let zoomScale = scp.scrollViewZoomScale {
            setZoomScale(zoomScale, animated: false)
        }
        if let contentOffset = scp.scrollViewContentOffset {
            setContentOffset(contentOffset, animated: false)
        }
    }
    
    public func setVideo(_ video: PHAsset,
                         mediaManager: LibraryMediaManager,
                         storedCropPosition: YPLibrarySelection?,
                         customSize: CGSize? = nil,
                         completion: @escaping () -> Void,
                         updateCropInfo: @escaping () -> Void) {
        mediaManager.imageManager?.fetchPreviewFor(video: video) { [weak self] preview in
            guard let strongSelf = self else { return }
            guard strongSelf.currentAsset != video else { completion() ; return }

            if strongSelf.videoView.isDescendant(of: strongSelf) == false {
                strongSelf.isVideoMode = true
                strongSelf.photoImageView.removeFromSuperview()
                strongSelf.addSubview(strongSelf.videoView)

                strongSelf.videoView.Top == strongSelf.Top
                strongSelf.videoView.Bottom == strongSelf.Bottom
                strongSelf.videoView.Right == strongSelf.Right
                strongSelf.videoView.Left == strongSelf.Left
            }
            
            strongSelf.videoView.setPreviewImage(preview)

            // calculate size from asset
            strongSelf.originalAssetSize = CGSize(width: video.pixelWidth, height: video.pixelHeight)
            let videoSize = customSize ?? strongSelf.originalAssetSize

            strongSelf.setAssetFrame(with: videoSize)
            strongSelf.squaredZoomScale = strongSelf.calculateSquaredZoomScale()

            completion()

            // Stored crop position in multiple selection
            if let scp173 = storedCropPosition {
                strongSelf.applyStoredCropPosition(scp173)
                // MARK: add update CropInfo after multiple
                updateCropInfo()
            }
        }
        mediaManager.imageManager?.fetchPlayerItem(for: video) { [weak self] playerItem in
            guard let strongSelf = self else { return }
            guard strongSelf.currentAsset != video else { completion() ; return }
            strongSelf.currentAsset = video

            strongSelf.videoView.loadVideo(playerItem)
            strongSelf.videoView.play()
            strongSelf.zoomableViewDelegate?.ypAssetZoomableViewDidLayoutSubviews(strongSelf)
        }
    }
    
    public func setImage(_ photo: PHAsset,
                         mediaManager: LibraryMediaManager,
                         storedCropPosition: YPLibrarySelection?,
                         customSize: CGSize? = nil,
                         completion: @escaping (Bool) -> Void,
                         updateCropInfo: @escaping () -> Void) {
        guard currentAsset != photo else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        currentAsset = photo

        mediaManager.imageManager?.fetch(photo: photo) { [weak self] image, isLowResIntermediaryImage in
            guard let strongSelf = self else { return }

            if strongSelf.photoImageView.isDescendant(of: strongSelf) == false {
                strongSelf.isVideoMode = false
                strongSelf.videoView.removeFromSuperview()
                strongSelf.videoView.showPlayImage(show: false)
                strongSelf.videoView.deallocate()
                strongSelf.addSubview(strongSelf.photoImageView)

                strongSelf.photoImageView.Top == strongSelf.Top
                strongSelf.photoImageView.Bottom == strongSelf.Bottom
                strongSelf.photoImageView.Right == strongSelf.Right
                strongSelf.photoImageView.Left == strongSelf.Left

                strongSelf.photoImageView.contentMode = .scaleAspectFill
            }

            strongSelf.originalAssetSize = image.size
            let imageSize = customSize ?? strongSelf.originalAssetSize

            strongSelf.photoImageView.image = image

            strongSelf.setAssetFrame(with: imageSize)

            // Stored crop position in multiple selection
            if let scp173 = storedCropPosition {
                strongSelf.applyStoredCropPosition(scp173)
                // add update CropInfo after multiple
                updateCropInfo()
            }

            strongSelf.squaredZoomScale = strongSelf.calculateSquaredZoomScale()
            
            completion(isLowResIntermediaryImage)
            strongSelf.squaredZoomScale = strongSelf.calculateSquaredZoomScale()
        }
    }

    public func clearAsset() {
        isVideoMode = false
        videoView.removeFromSuperview()
        videoView.deallocate()
        photoImageView.removeFromSuperview()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = YPConfig.colors.assetViewBackgroundColor
        clipsToBounds = true

        photoImageView.translatesAutoresizingMaskIntoConstraints = false

        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.width(0)
        videoView.height(0)
        videoView.playerView.fillContainer()

        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        fatalError("Only code layout.")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        zoomableViewDelegate?.ypAssetZoomableViewDidLayoutSubviews(self)
    }

    func restoreAssetToOriginalSize() {
        setAssetFrame(with: originalAssetSize)
    }

    private func resizeZoomableView(size: CGSize) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let imageSize = self.assetImageView.image?.size else { return }

            let imageAspectRatio = imageSize.width / imageSize.height
            let containerAspectRatio = size.width / size.height

            self.widthConstraint?.constant = size.width
            self.heightConstraint?.constant = size.height

            if imageAspectRatio > containerAspectRatio {
                assetView.widthConstraint?.constant = size.height * imageAspectRatio
                assetView.heightConstraint?.constant = size.height

            } else {
                assetView.widthConstraint?.constant = size.width
                assetView.heightConstraint?.constant = size.width / imageAspectRatio
            }

            self.layoutIfNeeded()

            self.cropAreaDidChange()
        }
    }
}

// MARK: - Private

fileprivate extension YPAssetZoomableView {

    func getContainerSize(from size: CGSize) -> CGSize {
        let screenWidth = YPImagePickerConfiguration.screenWidth

        let w = size.width
        let h = size.height

        var containerWidth: CGFloat = 0.0
        var containerHeight: CGFloat = 0.0

        let aspectRatio: CGFloat = w / h

        if w > h { // Landscape
            containerWidth = screenWidth
            containerHeight = screenWidth / aspectRatio

            if let maxAR = maxAspectRatio {
                if aspectRatio > maxAR  && isVideoMode {
                    containerHeight = screenWidth / maxAR
                }
            }
        } else if h > w { // Portrait
            containerWidth = screenWidth * aspectRatio
            containerHeight = screenWidth

            if let minAR = minAspectRatio {
                if aspectRatio < minAR  && isVideoMode {
                    containerWidth = screenWidth * minAR
                }
            }

            if let minWidth = minWidthForItem {
                containerWidth = minWidth * aspectRatio
                containerHeight = minWidth
            }

        } else { // Square
            containerWidth = screenWidth
            containerHeight = screenWidth
        }

        return CGSize(width: containerWidth, height: containerHeight)
    }

    func setScrollView() {
        isScrollEnabled = isMultipleSelectionEnabled || isVideoMode
        
        zoomScale = 1
        minimumZoomScale = 1
        maximumZoomScale = isMultipleSelectionEnabled && YPConfig.library.allowZoomToCrop ? 3 : 1
    }

    func setAssetFrame(with size:CGSize) {

        let containerSize = getContainerSize(from: size)
        resizeZoomableView(size: containerSize)

        setScrollView()

        // Centering image view
        assetView.center = self.center
        DispatchQueue.main.async { [weak self] in
            self?.centerAssetView()
        }
    }
    
    /// Calculate zoom scale which will fit the image to square
    func calculateSquaredZoomScale() -> CGFloat {
        guard let image = assetImageView.image else {
            ypLog("No image"); return 1.0
        }
        
        var squareZoomScale: CGFloat = 1.0
        let w = image.size.width
        let h = image.size.height
        
        if w > h { // Landscape
            squareZoomScale = (w / h)
        } else if h > w { // Portrait
            squareZoomScale = (h / w)
        }
        
        return squareZoomScale
    }
    
    // Centring the image frame
    func centerAssetView() {
        let scrollViewBoundsSize = bounds.size
        var assetFrame = assetView.frame
        let assetSize = assetView.frame.size

        assetFrame.origin.x = (assetSize.width < scrollViewBoundsSize.width) ?
        (scrollViewBoundsSize.width - assetSize.width) / 2.0 : 0
        assetFrame.origin.y = (assetSize.height < scrollViewBoundsSize.height) ?
        (scrollViewBoundsSize.height - assetSize.height) / 2.0 : 0.0

        assetView.frame = assetFrame

        layoutIfNeeded()
    }
}

// MARK: UIScrollViewDelegate Protocol
extension YPAssetZoomableView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isVideoMode ? videoView : photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomableViewDelegate?.ypAssetZoomableViewScrollViewDidZoom()
        
        DispatchQueue.main.async { [weak self] in
            self?.centerAssetView()
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let view = view, view == photoImageView || view == videoView else { return }
        
        // prevent to zoom out
        if YPConfig.library.onlySquare && scale < squaredZoomScale {
            self.fillImage(true, animated: true)
        }
        
        zoomableViewDelegate?.ypAssetZoomableViewScrollViewDidEndZooming()
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cropAreaDidChange()
    }
}
