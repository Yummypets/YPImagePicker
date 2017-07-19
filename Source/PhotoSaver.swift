//
//  PhotoSaver.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 10/11/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import Photos

public class PhotoSaver {
    
    public static var albumName = "DefaultYPImagePickerAlbumName"
    
    class func trySaveImage(_ image: UIImage) {
     
        if let album = album(named: albumName) {
            saveImage(image, toAlbum: album)
        } else {
            createAlbum(withName: albumName) {
                if let album = album(named: albumName) {
                    saveImage(image, toAlbum: album)
                }
            }
        }
    }
}

func album(named: String) -> PHAssetCollection? {
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "title = %@", named)
    let collection = PHAssetCollection.fetchAssetCollections(with: .album,
                                                             subtype: .any,
                                                             options: fetchOptions)
    return collection.firstObject
}

func saveImage(_ image: UIImage, toAlbum album: PHAssetCollection) {
    PHPhotoLibrary.shared().performChanges({
        let changeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
        let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
        let enumeration: NSArray = [changeRequest.placeholderForCreatedAsset!]
        albumChangeRequest?.addAssets(enumeration)
    })
}

func createAlbum(withName name: String, completion:@escaping () -> Void) {
    PHPhotoLibrary.shared().performChanges({
        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
    }) { success, _ in
        if success {
            completion()
        }
    }
}
