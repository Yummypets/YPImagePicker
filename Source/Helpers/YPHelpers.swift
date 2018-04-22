//
//  YPHelpers.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 02/11/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import UIKit

struct YPHelpers {
    static func changeBackButtonIcon(_ controller: UIViewController,
                                     configuration: YPImagePickerConfiguration) {
        if configuration.icons.shouldChangeDefaultBackButtonIcon {
            controller.navigationController?.navigationBar.backIndicatorImage = configuration.icons.backButtonIcon
            controller.navigationController?.navigationBar.backIndicatorTransitionMaskImage = configuration.icons.backButtonIcon
        }
    }
    
    static func changeBackButtonTitle(_ controller: UIViewController,
                                      configuration: YPImagePickerConfiguration) {
        if configuration.icons.hideBackButtonTitle {
            controller.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        }
    }
}

func ypLocalized(_ str: String) -> String {
    return NSLocalizedString(str,
                             tableName: nil,
                             bundle: Bundle(for: YPPickerVC.self),
                             value: "",
                             comment: "")
}

func imageFromBundle(_ named: String) -> UIImage {
    return UIImage(named: named, in: Bundle(for: YPPickerVC.self), compatibleWith: nil) ?? UIImage()
}

func configureFocusView(_ v: UIView) {
    v.alpha = 0.0
    v.backgroundColor = UIColor.clear
    v.layer.borderColor = UIColor(r: 204, g: 204, b: 204).cgColor
    v.layer.borderWidth = 1.0
    v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
}

func animateFocusView(_ v: UIView) {
    UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.8,
                   initialSpringVelocity: 3.0, options: UIViewAnimationOptions.curveEaseIn,
                   animations: {
                    v.alpha = 1.0
                    v.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { _ in
            v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            v.removeFromSuperview()
    })
}

func formattedStrigFrom(_ timeInterval: TimeInterval) -> String {
    let interval = Int(timeInterval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}
