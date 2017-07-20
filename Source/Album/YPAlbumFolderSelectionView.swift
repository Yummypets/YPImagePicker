//
//  YPAlbumFolderSelectionView.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 20/07/2017.
//  Copyright © 2017 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPAlbumFolderSelectionView: UIView {
    
    let tableView = UITableView()
    
    convenience init() {
        self.init(frame:CGRect.zero)
        sv(tableView)
        tableView.fillContainer()
    }
}
