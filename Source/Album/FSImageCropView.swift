//
//  FZImageCropView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/16.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit

protocol FSImageCropViewDelegate: class {
    func fsImageCropViewDidLayoutSubviews()
    func fsImageCropViewscrollViewDidZoom()
    func fsImageCropViewscrollViewDidEndZooming()
}

final class FSImageCropView: UIScrollView, UIScrollViewDelegate {
    
    var isVideoMode = false {
        didSet {
            isUserInteractionEnabled = !isVideoMode
        }
    }
    var squaredZoomScale: CGFloat = 1
    weak var myDelegate: FSImageCropViewDelegate?
    var imageView = UIImageView()
    var imageSize: CGSize?
    var image: UIImage! = nil {
        didSet {
            
            minimumZoomScale = 1
            setZoomScale(1.0, animated: false)
            if image != nil {
                if !imageView.isDescendant(of: self) {
                    imageView.alpha = 1.0
                    addSubview(imageView)
                }
            } else {
                imageView.image = nil
                return
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
    
    func setFitImage(_ fit: Bool) {
        let animated = !YPImagePickerConfiguration.shared.onlySquareImages
        refreshZoomScale()
        if fit {
            setZoomScale(squaredZoomScale, animated: animated)
        } else {
            setZoomScale(1, animated: animated)
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
        
        if YPImagePickerConfiguration.shared.onlySquareImages {
            bouncesZoom = false
            bounces = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        myDelegate?.fsImageCropViewDidLayoutSubviews()
    }
    
    // MARK: UIScrollViewDelegate Protocol
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        myDelegate?.fsImageCropViewscrollViewDidZoom()
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
        myDelegate?.fsImageCropViewscrollViewDidEndZooming()
        contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
    }
}
