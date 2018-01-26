//
//  YPMenuItem.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPMenuItem: UIView {
    
    var text = UILabel()
    var button = UIButton()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        
        sv(
            text,
            button
        )
        
        text.centerInContainer()
        button.fillContainer()
        
        text.style { l in
            l.textAlignment = .center
            l.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
            l.textColor = self.unselectedColor()
        }
    }
    
    func selectedColor() -> UIColor {
        return UIColor(r: 38, g: 38, b: 38)
    }
    
    func unselectedColor() -> UIColor {
        return UIColor(r: 153, g: 153, b: 153)
    }
    
    func select() {
        text.textColor = selectedColor()
    }
    
    func unselect() {
        text.textColor = unselectedColor()
    }
}
