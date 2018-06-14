//
//  YPSelectionsGalleryView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 13/06/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPSelectionsGalleryView: UIView {
    
    var collectionView: UICollectionView!
    
    convenience init() {
        self.init(frame: .zero)
    
        // Setup CollectionView Layout
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let sideMargin: CGFloat = 24
        let spacing: CGFloat = 12
        let overlapppingNextPhoto: CGFloat = 37
        flowLayout.minimumLineSpacing = spacing
        flowLayout.minimumInteritemSpacing = spacing
        let size = UIScreen.main.bounds.width - (sideMargin + overlapppingNextPhoto)
        flowLayout.itemSize = CGSize(width: size, height: size)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: sideMargin, bottom: 0, right: sideMargin)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        
        sv(
            collectionView
        )
        
        // Layout collectionView
        collectionView.heightEqualsWidth()
        if #available(iOS 11.0, *) {
            collectionView.Right == safeAreaLayoutGuide.Right
            collectionView.Left == safeAreaLayoutGuide.Left
        } else {
            |collectionView|
        }
        collectionView.CenterY == CenterY - 30
        
        // Apply style
        backgroundColor = UIColor(r: 247, g: 247, b: 247)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
    }
}
