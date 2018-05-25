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

protocol YPAssetZoomableViewDelegate: class {
    func ypAssetZoomableViewDidLayoutSubviews(_ zoomableView: YPAssetZoomableView)
    func ypAssetZoomableViewScrollViewDidZoom()
    func ypAssetZoomableViewScrollViewDidEndZooming()
}

final class YPAssetZoomableView: UIScrollView {
    public weak var myDelegate: YPAssetZoomableViewDelegate?
    public var cropAreaDidChange = {}
    public var squaredZoomScale: CGFloat = 1
    public var isVideoMode = false
    public var photoImageView = UIImageView()
    public var videoView = YPVideoView()
    
    // Image view of the asset for convenience. Can be video preview image view or photo image view.
    public var assetImageView: UIImageView {
        return isVideoMode ? videoView.previewImageView : photoImageView
    }

    /// Set zoom scale to fit the image to square or show the full image
    //
    /// - Parameters:
    ///   - fit: If true - zoom to show squared. If false - show full.
    public func fitImage(_ fit: Bool, animated isAnimated: Bool = false) {
        calculateSquaredZoomScale()
        if fit {
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
                         completion: @escaping () -> Void) {
        mediaManager.imageManager?.fetchPreviewFor(video: video) { [unowned self] preview in
            self.isVideoMode = true
            self.photoImageView.removeFromSuperview()
            
            if self.videoView.isDescendant(of: self) == false {
                self.addSubview(self.videoView)
            }
            
            self.setZoomScale(1, animated: false)
            
            self.videoView.setPreviewImage(preview)
            
            self.setAssetFrame(for: self.videoView, with: preview)
            
            // Fit video view if only squared
            if YPConfig.library.onlySquare {
                self.fitImage(true)
            }
            
            // Stored crop position in multiple selection
            if let scp = storedCropPosition {
                self.applyStoredCropPosition(scp)
            }
            
            completion()
        }
        mediaManager.imageManager?.fetchPlayerItem(for: video) { playerItem in
            self.videoView.loadVideo(playerItem)
            self.videoView.play()
        }
    }
    
    public func setImage(_ photo: PHAsset,
                         mediaManager: LibraryMediaManager,
                         storedCropPosition: YPLibrarySelection?,
                         completion: @escaping () -> Void) {
        mediaManager.imageManager?.fetch(photo: photo) { [unowned self] image, _ in
            self.isVideoMode = false
            self.videoView.showPlayImage(show: false)
            self.videoView.removeFromSuperview()
            self.videoView.deallocate()
            
            if self.photoImageView.isDescendant(of: self) == false {
                self.addSubview(self.photoImageView)
            }
            
            self.setZoomScale(1, animated: false)
            
            self.photoImageView.image = image
            self.photoImageView.contentMode = .scaleAspectFill
            self.photoImageView.clipsToBounds = true
            
            self.setAssetFrame(for: self.photoImageView, with: image)
            
            // Fit image if only squared
            if YPConfig.library.onlySquare {
                self.fitImage(true)
            }
            
            // Stored crop position in multiple selection
            if let scp = storedCropPosition {
                self.applyStoredCropPosition(scp)
            }

            completion()
        }
    }
    
    fileprivate func setAssetFrame(`for` view: UIView, with image: UIImage) {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        var squareZoomScale: CGFloat = 1.0
        let w = image.size.width
        let h = image.size.height
        
        if w > h { // Landscape
            squareZoomScale = (1.0 / (w / h))
            view.frame.size.width = screenWidth
            view.frame.size.height = screenWidth * squareZoomScale
        } else if h > w { // Portrait
            squareZoomScale = (1.0 / (h / w))
            view.frame.size.width = screenWidth * squareZoomScale
            view.frame.size.height = screenWidth
        } else { // Square
            view.frame.size.width = screenWidth
            view.frame.size.height = screenWidth
        }
        
        view.center = center
    }
    
    /// Calculate zoom scale which will fit the image to square
    fileprivate func calculateSquaredZoomScale() {
        guard let image = isVideoMode ? videoView.previewImageView.image : photoImageView.image else {
            print("YPAssetZoomableView >>> No image"); return
        }
        
        var squareZoomScale: CGFloat = 1.0
        let w = image.size.width
        let h = image.size.height
        
        if w > h { // Landscape
            squareZoomScale = (w / h)
        } else if h > w { // Portrait
            squareZoomScale = (h / w)
        }
        
        squaredZoomScale = squareZoomScale
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        frame.size      = CGSize.zero
        clipsToBounds   = true
        photoImageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        videoView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        maximumZoomScale = 6.0
        minimumZoomScale = 1
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator   = false
        delegate = self
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        isScrollEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        myDelegate?.ypAssetZoomableViewDidLayoutSubviews(self)
    }
}

// MARK: UIScrollViewDelegate Protocol
extension YPAssetZoomableView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isVideoMode ? videoView : photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        myDelegate?.ypAssetZoomableViewScrollViewDidZoom()
        
        let boundsSize = scrollView.bounds.size
        var contentsFrame = isVideoMode ? videoView.frame : photoImageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        if isVideoMode {
            videoView.frame = contentsFrame
        } else {
            photoImageView.frame = contentsFrame
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let view = view, view == photoImageView || view == videoView else { return }
        
        // prevent to zoom out
        if YPConfig.library.onlySquare && scale < squaredZoomScale {
            self.fitImage(true, animated: true)
        }
        
        myDelegate?.ypAssetZoomableViewScrollViewDidEndZooming()
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cropAreaDidChange()
    }
}
