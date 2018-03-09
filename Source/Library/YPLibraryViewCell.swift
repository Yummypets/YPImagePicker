//
//  YPLibraryViewCell.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPMultipleSelectionIndicator: UIView {
    
    let circle = UIView()
    
    convenience init() {
        self.init(frame: .zero)
        
        let size: CGFloat = 20
        
        sv(
            circle
        )
        
        circle.fillContainer()
        circle.size(size)
        
        circle.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        circle.layer.cornerRadius = size / 2.0
        circle.layer.borderColor = UIColor.white.cgColor
        circle.layer.borderWidth = 1
        
    }
}


class YPLibraryViewCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String!
    let imageView = UIImageView()
    let durationLabel = UILabel()
    let selectionOverlay = UIView()
    let multipleSelectionIndicator = YPMultipleSelectionIndicator()
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        sv(
            imageView,
            durationLabel,
            selectionOverlay,
            multipleSelectionIndicator
        )

        imageView.fillContainer()
        selectionOverlay.fillContainer()
        layout(
            durationLabel-5-|,
            5
        )
        
        layout(
            3,
            multipleSelectionIndicator-3-|
        )
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.isHidden = true
        selectionOverlay.backgroundColor = .black
        selectionOverlay.alpha = 0
        backgroundColor = UIColor(r: 247, g: 247, b: 247)
    }

    override var isSelected: Bool {
        didSet { isHighlighted = isSelected }
    }
    
    override var isHighlighted: Bool {
        didSet {
            selectionOverlay.alpha = isHighlighted ? 0.5 : 0
        }
    }
}
