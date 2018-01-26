//
//  YPLibraryView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import Photos

final class YPLibraryView: UIView {
    
    let imageCropViewMinimalVisibleHeight: CGFloat  = 50
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageCropView: YPImageCropView!
    @IBOutlet weak var imageCropViewContainer: YPImageCropViewContainer!
    @IBOutlet weak var imageCropViewConstraintTop: NSLayoutConstraint!
    
    let line = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sv(
            line
        )
        
        layout(
            imageCropViewContainer,
            |line| ~ 1
        )
    
        line.backgroundColor = .white
    }
}

// MARK: - UI Helpers

extension YPLibraryView {
    
    class func xibView() -> YPLibraryView? {
        let bundle = Bundle(for: YPPickerVC.self)
        let nib = UINib(nibName: "YPLibraryView",
                        bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as? YPLibraryView
        return xibView
    }
    
    // MARK: - Mode (Photo/video)
    
    func setPhotoMode() {
        imageCropViewContainer.isVideoMode = false
    }
    
    func setVideoMode() {
        imageCropViewContainer.isVideoMode = true
    }
    
    // MARK: - Player
    
    var player: AVPlayer? {
        return imageCropViewContainer.playerLayer.player
    }
    
    func pausePlayer() {
        player?.pause()
    }
    
    func hidePlayer() {
        imageCropViewContainer.playerLayer.player?.pause()
        imageCropViewContainer.playerLayer.isHidden = true
    }
    
    // MARK: - Grid
    
    func hideGrid() {
        imageCropViewContainer.grid.alpha = 0
    }
    
    // MARK: - Preview
    
    func setPreview(_ image: UIImage) {
        imageCropView.image = image
    }
    
    // MARK: - Loader
    
    func showLoader() {
        imageCropViewContainer.spinnerView.alpha = 1
    }
    
    func fadeOutLoader() {
        UIView.animate(withDuration: 0.2) {
            self.imageCropViewContainer.spinnerView.alpha = 0
        }
    }
    
    // MARK: - Crop Control
    
    func refreshCropControl() {
        imageCropViewContainer.refreshSquareCropButton()
    }
    
    // MARK: - Crop Rect
    
    func currentCropRect() -> CGRect {
        guard let cropView = imageCropView else {
            return CGRect.zero
        }
        let normalizedX = min(1, cropView.contentOffset.x / cropView.contentSize.width)
        let normalizedY = min(1, cropView.contentOffset.y / cropView.contentSize.height)
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }
    
    // MARK: - Curtain
    
    func refreshImageCurtainAlpha() {
        let imageCurtainAlpha = abs(imageCropViewConstraintTop.constant)
            / (imageCropViewContainer.frame.height - imageCropViewMinimalVisibleHeight)
        imageCropViewContainer.curtain.alpha = imageCurtainAlpha
    }
    
    func cellSize() -> CGSize {
        let size = UIScreen.main.bounds.width/4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }
}
