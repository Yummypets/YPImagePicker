//
//  YPAssetViewContainer.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 15/11/2016.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import UIKit
import Stevia
import AVFoundation

/// The container for asset (video or image). It containts the YPGridView and YPAssetZoomableView.
final class YPAssetViewContainer: UIView {

    public var zoomableView: YPAssetZoomableView
    public var itemOverlay: UIView?
    public let curtain = UIView()
    public let spinnerView = UIView()
    public let squareCropButton = UIButton()
    public let multipleSelectionButton: UIButton = {
        let v = UIButton()
        v.setImage(YPConfig.icons.multipleSelectionOffIcon, for: .normal)
        return v
    }()
    public var onlySquare = YPConfig.library.onlySquare
    public var isShown = true
    public var spinnerIsShown = false
    
    private let spinner = UIActivityIndicatorView(style: .white)
    private var shouldCropToSquare = YPConfig.library.isSquareByDefault
    private var isMultipleSelectionEnabled = false
  
    // carousel
    private var currentZoomableViewWidthAnchor: NSLayoutConstraint! = nil
    private var currentZoomableViewHeightAnchor: NSLayoutConstraint! = nil
    
    private var currentViewWidthAnchor: NSLayoutConstraint! = nil
    private var currentViewHeightAnchor: NSLayoutConstraint! = nil
    
    public var itemOverlayType = YPConfig.library.itemOverlayType

    init(frame: CGRect, zoomableView: YPAssetZoomableView) {
        self.zoomableView = zoomableView
        super.init(frame: frame)

        self.zoomableView.zoomableViewDelegate = self
        switch itemOverlayType {
        case .grid:
            itemOverlay = YPGridView()
        default:
            break
        }

        if let itemOverlay = itemOverlay {
            addSubview(itemOverlay)
            itemOverlay.frame = frame
            clipsToBounds = true
        
            itemOverlay.alpha = 0
        }

        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        touchDownGR.delegate = self
        addGestureRecognizer(touchDownGR)

        // TODO: Add tap gesture to play/pause. Add double tap gesture to square/unsquare

        sv(
            spinnerView.sv(
                spinner
            ),
            curtain
        )

        spinner.centerInContainer()
        spinnerView.fillContainer()
        curtain.fillContainer()

        spinner.startAnimating()
        spinnerView.backgroundColor = UIColor.ypLabel.withAlphaComponent(0.3)
        curtain.backgroundColor = UIColor.ypLabel.withAlphaComponent(0.7)
        curtain.alpha = 0

        if ((!YPConfig.isCarouselAlbumUpdating && !YPConfig.library.defaultMultipleSelection) && !onlySquare) {
            // Crop Button
            squareCropButton.setImage(YPConfig.icons.cropIcon, for: .normal)
            sv(squareCropButton)
            squareCropButton.size(42)
            |-15-squareCropButton
            squareCropButton.Bottom == self.Bottom - 15
        }

        // Multiple selection button
        sv(multipleSelectionButton)
        multipleSelectionButton.size(42).trailing(15)
        multipleSelectionButton.Bottom == self.Bottom - 15
    }

    required init?(coder: NSCoder) {
        zoomableView = YPAssetZoomableView()
        super.init(coder: coder)
        fatalError("Only code layout.")
    }

    // MARK: - Square button

    @objc public func squareCropButtonTapped() {
        let z = zoomableView.zoomScale
        shouldCropToSquare = (z >= 1 && z < zoomableView.squaredZoomScale)
        zoomableView.fitImage(shouldCropToSquare, animated: true)
    }
    
