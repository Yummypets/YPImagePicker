//
//  YPPagerMenu.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPPagerMenu: UIView {
    
    var didSetConstraints = false
    var menuItems = [YPMenuItem]()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = UIColor(r: 247, g: 247, b: 247)
        clipsToBounds = true
    }
    
    var separators = [UIView]()
    
    func setUpMenuItemsConstraints() {
        let menuItemWidth: CGFloat = UIScreen.main.bounds.width / CGFloat(menuItems.count)
        var previousMenuItem: YPMenuItem?
        for m in menuItems {
            
            sv(
                m
            )
            
            m.fillVertically().width(menuItemWidth)
            if let pm = previousMenuItem {
                pm-0-m
            } else {
                |m
            }
            
            previousMenuItem = m
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        if !didSetConstraints {
            setUpMenuItemsConstraints()
        }
        didSetConstraints = true
    }
    
    func refreshMenuItems() {
        didSetConstraints = false
        updateConstraints()
    }
}
