//
//  YPPhotoSaver.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 10/11/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Photos

public class YPPhotoSaver {
    class func trySaveImage(_ image: UIImage,
                            inAlbumNamed: String,
                            completion: ((PHAsset?) -> Void)? = nil) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            completion?(nil)
            return
        }
        if let album = album(named: inAlbumNamed) {
            saveImage(image, toAlbum: album, completion: completion)
        } else {
            createAlbum(withName: inAlbumNamed) {
                if let album = album(named: inAlbumNamed) {
                    saveImage(image, toAlbum: album, completion: completion)
                } else {
                    DispatchQueue.main.async { completion?(nil) }
                }
            }
        }
    }

    fileprivate class func saveImage(_ image: UIImage,
                                     toAlbum album: PHAssetCollection,
                                     completion: ((PHAsset?) -> Void)? = nil) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let changeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            if let createdPlaceholder = changeRequest.placeholderForCreatedAsset {
                placeholder = createdPlaceholder
                albumChangeRequest?.addAssets([createdPlaceholder] as NSArray)
            }
        }, completionHandler: { success, _ in
            guard success, let localIdentifier = placeholder?.localIdentifier else {
                DispatchQueue.main.async { completion?(nil) }
                return
            }
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject
            DispatchQueue.main.async { completion?(asset) }
        })
    }
    
    fileprivate class func createAlbum(withName name: String, completion:@escaping () -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }, completionHandler: { success, _ in
            if success {
                completion()
            }
        })
    }
    
    fileprivate class func album(named: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", named)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                 subtype: .any,
                                                                 options: fetchOptions)
        return collection.firstObject
    }
}