    /// Update only UI of square crop button.
    public func updateSquareCropButtonState() {
        if(YPConfig.isCarouselAlbumUpdating || YPConfig.library.defaultMultipleSelection) {
            squareCropButton.isHidden = true
        }
        
        guard !isMultipleSelectionEnabled else {
            // If multiple selection enabled, the squareCropButton is not visible
            squareCropButton.isHidden = true
            return
        }
        guard !onlySquare else {
            // If only square enabled, than the squareCropButton is not visible
            squareCropButton.isHidden = true
            return
        }
        guard let selectedAssetImage = zoomableView.assetImageView.image else {
            // If no selected asset, than the squareCropButton is not visible
            squareCropButton.isHidden = true
            return
        }

        let isImageASquare = selectedAssetImage.size.width == selectedAssetImage.size.height
        squareCropButton.isHidden = isImageASquare
    }
    
    // MARK: - Multiple selection

    /// Use this to update the multiple selection mode UI state for the YPAssetViewContainer
    public func setMultipleSelectionMode(on: Bool) {
        isMultipleSelectionEnabled = on
        let image = on ? YPConfig.icons.multipleSelectionOnIcon : YPConfig.icons.multipleSelectionOffIcon
        multipleSelectionButton.setImage(image, for: .normal)
        updateSquareCropButtonState()
        if(!YPConfig.isCarouselAlbumUpdating && !YPConfig.library.defaultMultipleSelection) {
            changeFrameDimensionsToSelectedMediaAspectRatio()
        }
    }
    
    
    public func changeFrameDimensionsToSelectedMediaAspectRatio () {
        let selectedMedia = self.zoomableView.isVideoMode ? self.zoomableView.videoView : self.zoomableView.assetImageView
  
        if(isMultipleSelectionEnabled) {
            self.zoomableView.isMultipleSelectionEnabled = true
            if(selectedMedia.frame.size.width < YPImagePickerConfiguration.screenWidth) {
                let carouselAlbumMediaWidth = selectedMedia.frame.size.width
                let carouselAlbumMediaHeight = YPImagePickerConfiguration.screenWidth
                self.zoomableView.multipleSelectionAspectRatio = selectedMedia.frame.size.width / YPImagePickerConfiguration.screenWidth
                self.zoomableView.multipleSelectionAssetType = 0
                
                if(self.currentZoomableViewWidthAnchor == nil  && self.currentZoomableViewHeightAnchor  == nil) {
                    self.currentZoomableViewWidthAnchor = self.zoomableView.widthAnchor.constraint(equalToConstant: carouselAlbumMediaWidth)
                    self.currentZoomableViewWidthAnchor.isActive = true
                    self.currentZoomableViewHeightAnchor = self.zoomableView.heightAnchor.constraint(equalToConstant: carouselAlbumMediaHeight)
                    self.currentZoomableViewHeightAnchor.isActive = true
                } else {
                    self.currentZoomableViewWidthAnchor.constant = carouselAlbumMediaWidth
                    self.currentZoomableViewHeightAnchor.constant = carouselAlbumMediaHeight
                }
                
                self.zoomableView.centerHorizontally()
                selectedMedia.frame.origin.x = 0
           
             
                
            } else if (selectedMedia.frame.size.width > selectedMedia.frame.size.height && selectedMedia.frame.size.height < YPImagePickerConfiguration.screenWidth) {
                let carouselAlbumMediaWidth = YPImagePickerConfiguration.screenWidth
                let carouselAlbumMediaHeight = selectedMedia.frame.size.height
                self.zoomableView.multipleSelectionAspectRatio = carouselAlbumMediaHeight / carouselAlbumMediaWidth
                self.zoomableView.multipleSelectionAssetType = 1
                if(self.currentZoomableViewWidthAnchor == nil  && self.currentZoomableViewHeightAnchor  == nil) {
                    self.currentZoomableViewWidthAnchor = self.zoomableView.widthAnchor.constraint(equalToConstant: carouselAlbumMediaWidth)
                    self.currentZoomableViewWidthAnchor.isActive = true
                    self.currentZoomableViewHeightAnchor = self.zoomableView.heightAnchor.constraint(equalToConstant: carouselAlbumMediaHeight)
                    self.currentZoomableViewHeightAnchor.isActive = true
                } else {
                    self.currentZoomableViewWidthAnchor.constant = carouselAlbumMediaWidth
                    self.currentZoomableViewHeightAnchor.constant = carouselAlbumMediaHeight
                }
                if(self.currentViewWidthAnchor == nil  && self.currentViewHeightAnchor == nil) {
                    self.currentViewWidthAnchor = self.widthAnchor.constraint(equalToConstant: YPImagePickerConfiguration.screenWidth)
                    self.currentViewWidthAnchor.isActive = true
                    self.currentViewHeightAnchor = self.heightAnchor.constraint(equalToConstant: YPImagePickerConfiguration.screenWidth)
                    self.currentViewHeightAnchor.isActive = true
                } else {
                    self.currentViewWidthAnchor.constant = YPImagePickerConfiguration.screenWidth
                    self.currentViewHeightAnchor.constant = YPImagePickerConfiguration.screenWidth
                }
            
                selectedMedia.frame.origin.y = 0
                self.zoomableView.centerVertically()
            }  else if (selectedMedia.frame.size.width >= YPImagePickerConfiguration.screenWidth) {
                self.zoomableView.multipleSelectionAssetType = 2
            }
            
        } else {
            self.zoomableView.isMultipleSelectionEnabled = false
            if(self.currentZoomableViewWidthAnchor != nil  && self.currentZoomableViewHeightAnchor != nil) {
                self.currentZoomableViewWidthAnchor.constant = YPImagePickerConfiguration.screenWidth
                self.currentZoomableViewHeightAnchor.constant = YPImagePickerConfiguration.screenWidth
                self.zoomableView.centerVertically()
                self.zoomableView.fitImage(true, animated:true)
            }
        }
          self.zoomableView.layoutIfNeeded()
    }
}

