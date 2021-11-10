//
//  UINavigationBar+Extensions.swift
//  YPImagePicker
//
//  Created by Sebastiaan Seegers on 02/03/2020.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit
import Foundation

extension UINavigationBar {

    func setTitleFont(font: UIFont?) {
        guard let font = font  else { return }
        self.titleTextAttributes = [NSAttributedString.Key.font: font]
    }

    func configureNavigationBar(isTransculent: Bool, tintColor: UIColor) {
        self.tintColor = .ypLabel

        if #available(iOS 15.0, *) {
            let appearance = standardAppearance
            if isTransculent {
                appearance.configureWithTransparentBackground()
            } else {
                appearance.configureWithOpaqueBackground()
            }
            scrollEdgeAppearance = appearance
        } else {
            self.isTranslucent = isTransculent
        }
    }
}
