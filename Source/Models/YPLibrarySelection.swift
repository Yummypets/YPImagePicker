//
//  YPLibrarySelection.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 18/04/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPLibrarySelection {
    let index: Int
    var cropRect: CGRect?
    var scrollViewContentOffset: CGPoint?
    var scrollViewZoomScale: CGFloat?
    let assetIdentifier: String
    let collectionIdentifier: String?
    
    init(index: Int,
         cropRect: CGRect? = nil,
         scrollViewContentOffset: CGPoint? = nil,
         scrollViewZoomScale: CGFloat? = nil,
         assetIdentifier: String,
         collectionIdentifier: String? = nil) {
        self.index = index
        self.cropRect = cropRect
        self.scrollViewContentOffset = scrollViewContentOffset
        self.scrollViewZoomScale = scrollViewZoomScale
        self.assetIdentifier = assetIdentifier
        self.collectionIdentifier = collectionIdentifier
    }
}
