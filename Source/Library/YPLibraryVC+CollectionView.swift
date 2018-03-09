//
//  YPLibraryVC+CollectionView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension YPLibraryVC {
    func setupCollectionView() {
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        v.collectionView.register(YPLibraryViewCell.self, forCellWithReuseIdentifier: "YPLibraryViewCell")
    }
}

extension YPLibraryVC: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  mediaManager.fetchResult.count
    }
}

extension YPLibraryVC: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = mediaManager.fetchResult[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YPLibraryViewCell",
                                                            for: indexPath) as? YPLibraryViewCell else {
                                                                fatalError("unexpected cell in collection view")
        }
        cell.representedAssetIdentifier = asset.localIdentifier
        mediaManager.imageManager?.requestImage(for: asset,
                                   targetSize: v.cellSize(),
                                   contentMode: .aspectFill,
                                   options: nil) { image, _ in
                                    // The cell may have been recycled when the time this gets called
                                    // set image only if it's still showing the same asset.
                                    if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                                        cell.imageView.image = image
                                    }
        }
        
        let isVideo = (asset.mediaType == .video)
        cell.durationLabel.isHidden = !isVideo
        cell.durationLabel.text = isVideo ? formattedStrigFrom(asset.duration) : ""
        cell.multipleSelectionIndicator.isHidden = !multipleSelectionEnabled
        
        //reselect previously selected
        
//        if selectedIndices.contains(indexPath.row) {
            cell.isSelected = selectedIndices.contains(indexPath.row)
//        }

        
        
        // Prevent weird animation where thumbnail fills cell on first scrolls.
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        
        // If this is the only selected cell, do not deselect.
        if selectedIndices.count == 1 && selectedIndices.first == indexPath.row {
            return
        }
        
        changeImage(mediaManager.fetchResult[indexPath.row])
        panGestureHelper.resetToOriginalState()
        collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        v.refreshImageCurtainAlpha()

        if !multipleSelectionEnabled {
            let previouslySelectedIndices = selectedIndices
            selectedIndices.removeAll()
            if let selectedRow = previouslySelectedIndices.first {
                let previouslySelectedIndexPath = IndexPath(row: selectedRow, section: 0)
                collectionView.reloadItems(at: [previouslySelectedIndexPath])
            }
            
        }
        
        // If already selected, remove
        if let positionIndex = selectedIndices.index(of: indexPath.row) {
            selectedIndices.remove(at: positionIndex)
        } else {
            selectedIndices.append(indexPath.row)
        }
        collectionView.reloadItems(at: [indexPath])
        
    }
}

extension YPLibraryVC: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
}
