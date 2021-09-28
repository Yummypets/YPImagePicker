//
//  UIBarButtonItem+Extensions.swift
//  YPImagePicker
//
//  Created by Sebastiaan Seegers on 02/03/2020.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit
import Foundation

extension UIBarButtonItem {

    func setFont(font: UIFont?, forState state: UIControl.State) {
        guard font != nil else { return }
        self.setTitleTextAttributes([NSAttributedString.Key.font: font!], for: .normal)
    }
}
