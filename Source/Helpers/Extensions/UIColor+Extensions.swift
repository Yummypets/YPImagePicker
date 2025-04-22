//
//  UIColor+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 26.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }

    static var offWhiteOrBlack: UIColor {
        return UIColor { (traitCollection: UITraitCollection) -> UIColor in
            let rgbValue: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0 : 247
            return UIColor(r: rgbValue, g: rgbValue, b: rgbValue)
        }
    }

    /// The color for text labels that contain primary content.
    ///
    /// Like `.label`, but backwards-compatible with iOS 12 and lower.
    static var ypLabel: UIColor {
        return .label
    }
    
    static var ypSecondaryLabel: UIColor {
        return .secondaryLabel
    }
    
    /// The color for content layered on top of the main background.
    ///
    /// Like `.secondarySystemBackground`, but backwards-compatible with iOS 12 and lower.
    static var ypSecondarySystemBackground: UIColor {
        return .secondarySystemBackground
    }
    
    /// The color for the main background of your interface.
    ///
    /// Like `.systemBackground`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemBackground: UIColor {
        return .systemBackground
    }
    
    /// The base blue color.
    ///
    /// Like `.systemBlue`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemBlue: UIColor {
        return .systemBlue
    }
    
    /// The base gray color.
    ///
    /// Like `.systemGray`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemGray: UIColor {
        return .systemGray
    }
    
    /// The color for red, compatible with dark mode in iOS 13.
    ///
    /// Like `.red`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemRed: UIColor {
        return .systemRed
    }
}
