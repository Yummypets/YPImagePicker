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
        cell.isSelected = currentlySelectedIndex == indexPath.row
        
        // Set correct selection number
        if let index = selectedIndices.index(of: indexPath.row) {
            cell.multipleSelectionIndicator.set(number: index + 1) // start at 1, not 0
        } else {
            cell.multipleSelectionIndicator.set(number: nil)
        }

        // Prevent weird animation where thumbnail fills cell on first scrolls.
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var previouslySelectedIndexPath: IndexPath?
        if let currentlySelectedIndex = currentlySelectedIndex {
            previouslySelectedIndexPath = IndexPath(row: currentlySelectedIndex, section: 0)
        }
        
        // If this is the only selected cell, do not deselect.
        if selectedIndices.count == 1 && selectedIndices.first == indexPath.row {
            return
        }
        
        changeImage(mediaManager.fetchResult[indexPath.row])
        panGestureHelper.resetToOriginalState()
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()

        if !multipleSelectionEnabled {
            let previouslySelectedIndices = selectedIndices
            selectedIndices.removeAll()
            if let selectedRow = previouslySelectedIndices.first {
                let previouslySelectedIndexPath = IndexPath(row: selectedRow, section: 0)
                collectionView.reloadItems(at: [previouslySelectedIndexPath])
            }
            
        }
        
        if multipleSelectionEnabled {
            let cellIsInTheSelectionPool = selectedIndices.contains(indexPath.row)
            let cellIsCurrentlySelected = indexPath.row == currentlySelectedIndex
            
            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected {
                    deselect(indexPath: indexPath)
                }
            } else {
                addToSelection(indexPath: indexPath)
            }
        }
        
        currentlySelectedIndex = indexPath.row
        collectionView.reloadItems(at: [indexPath])
        if let previouslySelectedIndexPath = previouslySelectedIndexPath {
            collectionView.reloadItems(at: [previouslySelectedIndexPath])
        }
    }
    
    func deselect(indexPath: IndexPath) {
        if let positionIndex = selectedIndices.index(of: indexPath.row) {
            selectedIndices.remove(at: positionIndex)
            // Refresh the numbers
            
            let selectedIndexPaths = selectedIndices.map { IndexPath(row: $0, section: 0 )}
            v.collectionView.reloadItems(at: selectedIndexPaths)
        }
    }
    
    func addToSelection(indexPath: IndexPath) {
        selectedIndices.append(indexPath.row) // Add cell to selection
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
