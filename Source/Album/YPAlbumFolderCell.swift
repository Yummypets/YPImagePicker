//
//  YPAlbumFolderCell.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 20/07/2017.
//  Copyright © 2017 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPAlbumFolderCell: UITableViewCell {
    
    let thumbnail = UIImageView()
    let title = UILabel()
    let numberOfPhotos = UILabel()
    
    convenience init() {
        self.init(frame:CGRect.zero)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.addArrangedSubview(title)
        stackView.addArrangedSubview(numberOfPhotos)
        
        sv(
            thumbnail,
            stackView
        )
        
        layout(
            10,
            |-10-thumbnail.size(60),
            10
        )
        
        alignHorizontally(thumbnail-10-stackView)
    }
    
}
