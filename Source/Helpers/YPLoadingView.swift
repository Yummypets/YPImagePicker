//
//  YPLoadingView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/04/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPLoadingView: UIView {
    
    let spinner = UIActivityIndicatorView(style: .large)
    let processingLabel = UILabel()
    
    convenience init() {
        self.init(frame: .zero)
    
        // View Hiearachy
        let stack = UIStackView(arrangedSubviews: [spinner, processingLabel])
        stack.axis = .vertical
        stack.spacing = 20
        subviews(
            stack
        )
        
        // Layout
        stack.centerInContainer()
        processingLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        
        // Style
        backgroundColor = UIColor.ypLabel.withAlphaComponent(0.8)
        processingLabel.textColor = .ypSystemBackground
        spinner.hidesWhenStopped = true
        
        // Content
        processingLabel.text = YPConfig.wordings.processing
        
        spinner.startAnimating()
    }
    
    func toggleLoading() {
        if !spinner.isAnimating {
            spinner.startAnimating()
            alpha = 1
        } else {
            spinner.stopAnimating()
            alpha = 0
        }
    }
}