// MARK: - ZoomableViewDelegate
extension YPAssetViewContainer: YPAssetZoomableViewDelegate {
    public func ypAssetZoomableViewDidLayoutSubviews(_ zoomableView: YPAssetZoomableView) {
        let newFrame = zoomableView.assetImageView.convert(zoomableView.assetImageView.bounds, to: self)
        
        if let itemOverlay = itemOverlay {
            // update grid position
            itemOverlay.frame = frame.intersection(newFrame)
            itemOverlay.layoutIfNeeded()
        }
        
        // Update play imageView position - bringing the playImageView from the videoView to assetViewContainer,
        // but the controll for appearing it still in videoView.
        if zoomableView.videoView.playImageView.isDescendant(of: self) == false {
            self.addSubview(zoomableView.videoView.playImageView)
            zoomableView.videoView.playImageView.centerInContainer()
        }
    }
    
    public func ypAssetZoomableViewScrollViewDidZoom() {
        guard let itemOverlay = itemOverlay else {
            return
        }
        if isShown {
            UIView.animate(withDuration: 0.1) {
                itemOverlay.alpha = 1
            }
        }
    }
    
    public func ypAssetZoomableViewScrollViewDidEndZooming() {
        guard let itemOverlay = itemOverlay else {
            return
        }
        UIView.animate(withDuration: 0.3) {
            itemOverlay.alpha = 0
        }
    }
}

// MARK: - Gesture recognizer Delegate
extension YPAssetViewContainer: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !spinnerIsShown && !(touch.view is UIButton)
    }
    
    @objc
    private func handleTouchDown(sender: UILongPressGestureRecognizer) {
        guard let itemOverlay = itemOverlay else {
            return
        }
        switch sender.state {
        case .began:
            if isShown {
                UIView.animate(withDuration: 0.1) {
                    itemOverlay.alpha = 1
                }
            }
        case .ended:
            UIView.animate(withDuration: 0.3) {
                itemOverlay.alpha = 0
            }
        default: ()
        }
    }
}
