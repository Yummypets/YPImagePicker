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
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    convenience init() {
        self.init(frame:CGRect.zero)
        
        sv(
            tableView,
            spinner
        )
        // TableView needs to be the first subview for it to automatically adjust its content inset with the NavBar
        
        spinner.centerInContainer()
        tableView.fillContainer()
        
        backgroundColor = .white
    }
}
