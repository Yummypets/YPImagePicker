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
    public var isPost: Bool = YPConfig.isPost
    public var portraitRatio: Double = YPConfig.portraitRatio
    public var photoLandscapeRatio: Double = YPConfig.photoLandscapeRatio
    public var videoLandscapeRatio: Double = YPConfig.videoLandscapeRatio
    public var assetType = 0
    public var isMediaFiting = false
    public var isCarouselAlbumUpdating = YPConfig.isCarouselAlbumUpdating
    public var carouselAlbumAspectRatio = YPConfig.carouselAlbumAspectRatio
    public var carouselAlbumAssetType = YPConfig.carouselAlbumAssetType
    public var isMultipleSelectionEnabled = false
    public var multipleSelectionAspectRatio = 0.805
    public var multipleSelectionAssetType = 0
    public var isFrameChanged = false
    
    // carousel
    private var currentZoomableViewWidthAnchor: NSLayoutConstraint! = nil
    private var currentZoomableViewHeightAnchor: NSLayoutConstraint! = nil
    
    fileprivate var currentAsset: PHAsset?
    
    // Image view of the asset for convenience. Can be video preview image view or photo image view.
    public var assetImageView: UIImageView {
        return isVideoMode ? videoView.previewImageView : photoImageView
    }
    
    public func changeFrameDimensionsToAlbumAspectRatio() {
        
        if(YPConfig.carouselAlbumAssetType == 0) {
            let carouselAlbumMediaHeight = YPImagePickerConfiguration.screenWidth
            let carouselAlbumMediaWidth = carouselAlbumMediaHeight * YPConfig.carouselAlbumAspectRatio

            if(self.currentZoomableViewWidthAnchor == nil  && self.currentZoomableViewHeightAnchor  == nil) {
                self.currentZoomableViewWidthAnchor = self.widthAnchor.constraint(equalToConstant: carouselAlbumMediaWidth)
                self.currentZoomableViewWidthAnchor.isActive = true
                self.currentZoomableViewHeightAnchor = self.heightAnchor.constraint(equalToConstant: carouselAlbumMediaHeight)
                self.currentZoomableViewHeightAnchor.isActive = true
            } else {
                self.currentZoomableViewWidthAnchor.constant = carouselAlbumMediaWidth
                self.currentZoomableViewHeightAnchor.constant = carouselAlbumMediaHeight
            }
            
            self.centerHorizontally()
            self.assetImageView.frame.origin.x = 0
        }
        
        if(YPConfig.carouselAlbumAssetType == 1) {
            let carouselAlbumMediaWidth = YPImagePickerConfiguration.screenWidth
            let carouselAlbumMediaHeight = carouselAlbumMediaWidth * YPConfig.carouselAlbumAspectRatio
            
            if(self.currentZoomableViewWidthAnchor == nil  && self.currentZoomableViewHeightAnchor  == nil) {
                self.currentZoomableViewWidthAnchor = self.widthAnchor.constraint(equalToConstant: carouselAlbumMediaWidth)
                self.currentZoomableViewWidthAnchor.isActive = true
                self.currentZoomableViewHeightAnchor = self.heightAnchor.constraint(equalToConstant: carouselAlbumMediaHeight)
                self.currentZoomableViewHeightAnchor.isActive = true
               
            } else {
                self.currentZoomableViewWidthAnchor.constant = carouselAlbumMediaWidth
                self.currentZoomableViewHeightAnchor.constant = carouselAlbumMediaHeight
            }
            
            self.assetImageView.frame.origin.y = 0
            self.centerVertically()
            self.layoutIfNeeded()
        }
        
        isFrameChanged = true
    }
    

    /// Set zoom scale to fit the image to square or show the full image
    //
    /// - Parameters:
    ///   - fit: If true - zoom to show squared. If false - show full.
    public func fitImage(_ fit: Bool, animated isAnimated: Bool = false) {
        isMediaFiting = true
        squaredZoomScale = calculateSquaredZoomScale()
        let correctAspectRatio = isCarouselAlbumUpdating ? carouselAlbumAspectRatio : multipleSelectionAspectRatio
        let correctAssetType = isCarouselAlbumUpdating ? carouselAlbumAssetType : multipleSelectionAssetType
         
            if isPost {
                if(!isMultipleSelectionEnabled && !isCarouselAlbumUpdating) {
                if fit {
                    setZoomScale(squaredZoomScale, animated: isAnimated)
                }  else {
                    if self.assetType == 0 {
                        setZoomScale(squaredZoomScale * portraitRatio, animated: isAnimated)
                    } else if self.assetType == 1 {
                        if(isVideoMode) {
                            setZoomScale(squaredZoomScale * videoLandscapeRatio, animated: isAnimated)
                        } else {
                            setZoomScale(squaredZoomScale * photoLandscapeRatio, animated: isAnimated)
                        }
         
                    } else if self.assetType == 2 {
                        setZoomScale(1, animated: isAnimated)
                    }
                }
                } else {
                    if(correctAssetType == 0) {
                        if(self.assetType == 0) {
                            setZoomScale(squaredZoomScale * correctAspectRatio, animated: isAnimated)
                        } else {
                            setZoomScale(squaredZoomScale, animated: isAnimated)
                        }
                    }
                    if(correctAssetType == 1) {
                        if(self.assetType == 1) {
                            setZoomScale(squaredZoomScale * correctAspectRatio, animated: isAnimated)
                        } else {
                            setZoomScale(squaredZoomScale, animated: isAnimated)
                        }
                    }
                    
                    if(correctAssetType == 2) {
                        setZoomScale(squaredZoomScale, animated: isAnimated)
                    }
                }
            } else {
                if fit {
                          setZoomScale(squaredZoomScale, animated: isAnimated)
                      } else {
                          setZoomScale(1, animated: isAnimated)
                      }
            }
        
        isMediaFiting = false
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
            
            strongSelf.setAssetFrame(for: strongSelf.videoView, with: preview)

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
           
            strongSelf.setAssetFrame(for: strongSelf.photoImageView, with: image)
                
            // Stored crop position in multiple selection
            if let scp173 = storedCropPosition {
                strongSelf.applyStoredCropPosition(scp173)
                // add update CropInfo after multiple
                updateCropInfo()
            }

            strongSelf.squaredZoomScale = strongSelf.calculateSquaredZoomScale()
            
            completion(isLowResIntermediaryImage)
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
        maximumZoomScale = 6.0
        minimumZoomScale = 1
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        delegate = self
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        isScrollEnabled = true
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
    
    func setAssetFrame(`for` view: UIView, with image: UIImage) {
            // Reseting the previous scale
            self.minimumZoomScale = 1
            self.zoomScale = 1
            
            // Calculating and setting the image view frame depending on screenWidth
            let screenWidth = YPImagePickerConfiguration.screenWidth
            
            let w = image.size.width
            let h = image.size.height

            var aspectRatio: CGFloat = 1
            var zoomScale: CGFloat = 1

            if w > h { // Landscape
                aspectRatio = h / w
                view.frame.size.width = screenWidth
                view.frame.size.height = screenWidth * aspectRatio
                self.assetType = 1
            } else if h > w { // Portrait
                aspectRatio = w / h
                view.frame.size.width = screenWidth * aspectRatio
                view.frame.size.height = screenWidth
                self.assetType = 0
                
                if let minWidth = minWidthForItem {
                    let k = minWidth / screenWidth
                    zoomScale = (h / w) * k
                }
            } else { // Square
                view.frame.size.width = screenWidth
                view.frame.size.height = screenWidth
                self.assetType = 2
            }
            
            // Centering image view
            view.center = center
            centerAssetView()
            
            // Setting new scale
            minimumZoomScale = zoomScale
            self.zoomScale = zoomScale

            fitImage(false)
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
       
        let frameAssetType = isCarouselAlbumUpdating ? YPConfig.carouselAlbumAssetType : multipleSelectionAssetType
        
        assetFrame.origin.x = (assetSize.width < scrollViewBoundsSize.width) ?
            (scrollViewBoundsSize.width - assetSize.width) / 2.0 : 0
        assetFrame.origin.y = (assetSize.height < scrollViewBoundsSize.height) ?
            (scrollViewBoundsSize.height - assetSize.height) / 2.0 : 0.0

    
        if(YPConfig.isCarouselAlbumUpdating) {
            if(isFrameChanged  && YPConfig.isPost && frameAssetType == 1) {
                assetFrame.origin.y = 0
            }
            
            if(!isFrameChanged  && YPConfig.isPost) {
                self.changeFrameDimensionsToAlbumAspectRatio()
            }
        }
    
        
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
        
        let correctAspectRatio = isCarouselAlbumUpdating ? carouselAlbumAspectRatio : multipleSelectionAspectRatio
        let correctAssetType = isCarouselAlbumUpdating ? carouselAlbumAssetType : multipleSelectionAssetType
        // prevent to zoom out
//        if YPConfig.library.onlySquare && scale < squaredZoomScale {
//            self.fitImage(true, animated: true)
//        }
        
        if(!isMultipleSelectionEnabled && !isCarouselAlbumUpdating) {
        if isPost {
                 if self.assetType == 0 {
                         if scale < squaredZoomScale * portraitRatio {
                             fitImage(false, animated: true)
                         }
                     } else if self.assetType == 1 {
                         if(isVideoMode) {
                             if scale < squaredZoomScale * videoLandscapeRatio {
                                 fitImage(false, animated: true)
                             }
                         } else {
                             if scale < squaredZoomScale * photoLandscapeRatio {
                                 fitImage(false, animated: true)
                             }
                         }
                     }
             }
        } else {
            if(correctAssetType == 0) {
                if(self.assetType == 0) {
                    if(scale < squaredZoomScale * correctAspectRatio) {
                        fitImage(false, animated: true)
                    }
                } else if (scale < squaredZoomScale) {
                    fitImage(false, animated: true)
                }
            }
            if(correctAssetType == 1) {
                if(self.assetType == 1) {
                    if(scale < squaredZoomScale * correctAspectRatio) {
                        fitImage(false, animated: true)
                    }
                } else if (scale < squaredZoomScale) {
                    fitImage(false, animated: true)
                }
            }
            if(correctAssetType == 2) {
                    if(scale < squaredZoomScale) {
                        fitImage(false, animated: true)
                    }
               
            }
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
