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
        DispatchQueue.main.async {
            guard
                let fetchResult = self.mediaManager.fetchResult,
                let collectionChanges = changeInstance.changeDetails(for: fetchResult),
                let collectionView = self.v.collectionView else {
                return
            }

            self.mediaManager.fetchResult = collectionChanges.fetchResultAfterChanges
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                collectionView.reloadData()
            } else {
                collectionView.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes, removedIndexes.count != 0 {
                        collectionView.deleteItems(at: removedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes, insertedIndexes.count != 0 {
                        collectionView.insertItems(at: insertedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }
                }, completion: { finished in
                    guard finished,
                        let changedIndexes = collectionChanges.changedIndexes,
                        changedIndexes.count != 0 else { return }
                    collectionView.reloadItems(at: changedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                })
            }
            self.mediaManager.resetCachedAssets()
        }
    }
}
