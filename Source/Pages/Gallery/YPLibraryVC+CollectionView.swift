//
//  YPLibraryVC+CollectionView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension YPLibraryVC {
    var isLimitExceeded: Bool { return selectedItems.count >= YPConfig.library.maxNumberOfItems }
    
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
        if isMultipleSelectionEnabled || isProcessing || YPConfig.library.maxNumberOfItems <= 1 {
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
        toggleMultipleSelection()
        
        // Update preview.
        changeAsset(mediaManager.getAsset(at: indexPath.row))

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
        if let positionIndex = selectedItems.firstIndex(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
		}) {
            selectedItems.remove(at: positionIndex)

            // Refresh the numbers
            let selectedIndexPaths = selectedItems.map { IndexPath(row: $0.index, section: 0) }
			
            // Replace the current selected image with the previously selected one
            if let previouslySelectedIndexPath = selectedIndexPaths.last {
                currentlySelectedIndex = previouslySelectedIndexPath.row
                let asset = mediaManager.getAsset(with: selectedItems.last?.assetIdentifier)
                changeAsset(asset)
            }
            v.collectionView.reloadItems(at: selectedIndexPaths)
            checkLimit()
        }
    }
    
    /// Adds cell to selection
    func addToSelection(indexPath: IndexPath) {
        if !(delegate?.libraryViewShouldAddToSelection(indexPath: indexPath,
                                                       numSelections: selectedItems.count) ?? true) {
            return
        }
        guard let asset = mediaManager.getAsset(at: indexPath.item) else {
            ypLog("No asset to add to selection.")
            return
        }

        let newSelection = YPLibrarySelection(index: indexPath.row, assetIdentifier: asset.localIdentifier)
        selectedItems.append(newSelection)
        checkLimit()
    }
    
    func isInSelectionPool(indexPath: IndexPath) -> Bool {
        return selectedItems.contains(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
		})
    }
    
    /// Checks if there can be selected more items. If no - present warning.
    func checkLimit() {
        guard YPConfig.library.showMaxNumberWarning else { return }
        v.maxNumberWarningView.isHidden = !isLimitExceeded || isMultipleSelectionEnabled == false
    }
}

extension YPLibraryVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaManager.fetchResult?.count ?? 0
    }
}

extension YPLibraryVC: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YPLibraryViewCell", for: indexPath) as? YPLibraryViewCell else {
            fatalError("unexpected cell in collection view")
        }
        guard let asset = mediaManager.getAsset(at: indexPath.item) else {
            return cell
        }

        cell.representedAssetIdentifier = asset.localIdentifier
        cell.multipleSelectionIndicator.selectionColor =
            YPConfig.colors.multipleItemsSelectedCircleColor ?? YPConfig.colors.tintColor
        cell.multipleSelectionIndicator.selectionBorderColor =
            YPConfig.colors.multipleItemsSelectedCircleBorderColor ?? .clear
        cell.multipleSelectionIndicator.unselectedColor =
            YPConfig.colors.multipleItemsUnselectedCircleColor ?? .white.withAlphaComponent(0.3)
        cell.multipleSelectionIndicator.unselectedBorderColor =
            YPConfig.colors.multipleItemsUnselectedCircleBorderColor ?? .white
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

        if !YPImagePickerConfiguration.shared.allowPhotoAndVideoSelection {
            cell.multipleSelectionIndicator.isHidden = !isMultipleSelectionEnabled || (isMultipleSelectionEnabled && isVideo)
            cell.isUserInteractionEnabled = !(isMultipleSelectionEnabled && isVideo)
        } else {
            cell.multipleSelectionIndicator.isHidden = !isMultipleSelectionEnabled
            cell.isUserInteractionEnabled = true
        }


        cell.isSelected = !disableAutomaticCellSelection && currentlySelectedIndex == indexPath.row && selectedItems.contains(where: { $0.assetIdentifier == asset.localIdentifier })
        cell.isUserInteractionEnabled = true
        
        // Set correct selection number
        if let index = selectedItems.firstIndex(where: { $0.assetIdentifier == asset.localIdentifier }) {
            let currentSelection = selectedItems[index]
            if currentSelection.index < 0 {
                selectedItems[index] = YPLibrarySelection(index: indexPath.row,
                                                      cropRect: currentSelection.cropRect,
                                                      scrollViewContentOffset: currentSelection.scrollViewContentOffset,
                                                      scrollViewZoomScale: currentSelection.scrollViewZoomScale,
                                                      assetIdentifier: currentSelection.assetIdentifier)
            }
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

        changeAsset(mediaManager.getAsset(at: indexPath.row))
        panGestureHelper.resetToOriginalState()
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
            
        if isMultipleSelectionEnabled {
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelectedIndexPath.row == currentlySelectedIndex
            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected && !disableAutomaticCellSelection {
                    deselect(indexPath: indexPath)
                }
            } else if isLimitExceeded == false {
                addToSelection(indexPath: indexPath)
            }
            if (cellIsCurrentlySelected && !cellIsInTheSelectionPool) || !cellIsCurrentlySelected || disableAutomaticCellSelection {
                disableAutomaticCellSelection = false
                collectionView.cellForItem(at: indexPath)?.isSelected = true
            }

            collectionView.reloadItems(at: [indexPath, previouslySelectedIndexPath])
        } else if previouslySelectedIndexPath != indexPath {
            selectedItems.removeAll()
            addToSelection(indexPath: indexPath)
            
            // Force deseletion of previously selected cell.
            // In the case where the previous cell was loaded from iCloud, a new image was fetched
            // which triggered photoLibraryDidChange() and reloadItems() which breaks selection.
            //
            if let previousCell = collectionView.cellForItem(at: previouslySelectedIndexPath) as? YPLibraryViewCell {
                previousCell.isSelected = false
            }
            collectionView.reloadItems(at: [indexPath, previouslySelectedIndexPath])
        }
        disableAutomaticCellSelection = false
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

    public func collectionView(_ collectionView: UICollectionView,
							   layout collectionViewLayout: UICollectionViewLayout,
							   minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }

    public func collectionView(_ collectionView: UICollectionView,
							   layout collectionViewLayout: UICollectionViewLayout,
							   minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }
}
