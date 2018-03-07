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
    
    let playerLayer = AVPlayerLayer()
    var isShown = true
    let grid = YPGridView()
    let curtain = UIView()
    let spinnerView = UIView()
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
    let squareCropButton = UIButton()
    var isVideoMode = false {
        didSet {
            self.cropView?.isVideoMode = isVideoMode
            self.refresh()
        }
    }
    var cropView: YPImageCropView?
    var shouldCropToSquare = false
    var onlySquareImages = false
    
    @objc
    func squareCropButtonTapped() {
        if let cropView = cropView {
            let z = cropView.zoomScale
            if z >= 1 && z < cropView.squaredZoomScale {
                shouldCropToSquare = true
            } else {
                shouldCropToSquare = false
            }
        }
        cropView?.setFitImage(shouldCropToSquare)
    }
    
    func refresh() {
        refreshSquareCropButton()
    }
    
    func refreshSquareCropButton() {
        if onlySquareImages {
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
        
        let touchDownGR = UILongPressGestureRecognizer(target: self, action: #selector(handleTouchDown))
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
            curtain
        )
        
        spinnerView.fillContainer()
        spinner.centerInContainer()
        curtain.fillContainer()
        
        spinner.startAnimating()
        spinnerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
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
        
        playerLayer.videoGravity = .resizeAspect
        layer.insertSublayer(playerLayer, below: spinnerView.layer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = frame
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
                                  otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
         return !(touch.view is UIButton)
    }
    
    @objc
    func handleTouchDown(sender: UILongPressGestureRecognizer) {
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
    
    func ypImageCropViewDidLayoutSubviews() {
        let newFrame = cropView!.imageView.convert(cropView!.imageView.bounds, to: self)
        grid.frame = frame.intersection(newFrame)
        grid.layoutIfNeeded()
    }
    
    func ypImageCropViewscrollViewDidZoom() {
        if isShown && !isVideoMode {
            UIView.animate(withDuration: 0.1) {
                self.grid.alpha = 1
            }
        }
    }
    
    func ypImageCropViewscrollViewDidEndZooming() {
        UIView.animate(withDuration: 0.3) {
            self.grid.alpha = 0
        }
    }
    
    @objc
    func singleTap() {
        if isVideoMode {
            playerLayer.player?.togglePlayPause()
        }
    }
}
