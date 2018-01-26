//
//  YPLibraryVC + UIHelpers.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension YPLibraryVC {
        
    func display(photo asset: PHAsset, image: UIImage) {
        v.imageCropView.imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        v.imageCropView.image = image
        if configuration.onlySquareImagesFromLibrary {
            v.imageCropView.setFitImage(true)
            v.imageCropView.minimumZoomScale = v.imageCropView.squaredZoomScale
        }
        refreshCropControl()
    }
    
    func setVideoMode(_ isVideoMode: Bool) {
        v.imageCropViewContainer.isVideoMode = isVideoMode
    }
    
    func resetPlayer() {
        v.imageCropViewContainer.playerLayer.player?.pause()
        v.imageCropViewContainer.playerLayer.isHidden = true
    }
    
    func hideGrid() {
        v.imageCropViewContainer.grid.alpha = 0
    }
    
    func showLoader() {
        v.imageCropViewContainer.spinnerView.alpha = 1
    }
    
    func fadeOutLoader() {
        UIView.animate(withDuration: 0.2) {
            self.v.imageCropViewContainer.spinnerView.alpha = 0
        }
    }
    
    func refreshCropControl() {
        v.imageCropViewContainer.refreshSquareCropButton()
    }
    
    func setPreview(_ image: UIImage) {
        v.imageCropView.image = image
    }
    
    func fitImage(animated: Bool = true) {
        v.imageCropViewContainer.cropView?.setFitImage(true, animated: animated)
    }
    
    func play(videoItem: AVPlayerItem) {
        let player = AVPlayer(playerItem: videoItem)
        v.imageCropViewContainer.playerLayer.player = player
        v.imageCropViewContainer.playerLayer.isHidden = false
        v.imageCropViewContainer.spinnerView.alpha = 0
        player.play()
    }
    
    func downloadAndSetPreviewFor(video asset: PHAsset) {
        imageManager?.fetchPreviewFor(video: asset) { preview in
            // Prevent long images to come after user selected
            // another in the meantime.
            if self.latestImageTapped == asset.localIdentifier {
                DispatchQueue.main.async {
                    self.setPreview(preview)
                    self.fitImage(animated: false)
                }
            }
        }
    }
    
    func downloadAndPlay(video asset: PHAsset) {
        imageManager?.fetchPlayerItem(for: asset) { playerItem in
            // Prevent long videos to come after user selected another in the meantime.
            if self.latestImageTapped == asset.localIdentifier {
                self.play(videoItem: playerItem)
            }
        }
    }
}

