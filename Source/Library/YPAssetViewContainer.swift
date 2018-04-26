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
class YPAssetViewContainer: UIView {
    public var assetView: YPAssetZoomableView?
    public let grid = YPGridView()
    public let curtain = UIView()
    public let spinnerView = UIView()
    public let squareCropButton = UIButton()
    public let multipleSelectionButton = UIButton()
    public var onlySquare = YPConfig.onlySquareFromLibrary
    public var isShown = true
    
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
    private var shouldCropToSquare = false
    private var isMultipleSelection = false

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addSubview(grid)
        grid.frame = frame
        clipsToBounds = true
        
        for sv in subviews {
            if let cv = sv as? YPAssetZoomableView {
                assetView = cv
                assetView?.myDelegate = self
            }
        }
        
        grid.alpha = 0
        
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
        spinnerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        curtain.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        curtain.alpha = 0
        
        if !onlySquare {
            // Crop Button
            squareCropButton.setImage(YPConfig.icons.cropIcon, for: .normal)
            sv(squareCropButton)
            squareCropButton.size(42)
            |-15-squareCropButton
            squareCropButton.Bottom == assetView!.Bottom - 15
        }
        
        // Multiple selection button
        sv(multipleSelectionButton)
        multipleSelectionButton.size(42)
        multipleSelectionButton-15-|
        multipleSelectionButton.setImage(YPConfig.icons.multipleSelectionOffIcon, for: .normal)
        multipleSelectionButton.Bottom == assetView!.Bottom - 15
        
    }
    
    // MARK: - Square button

    @objc public func squareCropButtonTapped() {
        if let cropView = assetView {
            let z = cropView.zoomScale
            if z >= 1 && z < cropView.squaredZoomScale {
                shouldCropToSquare = true
            } else {
                shouldCropToSquare = false
            }
        }
        assetView?.setFitImage(shouldCropToSquare, animated: true)
    }
    
    public func refreshSquareCropButton() {
        if onlySquare {
            squareCropButton.isHidden = true
        } else {
            if let image = assetView?.image {
                let isShowingSquareImage = image.size.width == image.size.height
                squareCropButton.isHidden = isShowingSquareImage
            }
        }
    }
    
    // MARK: - Multiple selection

    /// Use this to update the multiple selection mode UI state for the YPAssetViewContainer
    public func setMultipleSelectionMode(on: Bool) {
        isMultipleSelection = on
        multipleSelectionButton.setImage(on ? YPConfig.icons.multipleSelectionOnIcon : YPConfig.icons.multipleSelectionOffIcon, for: .normal)
        refreshSquareCropButton()
    }
}

// MARK: - ZoomableViewDelegate
extension YPAssetViewContainer: YPAssetZoomableViewDelegate {
    public func ypAssetZoomableViewDidLayoutSubviews() {
        let newFrame = assetView!.assetImageView.convert(assetView!.assetImageView.bounds, to: self)
        grid.frame = frame.intersection(newFrame)
        grid.layoutIfNeeded()
    }
    
    public func ypAssetZoomableViewScrollViewDidZoom() {
        if isShown {
            UIView.animate(withDuration: 0.1) {
                self.grid.alpha = 1
            }
        }
    }
    
    public func ypAssetZoomableViewScrollViewDidEndZooming() {
        UIView.animate(withDuration: 0.3) {
            self.grid.alpha = 0
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
        return !(touch.view is UIButton)
    }
    
    @objc
    private func handleTouchDown(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            if isShown {
                UIView.animate(withDuration: 0.1) {
                    self.grid.alpha = 1
                }
            }
        case .ended:
            UIView.animate(withDuration: 0.3) {
                self.grid.alpha = 0
            }
        default: ()
        }
    }
}
