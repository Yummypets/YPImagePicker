//
//  YPLoaders.swift
//  YPImagePicker
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPLoaders {

    static var defaultLoader: UIBarButtonItem {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.color = YPConfig.colors.navigationBarActivityIndicatorColor
        spinner.startAnimating()
        return UIBarButtonItem(customView: spinner)
    }
    
}
