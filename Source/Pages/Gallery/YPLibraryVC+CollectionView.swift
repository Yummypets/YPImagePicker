//
//  YPLibraryVC+CollectionView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension YPLibraryVC {
    var isLimitExceeded: Bool { return selection.count >= YPConfig.library.maxNumberOfItems }
    
    func setupCollectionView() {
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        v.collectionView.register(YPLibraryViewCell.self, forCellWithReuseIdentifier: "YPLibraryViewCell")
        
        // Long press on cell to enable multiple selection
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        v.collectionView.addGestureRecognizer(longPressGR)
    }
    
    /// When tapping on the cell with long press, clear all previously selected cells.
    @objc func handleLongPress(longPressGR: UILongPressGestureRecognizer) {
        if multipleSelectionEnabled || isProcessing || YPConfig.library.maxNumberOfItems <= 1 {
            return
        }
        
        if longPressGR.state == .began {
            let point = longPressGR.location(in: v.collectionView)
            guard let indexPath = v.collectionView.indexPathForItem(at: point) else {
                return
            }
            startMultipleSelection(at: indexPath)
        }
    }
    
    func startMultipleSelection(at indexPath: IndexPath) {
        currentlySelectedIndex = indexPath.row
        multipleSelectionButtonTapped()
        
        // Update preview.
        changeAsset(mediaManager.fetchResult[indexPath.row])
        
        // Bring preview down and keep selected cell visible.
        panGestureHelper.resetToOriginalState()
        if !panGestureHelper.isImageShown {
            v.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
    }
    
    // MARK: - Library collection view cell managing
    
    /// Removes cell from selection
    func deselect(indexPath: IndexPath) {
        if let positionIndex = selection.index(where: { $0.assetIdentifier == mediaManager.fetchResult[indexPath.row].localIdentifier }) {
            selection.remove(at: positionIndex)

            // Refresh the numbers
            var selectedIndexPaths = [IndexPath]()
            mediaManager.fetchResult.enumerateObjects { [unowned self] (asset, index, _) in
                if self.selection.contains(where: { $0.assetIdentifier == asset.localIdentifier }) {
                    selectedIndexPaths.append(IndexPath(row: index, section: 0))
                }
            }
            v.collectionView.reloadItems(at: selectedIndexPaths)

            checkLimit()
        }
    }
    
    /// Adds cell to selection
    func addToSelection(indexPath: IndexPath) {
        let asset = mediaManager.fetchResult[indexPath.item]
        selection.append(
            YPLibrarySelection(
                index: indexPath.row,
                assetIdentifier: asset.localIdentifier
            )
        )
        checkLimit()
    }
    
    func isInSelectionPool(indexPath: IndexPath) -> Bool {
        return selection.contains(where: { $0.assetIdentifier == mediaManager.fetchResult[indexPath.row].localIdentifier })
    }
    
    /// Checks if there can be selected more items. If no - present warning.
    func checkLimit() {
        v.maxNumberWarningView.isHidden = !isLimitExceeded || multipleSelectionEnabled == false
    }
}

extension YPLibraryVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaManager.fetchResult.count
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
        cell.multipleSelectionIndicator.selectionColor = YPConfig.colors.multipleItemsSelectedCircleColor
                                                            ?? YPConfig.colors.tintColor
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
        cell.durationLabel.text = isVideo ? YPHelper.formattedStrigFrom(asset.duration) : ""
        cell.multipleSelectionIndicator.isHidden = !multipleSelectionEnabled
        cell.isSelected = currentlySelectedIndex == indexPath.row
        
        // Set correct selection number
        if let index = selection.index(where: { $0.assetIdentifier == asset.localIdentifier }) {
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
        let previouslySelectedIndexPath = IndexPath(row: currentlySelectedIndex, section: 0)
        currentlySelectedIndex = indexPath.row

        changeAsset(mediaManager.fetchResult[indexPath.row])
        panGestureHelper.resetToOriginalState()
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()

        if multipleSelectionEnabled {
            
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelectedIndexPath.row == currentlySelectedIndex

            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected {
                    deselect(indexPath: indexPath)
                }
            } else if isLimitExceeded == false {
                addToSelection(indexPath: indexPath)
            }
        } else {
            let previouslySelectedIndices = selection
            selection.removeAll()
            addToSelection(indexPath: indexPath)
            if let selectedRow = previouslySelectedIndices.first?.index {
                let previouslySelectedIndexPath = IndexPath(row: selectedRow, section: 0)
                collectionView.reloadItems(at: [previouslySelectedIndexPath])
            }
        }

        collectionView.reloadItems(at: [indexPath])
        collectionView.reloadItems(at: [previouslySelectedIndexPath])
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return isProcessing == false
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return isProcessing == false
    }
}

extension YPLibraryVC: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margins = YPConfig.library.spacingBetweenItems * CGFloat(YPConfig.library.numberOfItemsInRow - 1)
        let width = (collectionView.frame.width - margins) / CGFloat(YPConfig.library.numberOfItemsInRow)
        return CGSize(width: width, height: width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }
}
