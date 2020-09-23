//
//  UIButton+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 26.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

internal extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState: UIControl.State) {
        setBackgroundImage(imageWithColor(color), for: forState)
    }
    
    func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
