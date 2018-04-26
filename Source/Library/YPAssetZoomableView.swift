//
//  YPAssetZoomableView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/16.
//  Edited by Nik Kov || nik-kov.com on 2018/04
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

protocol YPAssetZoomableViewDelegate: class {
    func ypAssetZoomableViewDidLayoutSubviews()
    func ypAssetZoomableViewScrollViewDidZoom()
    func ypAssetZoomableViewScrollViewDidEndZooming()
}

final class YPAssetZoomableView: UIScrollView {
    weak var myDelegate: YPAssetZoomableViewDelegate?
    var isVideoMode = false

    var cropAreaDidChange = {}
    var imageSize: CGSize?
    var squaredZoomScale: CGFloat = 1
    var onlySquareImages = false { didSet {
            bouncesZoom = false
            bounces = false
        }}

    public var imageView = UIImageView()
    public var image: UIImage! { didSet { didSetImage(image) }}
    public var videoView = YPVideoView()
    public var video: AVPlayerItem! { didSet { didSetVideo(video) }}
    
    func didSetVideo(_ video: AVPlayerItem) {
        videoView.frame = frame
        addSubview(videoView)
        videoView.loadVideo(video)
    }

    func didSetImage(_ image: UIImage) {
        minimumZoomScale = 1
        setZoomScale(1.0, animated: false)
        
        if !imageView.isDescendant(of: self) {
            imageView.alpha = 1.0
            addSubview(imageView)
        }
        
        if isVideoMode {
            imageView.frame = frame
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            contentSize = CGSize.zero
            return
        }
        
        let screenSize: CGFloat = UIScreen.main.bounds.width
        self.imageView.frame.size.width = screenSize
        self.imageView.frame.size.height = screenSize
        
        var squareZoomScale: CGFloat = 1.0
        let w = image.size.width
        let h = image.size.height
        
        if w > h { // Landscape
            squareZoomScale = (1.0 / (w / h))
            self.imageView.frame.size.width = screenSize
            self.imageView.frame.size.height = screenSize*squareZoomScale
            
        } else if h > w { // Portrait
            squareZoomScale = (1.0 / (h / w))
            self.imageView.frame.size.width = screenSize*squareZoomScale
            self.imageView.frame.size.height = screenSize
        }
        
        self.imageView.center = center
        
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.image = self.image
        imageView.clipsToBounds = true
        
        refreshZoomScale()
    }
    
    func refreshZoomScale() {
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
        // uncomment if need animation
//        let animated = isAnimated ?? !onlySquareImages
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
        imageView.alpha = 0.0
        imageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
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
        myDelegate?.ypAssetZoomableViewDidLayoutSubviews()
    }
}

extension YPAssetZoomableView: UIScrollViewDelegate {
    
    // MARK: UIScrollViewDelegate Protocol
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isVideoMode ? videoView : imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        myDelegate?.ypAssetZoomableViewScrollViewDidZoom()
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
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
        imageView.frame = contentsFrame
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        myDelegate?.ypAssetZoomableViewScrollViewDidEndZooming()
        contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        cropAreaDidChange()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cropAreaDidChange()
    }
}
