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
    let label = UILabel()
    var selectionColor = UIColor.black
    
    convenience init() {
        self.init(frame: .zero)
        
        let size: CGFloat = 20
        
        sv(
            circle,
            label
        )
        
        circle.fillContainer()
        circle.size(size)
        label.fillContainer()
        
        circle.layer.cornerRadius = size / 2.0
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        set(number: nil)
    }
    
    func set(number: Int?) {
        label.isHidden = (number == nil)
        if let number = number {
            circle.backgroundColor = selectionColor
            circle.layer.borderColor = UIColor.clear.cgColor
            circle.layer.borderWidth = 0
            label.text = "\(number)"
        } else {
            circle.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            circle.layer.borderColor = UIColor.white.cgColor
            circle.layer.borderWidth = 1
            label.text = ""
        }
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
        selectionOverlay.backgroundColor = .white
        selectionOverlay.alpha = 0
        backgroundColor = UIColor(r: 247, g: 247, b: 247)
    }

    override var isSelected: Bool {
        didSet { isHighlighted = isSelected }
    }
    
    override var isHighlighted: Bool {
        didSet {
            selectionOverlay.alpha = isHighlighted ? 0.6 : 0
        }
    }
}
