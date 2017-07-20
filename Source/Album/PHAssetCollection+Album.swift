//
//  PHAssetCollection+Album.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 20/07/2017.
//  Copyright © 2017 Yummypets. All rights reserved.
//

import Foundation
import Photos

class AlbumsManager {
    
    private static let instance = AlbumsManager()
    
    class var `default`: AlbumsManager {
        return instance
    }
    
    func fetchAlbums() -> [Album] {
        var albums = [Album]()
        
        // .smartAlbum / moment
        let options = PHFetchOptions()
        //        options.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        let result = PHAssetCollection
            .fetchAssetCollections(with: .smartAlbum,
                                   subtype: .any,
                                   options: options)
        print(result.count)
        result.enumerateObjects({ assetCollection, index, stop in
            
            
            var album = Album()
            album.title = assetCollection.localizedTitle ?? ""
            album.numberOfPhotos = self.mediaCountFor(collection: assetCollection)
            
            if album.numberOfPhotos > 0 {
                
                let r = PHAsset.fetchKeyAssets(in: assetCollection, options: nil)
                //                print("KEY aSSET COUNT: \(r?.count)")
                //                r?.enumerateObjects({ asset, index, stop in
                //                    print(asset)
                //                })
                if let first = r?.firstObject {
                    let targetSize = CGSize(width: 60, height: 60)
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    options.deliveryMode = .fastFormat
                    //                    options.resizeMode = .fast
                    
                    
                    PHImageManager.default().requestImage(for: first,
                                                          targetSize: targetSize,
                                                          contentMode: .aspectFill,
                                                          options: options,
                                                          resultHandler: { image, dic in
                                                            print(image)
                                                            print(dic)
                                                            
                                                            print("Got Image")
                                                            if let image = image {
                                                                album.thumbnail = image
                                                            }
                    })
                }
                print("Adding album")
                album.collection = assetCollection
                albums.append(album)
            }
            
            
        })
        print("Done")
        
        
        return albums
    }
    
    func mediaCountFor(collection: PHAssetCollection) -> Int {
        let result = PHAsset.fetchAssets(in: collection, options: nil)
        return result.count
    }
}

