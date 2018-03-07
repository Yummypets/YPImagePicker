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
        v.refreshCropControl()
    }
    
    func play(videoItem: AVPlayerItem) {
        let player = AVPlayer(playerItem: videoItem)
        v.imageCropViewContainer.playerLayer.player = player
        v.imageCropViewContainer.playerLayer.isHidden = false
        v.imageCropViewContainer.spinnerView.alpha = 0
        player.play()
    }
    
    func downloadAndSetPreviewFor(video asset: PHAsset) {
        mediaManager.imageManager?.fetchPreviewFor(video: asset) { preview in
            // Prevent long images to come after user selected
            // another in the meantime.
            if self.latestImageTapped == asset.localIdentifier {
                DispatchQueue.main.async {
                    self.v.setPreview(preview)
                }
            }
        }
    }
    
    func downloadAndPlay(video asset: PHAsset) {
        mediaManager.imageManager?.fetchPlayerItem(for: asset) { playerItem in
            // Prevent long videos to come after user selected another in the meantime.
            if self.latestImageTapped == asset.localIdentifier {
                self.play(videoItem: playerItem)
            }
        }
    }
}
