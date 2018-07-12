//
//  SelectionsGalleryCell.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Stevia

public class YPSelectionsGalleryCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let editIcon = UIView()
    let editSquare = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        sv(
            imageView,
            editIcon,
            editSquare
        )
        
        imageView.fillContainer()
        editIcon.size(32).left(12).bottom(12)
        editSquare.size(16)
        editSquare.CenterY == editIcon.CenterY
        editSquare.CenterX == editIcon.CenterX
        
        layer.shadowColor = UIColor(r: 46, g: 43, b: 37).cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 4, height: 7)
        layer.shadowRadius = 5
        layer.backgroundColor = UIColor.clear.cgColor
        imageView.style { i in
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
        }
        editIcon.style { v in
            v.backgroundColor = .white
            v.layer.cornerRadius = 16
        }
        editSquare.style { v in
            v.layer.borderWidth = 1
            v.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0,
                           options: .curveEaseInOut,
                           animations: {
                            if self.isHighlighted {
                                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                                self.alpha = 0.8
                            } else {
                                self.transform = .identity
                                self.alpha = 1
                            }
            }, completion: nil)
        }
    }
}
