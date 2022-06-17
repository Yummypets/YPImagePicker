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
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: YPGalleryCollectionViewFlowLayout())
    
    convenience init() {
        self.init(frame: .zero)
    
        subviews(
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
        backgroundColor = YPConfig.colors.selectionsBackgroundColor
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
    }
}

class YPGalleryCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        scrollDirection = .horizontal
        let sideMargin: CGFloat = 24
        let spacing: CGFloat = 12
        let overlapppingNextPhoto: CGFloat = 37
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
        let screenWidth = YPImagePickerConfiguration.screenWidth
        let size = screenWidth - (sideMargin + overlapppingNextPhoto)
        itemSize = CGSize(width: size, height: size)
        sectionInset = UIEdgeInsets(top: 0, left: sideMargin, bottom: 0, right: sideMargin)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This makes so that Scrolling the collection view always stops with a centered image.
    // This is heavily inpired form :
    // https://stackoverflow.com/questions/13492037/targetcontentoffsetforproposedcontentoffsetwithscrollingvelocity
	// -without-subcla
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
									  withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let spacing: CGFloat = 12
        let overlapppingNextPhoto: CGFloat = 37
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude// MAXFLOAT
        let horizontalOffset = proposedContentOffset.x + spacing + overlapppingNextPhoto/2 // + 5
        
        guard let collectionView = collectionView else {
            return proposedContentOffset
        }
        let targetRect = CGRect(x: proposedContentOffset.x,
								y: 0,
								width: collectionView.bounds.size.width,
								height: collectionView.bounds.size.height)
        guard let array = super.layoutAttributesForElements(in: targetRect) else {
            return proposedContentOffset
        }
        
        for layoutAttributes in array {
            let itemOffset = layoutAttributes.frame.origin.x
            if abs(itemOffset - horizontalOffset) < abs(offsetAdjustment) {
                offsetAdjustment = itemOffset - horizontalOffset
            }
        }
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}
