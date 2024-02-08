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

    public var minWidthForItem: CGFloat? = YPConfig.library.minWidthForItem
    public var maxAspectRatio: CGFloat? = YPConfig.library.maxAspectRatio
    public var minAspectRatio: CGFloat? = YPConfig.library.minAspectRatio
    public var allowedAspectRatios: [CGFloat]? = YPConfig.library.allowedAspectRatios

    fileprivate var currentAsset: PHAsset?
    
    // Image view of the asset for convenience. Can be video preview image view or photo image view.
    public var assetImageView: UIImageView {
        return isVideoMode ? videoView.previewImageView : photoImageView
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
                         completion: @escaping () -> Void,
                         updateCropInfo: @escaping () -> Void) {
        mediaManager.imageManager?.fetchPreviewFor(video: video) { [weak self] preview in
            guard let strongSelf = self else { return }
            guard strongSelf.currentAsset != video else { completion() ; return }
            
            if strongSelf.videoView.isDescendant(of: strongSelf) == false {
                strongSelf.isVideoMode = true
                strongSelf.photoImageView.removeFromSuperview()
                strongSelf.addSubview(strongSelf.videoView)
            }
            
            strongSelf.videoView.setPreviewImage(preview)

            // calculate size from asset
            let videoSize = CGSize(width: video.pixelWidth, height: video.pixelHeight)
            strongSelf.setAssetFrame(for: strongSelf.videoView, with: videoSize)
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
            
                strongSelf.photoImageView.contentMode = .scaleAspectFill
                strongSelf.photoImageView.clipsToBounds = true
            }
            
            strongSelf.photoImageView.image = image
           
            strongSelf.setAssetFrame(for: strongSelf.photoImageView, with: image.size)
                
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
        photoImageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        videoView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        maximumZoomScale = 3.0
        minimumZoomScale = 1
        delegate = self
        if YPConfig.library.allowZoomToCrop {
            alwaysBounceHorizontal = true
            alwaysBounceVertical = true
        } else {
            maximumZoomScale = 1.0
            minimumZoomScale = 1.0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        fatalError("Only code layout.")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        zoomableViewDelegate?.ypAssetZoomableViewDidLayoutSubviews(self)
    }
}

// MARK: - Private

fileprivate extension YPAssetZoomableView {

    func setAssetFrame(`for` view: UIView, with size:CGSize) {
        // Reseting the previous scale
        self.minimumZoomScale = 1
        self.zoomScale = 1
        
        // Calculating and setting the image view frame depending on screenWidth
        let screenWidth = YPImagePickerConfiguration.screenWidth
        
        let w = size.width
        let h = size.height

        let aspectRatio: CGFloat = w / h
        var zoomScale: CGFloat = 1

        if w > h { // Landscape
            view.frame.size.width = screenWidth
            view.frame.size.height = screenWidth / aspectRatio
            
            // if the content aspect ratio is wider than minimum, then increase zoom scale so the sides are cropped off to maintain the minimum ar. This only applies to videos.
            if let maxAR = maxAspectRatio {
                if aspectRatio > maxAR  && isVideoMode {
                    let targetHeight = screenWidth / maxAR
                    zoomScale = targetHeight / view.frame.size.height
                }
            }
        } else if h > w { // Portrait
            view.frame.size.width = screenWidth * aspectRatio
            view.frame.size.height = screenWidth
            
            if let minWidth = minWidthForItem {
                let k = minWidth / screenWidth
                zoomScale = (h / w) * k
            }
            
            // if the content aspect ratio is taller than maximum, then increase zoom scale so the top and bottom are cropped off to maintain the maximum ar. This only applies to videos.
            if let minAR = minAspectRatio {
                if aspectRatio < minAR  && isVideoMode {
                    let targetWidth = view.frame.size.height * minAR
                    zoomScale = targetWidth / view.frame.size.width
                }
            }
        } else { // Square
            view.frame.size.width = screenWidth
            view.frame.size.height = screenWidth
        }

        if let allowedAspectRatios = allowedAspectRatios, !allowedAspectRatios.isEmpty, isVideoMode {
            var closestAllowedAspectRatio: CGFloat? = nil
            if h > w { // portrait
                // in this case, we need to find the next "larger" aspect ratio
                let ascendingAllowedAspectRatios = allowedAspectRatios.sorted(by: <)
                closestAllowedAspectRatio = ascendingAllowedAspectRatios.first(where: { $0 >= aspectRatio })
            } else if w > h { // landscape
                // in this case, we need to find the next "smaller" aspect ratio
                let descendingAllowedAspectRatios = allowedAspectRatios.sorted(by: >)
                closestAllowedAspectRatio = descendingAllowedAspectRatios.first(where: { $0 <= aspectRatio })
            } else { // square
                // in this case, we can pick whichever is closest
                closestAllowedAspectRatio = allowedAspectRatios.enumerated().min( by: { abs($0.1 - aspectRatio) < abs($1.1 - aspectRatio) } )?.element
            }
            if let closestAllowedAspectRatio = closestAllowedAspectRatio {
                if closestAllowedAspectRatio < aspectRatio {
                    let targetHeight = screenWidth / closestAllowedAspectRatio
                    zoomScale = targetHeight / view.frame.size.height
                } else {
                    let targetWidth = view.frame.size.height * closestAllowedAspectRatio
                    zoomScale = targetWidth / view.frame.size.width
                }
            }
        }

        // Centering image view
        view.center = center
        centerAssetView()
        
        // Setting new scale
        minimumZoomScale = zoomScale

        if isVideoMode {
            isScrollEnabled = true
            maximumZoomScale = 3.0
            if !YPConfig.library.allowZoomToCrop {
                maximumZoomScale = zoomScale
                minimumZoomScale = zoomScale
            }
        } else {
            isScrollEnabled = false // can't scroll for images
            maximumZoomScale = zoomScale
        }

        self.zoomScale = zoomScale
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
        let assetView = isVideoMode ? videoView : photoImageView
        let scrollViewBoundsSize = self.bounds.size
        var assetFrame = assetView.frame
        let assetSize = assetView.frame.size
        
        assetFrame.origin.x = (assetSize.width < scrollViewBoundsSize.width) ?
            (scrollViewBoundsSize.width - assetSize.width) / 2.0 : 0
        assetFrame.origin.y = (assetSize.height < scrollViewBoundsSize.height) ?
            (scrollViewBoundsSize.height - assetSize.height) / 2.0 : 0.0
        
        assetView.frame = assetFrame
    }
}

// MARK: UIScrollViewDelegate Protocol
extension YPAssetZoomableView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isVideoMode ? videoView : photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomableViewDelegate?.ypAssetZoomableViewScrollViewDidZoom()
        
        centerAssetView()
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
