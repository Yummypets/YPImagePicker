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
    func ypAssetZoomableViewDidLayoutSubviews()
    func ypAssetZoomableViewScrollViewDidZoom()
    func ypAssetZoomableViewScrollViewDidEndZooming()
}

final class YPAssetZoomableView: UIScrollView {
    public weak var myDelegate: YPAssetZoomableViewDelegate?
    public var cropAreaDidChange = {}
    public var squaredZoomScale: CGFloat = 1
    public var isVideoMode = false
    public var photoImageView = UIImageView()
    public var image: UIImage! { didSet { didSetImage(image) }}
    public var videoView = YPVideoView()
    
    // Image view of the asset for convenience. Can be video preview image view or photo image view.
    public var assetImageView: UIImageView {
        return isVideoMode ? videoView.previewImageView : photoImageView
    }

    public func setVideo(video: PHAsset,
                  mediaManager: LibraryMediaManager,
                  completion: @escaping () -> Void) {
        isVideoMode = true
        photoImageView.removeFromSuperview()
        
        minimumZoomScale = 1
        setZoomScale(1.0, animated: false)
        
        if !videoView.isDescendant(of: self) {
            addSubview(videoView)
        }
     
        mediaManager.imageManager?.fetchPreviewFor(video: video) { preview in
            self.videoView.setPreviewImage(preview)
            self.setAssetFrame()
            self.videoView.center = self.center
            completion()
        }
        mediaManager.imageManager?.fetchPlayerItem(for: video) { playerItem in
            self.videoView.loadVideo(playerItem)
            self.videoView.play()
        }
    }
    
    fileprivate func didSetImage(_ image: UIImage) {
        isVideoMode = false
        videoView.removeFromSuperview()
        videoView.deallocate()
        
        minimumZoomScale = 1
        setZoomScale(1.0, animated: false)
        
        if !photoImageView.isDescendant(of: self) {
            addSubview(photoImageView)
        }
        
        self.photoImageView.center = center
        self.photoImageView.contentMode = .scaleAspectFill
        self.photoImageView.image = self.image
        photoImageView.clipsToBounds = true
        
        setAssetFrame()
    }
    
    fileprivate func setAssetFrame() {
        let view = isVideoMode ? videoView : photoImageView
        let image: UIImage = assetImageView.image!
        
        let screenSize: CGFloat = UIScreen.main.bounds.width
        view.frame.size.width = screenSize
        view.frame.size.height = screenSize
        
        var squareZoomScale: CGFloat = 1.0
        let w = image.size.width
        let h = image.size.height
        
        if w > h { // Landscape
            squareZoomScale = (1.0 / (w / h))
            view.frame.size.width = screenSize
            view.frame.size.height = screenSize * squareZoomScale
            
        } else if h > w { // Portrait
            squareZoomScale = (1.0 / (h / w))
            view.frame.size.width = screenSize * squareZoomScale
            view.frame.size.height = screenSize
        }
        
        refreshZoomScale()
    }
    
    func refreshZoomScale() {
        let image = isVideoMode ? videoView.previewImageView.image! : photoImageView.image!
        
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
    
    func setFitImage(_ fit: Bool, animated isAnimated: Bool = false) {
        refreshZoomScale()
        if fit {
            setZoomScale(squaredZoomScale, animated: isAnimated)
        } else {
            setZoomScale(1, animated: isAnimated)
        }
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
        
        if YPConfig.onlySquareFromLibrary {
            bouncesZoom = false
            bounces = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        myDelegate?.ypAssetZoomableViewDidLayoutSubviews()
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
        
        myDelegate?.ypAssetZoomableViewScrollViewDidEndZooming()
        contentSize = CGSize(width: view.frame.width + 1, height: view.frame.height + 1)
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cropAreaDidChange()
    }
}
