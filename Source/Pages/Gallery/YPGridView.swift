//
//  YPGridView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 15/11/2016.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPGridView: UIView {
    
    let line1 = UIView()
    let line2 = UIView()
    let line3 = UIView()
    let line4 = UIView()
    
    var isCircle = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    convenience init() {
        self.init(frame: .zero)
        isUserInteractionEnabled = false
        sv(
            line1,
            line2,
            line3,
            line4
        )
        
        let stroke: CGFloat = 0.5
        line1.top(0).width(stroke).bottom(0)
        line1.Right == 33 % Right
        
        line2.top(0).width(stroke).bottom(0)
        line2.Right == 66 % Right
        
        line3.left(0).height(stroke).right(0)
        line3.Bottom == 33 % Bottom
        
        line4.left(0).height(stroke).right(0)
        line4.Bottom == 66 % Bottom
        
        let color = UIColor.white.withAlphaComponent(0.6)
        line1.backgroundColor = color
        line2.backgroundColor = color
        line3.backgroundColor = color
        line4.backgroundColor = color
        
        applyShadow(to: line1)
        applyShadow(to: line2)
        applyShadow(to: line3)
        applyShadow(to: line4)
    }
    
    func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 2
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isCircle {
            clipsToBounds = true
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
    }
}
