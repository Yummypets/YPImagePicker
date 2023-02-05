//
//  YPAlbumCell.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 20/07/2017.
//  Copyright © 2017 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPAlbumCell: UITableViewCell {
    
    let thumbnail = UIImageView()
    let title = UILabel()
    let numberOfItems = UILabel()
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.addArrangedSubview(title)
        stackView.addArrangedSubview(numberOfItems)
        
        subviews(
            thumbnail,
            stackView
        )
        
        layout(
            6,
            |-10-thumbnail.size(78),
            6
        )
        
        align(horizontally: thumbnail-10-stackView)
        
        thumbnail.contentMode = .scaleAspectFill
        thumbnail.clipsToBounds = true
        
        title.font = YPConfig.fonts.albumCellTitleFont
        numberOfItems.font = YPConfig.fonts.albumCellNumberOfItemsFont
    }
}
