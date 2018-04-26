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
        v.assetZoomableView.image = image
        v.assetZoomableView.setFitImage(true)
        if YPConfig.onlySquareFromLibrary {
            v.assetZoomableView.minimumZoomScale = v.assetZoomableView.squaredZoomScale
        }
        v.assetViewContainer.refreshSquareCropButton()
        
        // Re-apply correct scrollview settings if image has already been adjusted in
        // multiple selection mode so that user can see where they left off.
        if let currentlySelectedIndex = currentlySelectedIndex,
            multipleSelectionEnabled,
            selection.contains(where: { $0.index == currentlySelectedIndex }) {
            guard let selectedAssetIndex = selection.index(where: { $0.index == currentlySelectedIndex }) else {
                return
            }
            let selectedAsset = selection[selectedAssetIndex]
            // ZoomScale needs to be set first.
            if let zoomScale = selectedAsset.scrollViewZoomScale {
                v.assetZoomableView.zoomScale = zoomScale
            }
            if let contentOffset = selectedAsset.scrollViewContentOffset {
                v.assetZoomableView.contentOffset = contentOffset
            }
        }
    }
}
