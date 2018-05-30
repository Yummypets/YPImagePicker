//
//  YPAlbumsManager.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 20/07/2017.
//  Copyright © 2017 Yummypets. All rights reserved.
//

import Foundation
import Photos

class YPAlbumsManager {
    
    private var cachedAlbums: [YPAlbum]?
    
    func fetchAlbums() -> [YPAlbum] {
        if let cachedAlbums = cachedAlbums {
            return cachedAlbums
        }
        
        var albums = [YPAlbum]()
        let options = PHFetchOptions()
        
        let smartAlbumsResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                        subtype: .any,
                                                                        options: options)
        let albumsResult = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                   subtype: .any,
                                                                   options: options)
        for result in [smartAlbumsResult, albumsResult] {
            result.enumerateObjects({ assetCollection, _, _ in
                var album = YPAlbum()
                album.title = assetCollection.localizedTitle ?? ""
                album.numberOfItems = self.mediaCountFor(collection: assetCollection)
                if album.numberOfItems > 0 {
                    let r = PHAsset.fetchKeyAssets(in: assetCollection, options: nil)
                    if let first = r?.firstObject {
                        let targetSize = CGSize(width: 78*2, height: 78*2)
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        options.deliveryMode = .fastFormat
                        PHImageManager.default().requestImage(for: first,
                                                              targetSize: targetSize,
                                                              contentMode: .aspectFit,
                                                              options: options,
                                                              resultHandler: { image, _ in
                                                                album.thumbnail = image
                        })
                    }
                    album.collection = assetCollection
                    
                    if YPConfig.library.mediaType == .photo {
                        if !(assetCollection.assetCollectionSubtype == .smartAlbumSlomoVideos
                            || assetCollection.assetCollectionSubtype == .smartAlbumVideos) {
                            albums.append(album)
                        }
                    } else {
                        albums.append(album)
                    }
                }
            })
        }
        cachedAlbums = albums
        return albums
    }
    
    func mediaCountFor(collection: PHAssetCollection) -> Int {
        let options = PHFetchOptions()
        options.predicate = YPConfig.library.mediaType.predicate()
        let result = PHAsset.fetchAssets(in: collection, options: options)
        return result.count
    }
    
}

extension YPlibraryMediaType {
    func predicate() -> NSPredicate {
        switch self {
        case .photo:
            return NSPredicate(format: "mediaType = %d",
                               PHAssetMediaType.image.rawValue)
        case .video:
            return NSPredicate(format: "mediaType = %d",
                               PHAssetMediaType.video.rawValue)
        case .photoAndVideo:
            return NSPredicate(format: "mediaType = %d || mediaType = %d",
                               PHAssetMediaType.image.rawValue,
                               PHAssetMediaType.video.rawValue)
        }
    }
}
