//
//  SelectionsGalleryCVCell.swift
//  YPImagePicker
//
//  Created by Nik Kov on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

class SelectionsGalleryCVCell: UICollectionViewCell {
    @IBOutlet weak var imageV: UIImageView!
        
    override func awakeFromNib() {
        super.awakeFromNib()

        imageV.layer.shadowColor = UIColor(r: 46, g: 43, b: 37).cgColor
        imageV.layer.shadowOpacity = 0.2
        imageV.layer.shadowOffset = CGSize(width: 4, height: 7)
        imageV.layer.shadowRadius = 5
    }
}

