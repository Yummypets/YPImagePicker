//
//  YPCropView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 12/02/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPCropView: UIView {
    
    let imageView = UIImageView()
    let topCurtain = UIView()
    let cropArea = UIView()
    let bottomCurtain = UIView()
    let toolbar = UIToolbar()

    convenience init(image: UIImage, ratio: Double) {
        self.init(frame: .zero)
        setupViewHierarchy()
        setupLayout(with: image, ratio: ratio)
        applyStyle()
        imageView.image = image
    }
    
    private func setupViewHierarchy() {
        sv(
            imageView,
            topCurtain,
            cropArea,
            bottomCurtain,
            toolbar
        )
    }
    
    private func setupLayout(with image: UIImage, ratio: Double) {
        layout(
            0,
            |topCurtain|,
            |cropArea|,
            |bottomCurtain|,
            0
        )
        |toolbar|
        if #available(iOS 11.0, *) {
            toolbar.Bottom == safeAreaLayoutGuide.Bottom
        } else {
            toolbar.bottom(0)
        }
        
        let r: CGFloat = CGFloat(1.0 / ratio)
        cropArea.Height == cropArea.Width * r
        cropArea.centerVertically()
        
        // Fit image differently depnding on its ratio.
        let imageRatio: Double = Double(image.size.width / image.size.height)
        if ratio > imageRatio {
            let scaledDownRatio = UIScreen.main.bounds.width / image.size.width
            imageView.width(image.size.width * scaledDownRatio )
            imageView.centerInContainer()
        } else if ratio < imageRatio {
            imageView.Height == cropArea.Height
            imageView.centerInContainer()
        } else {
            imageView.followEdges(cropArea)
        }
        
        // Fit imageView to image's bounds
        imageView.Width == imageView.Height * CGFloat(imageRatio)
    }
    
    private func applyStyle() {
        backgroundColor = .ypSystemBackground
        clipsToBounds = true
        imageView.style { i in
            i.isUserInteractionEnabled = true
            i.isMultipleTouchEnabled = true
        }
        topCurtain.style(curtainStyle)
        cropArea.style { v in
            v.backgroundColor = .clear
            v.isUserInteractionEnabled = false
        }
        bottomCurtain.style(curtainStyle)
        toolbar.style { t in
            t.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
            t.setShadowImage(UIImage(), forToolbarPosition: .any)
        }
    }
    
    func curtainStyle(v: UIView) {
        v.backgroundColor = UIColor.ypSystemBackground.withAlphaComponent(0.7)
        v.isUserInteractionEnabled = false
    }
}
