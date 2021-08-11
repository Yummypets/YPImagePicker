//
//  YPLibrary+LibraryChange.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension YPLibraryVC: PHPhotoLibraryChangeObserver {
    func registerForLibraryChanges() {
        PHPhotoLibrary.shared().register(self)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = self.mediaManager.fetchResult,
              let collectionChanges = changeInstance.changeDetails(for: fetchResult) else {
            return
        }

        DispatchQueue.main.async {
            self.mediaManager.fetchResult = collectionChanges.fetchResultAfterChanges
            let collectionView = self.v.collectionView!
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                collectionView.reloadData()
            } else {
                collectionView.performBatchUpdates({
                    let removedIndexes = collectionChanges.removedIndexes
                    if (removedIndexes?.count ?? 0) != 0 {
                        collectionView.deleteItems(at: removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                    }
                    let insertedIndexes = collectionChanges.insertedIndexes
                    if (insertedIndexes?.count ?? 0) != 0 {
                        collectionView.insertItems(at: insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                    }
                }, completion: { finished in
                    if finished {
                        let changedIndexes = collectionChanges.changedIndexes
                        if (changedIndexes?.count ?? 0) != 0 {
                            collectionView.reloadItems(at: changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                    }
                })

            }

            self.updateAssetSelection()
            self.mediaManager.resetCachedAssets()
        }
    }

    fileprivate func updateAssetSelection() {
        // If no items selected in assetView, but there are already photos
        // after photoLibraryDidChange, than select first item in library.
        // It can be when user add photos from limited permission.
        if self.mediaManager.fetchResult.count > 0,
           selectedItems.isEmpty {
            let newAsset = self.mediaManager.fetchResult[0]
            self.changeAsset(newAsset)
        }

        // If user decided to forbid all photos with limited permission
        // while using the lib we need to remove asset from assets view.
        if selectedItems.isEmpty == false,
           self.mediaManager.fetchResult.count == 0 {
            self.v.assetZoomableView.clearAsset()
            self.selectedItems.removeAll()
            self.delegate?.libraryViewFinishedLoading()
        }
    }
}
