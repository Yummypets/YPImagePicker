//
//  YPImageCropViewContainer.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 15/11/2016.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import UIKit
import Stevia
import AVFoundation

class YPImageCropViewContainer: UIView, YPImageCropViewDelegate, UIGestureRecognizerDelegate {
    
    public let playerLayer = AVPlayerLayer()
    public let grid = YPGridView()
    public let curtain = UIView()
    public let spinnerView = UIView()
    public let squareCropButton = UIButton()
    public let multipleSelectionButton = UIButton()
    public var onlySquareImages = false
    public var isShown = true
    public var isVideoMode = false {
        didSet {
            self.cropView?.isVideoMode = isVideoMode
            self.refresh()
        }
    }
    
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
    private let playImageView = UIImageView(image: imageFromBundle("yp_play"))
    private var cropView: YPImageCropView?
    private var shouldCropToSquare = false
    private var isMultipleSelection = false

    @objc
    public func squareCropButtonTapped() {
        if let cropView = cropView {
            let z = cropView.zoomScale
            if z >= 1 && z < cropView.squaredZoomScale {
                shouldCropToSquare = true
            } else {
                shouldCropToSquare = false
            }
        }
        cropView?.setFitImage(shouldCropToSquare, animated: true)
    }
    
    public func refreshSquareCropButton() {
        if onlySquareImages || isMultipleSelection {
            squareCropButton.isHidden = true
        } else {
            if isVideoMode {
                squareCropButton.isHidden = true
            } else if let image = cropView?.image {
                let isShowingSquareImage = image.size.width == image.size.height
                squareCropButton.isHidden = isShowingSquareImage
            }
        }
    }
    
    /// Use this to update the multiple selection mode UI state for the YPImageCropViewContainer
    public func setMultipleSelectionMode(on: Bool) {
        isMultipleSelection = on
        multipleSelectionButton.setImage(imageFromBundle(on ? "yp_multiple_colored" : "yp_multiple"), for: .normal)
        refreshSquareCropButton()
    }
    
    public func ypImageCropViewDidLayoutSubviews() {
        let newFrame = cropView!.imageView.convert(cropView!.imageView.bounds, to: self)
        grid.frame = frame.intersection(newFrame)
        grid.layoutIfNeeded()
    }
    
    public func ypImageCropViewscrollViewDidZoom() {
        if isShown && !isVideoMode {
            UIView.animate(withDuration: 0.1) {
                self.grid.alpha = 1
            }
        }
    }
    
    public func ypImageCropViewscrollViewDidEndZooming() {
        UIView.animate(withDuration: 0.3) {
            self.grid.alpha = 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(grid)
        grid.frame = frame
        clipsToBounds = true
        
        for sv in subviews {
            if let cv = sv as? YPImageCropView {
                cropView = cv
                cropView?.myDelegate = self
            }
        }
        
        grid.alpha = 0
        
        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        addGestureRecognizer(touchDownGR)
        touchDownGR.delegate = self
        
        let singleTapGR = UITapGestureRecognizer(target: self,
                                                 action: #selector(singleTap))
        singleTapGR.numberOfTapsRequired = 1
        singleTapGR.delegate = self
        addGestureRecognizer(singleTapGR)
        
        sv(
            spinnerView.sv(
                spinner
            ),
            playImageView,
            curtain
            )
        
        spinner.centerInContainer()
        spinnerView.fillContainer()
        playImageView.centerInContainer()
        curtain.fillContainer()
        
        spinner.startAnimating()
        spinnerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        playImageView.alpha = 0
        curtain.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        curtain.alpha = 0
        
        if !onlySquareImages {
            // Crop Button
            squareCropButton.setImage(imageFromBundle("yp_iconCrop"), for: .normal)
            sv(squareCropButton)
            squareCropButton.size(42)
            |-15-squareCropButton
            squareCropButton.Bottom == cropView!.Bottom - 15
        }
        
        // Multiple selection button
        sv(multipleSelectionButton)
        multipleSelectionButton.size(42)
        multipleSelectionButton-15-|
        multipleSelectionButton.setImage(imageFromBundle("yp_multiple"), for: .normal)
        multipleSelectionButton.Bottom == cropView!.Bottom - 15
        
        playerLayer.videoGravity = .resizeAspect
        layer.insertSublayer(playerLayer, below: spinnerView.layer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = frame
    }
    
    private func refresh() {
        refreshSquareCropButton()
    }
    
    @objc
    private func singleTap() {
        if isVideoMode {
            playerLayer.player?.togglePlayPause { isPlaying in
                UIView.animate(withDuration: 0.1) {
                    self.playImageView.alpha = isPlaying ? 0 : 0.8
                }
            }
        }
    }
}

extension YPImageCropViewContainer {
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
            if isShown && !isVideoMode {
                UIView.animate(withDuration: 0.1) {
                    self.grid.alpha = 1
                }
            }
        case .ended:
            UIView.animate(withDuration: 0.3) {
                self.grid.alpha = 0
            }
        default : ()
        }
    }
}
