//
//  YPCropView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 12/02/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPCropAreaView: UIView {
    
    var isCircle = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard isCircle else {
            return
        }
        
        backgroundColor?.setFill()
        UIRectFill(rect)

        let layer = CAShapeLayer()
        let path = CGMutablePath()

        path.addRoundedRect(in: bounds, cornerWidth: bounds.width/2, cornerHeight: bounds.width/2)
        path.addRect(bounds)
        
        layer.path = path
        layer.fillRule = CAShapeLayerFillRule.evenOdd
        
        self.layer.mask = layer
    }
}

class YPCropView: UIView {
    
    let imageView = UIImageView()
    let topCurtain = UIView()
    let cropArea = YPCropAreaView()
    let bottomCurtain = UIView()
    let toolbar = UIToolbar()
    let grid = YPGridView()
    
    private var isCircle = true
    
    convenience init(image: UIImage) {
        self.init(frame: .zero)
        setupViewHierarchy()
        let ratio: Double
        switch YPConfig.showsCrop {
        case .rectangle(ratio: let configuredRatio):
            isCircle = false
            ratio = configuredRatio
        default:
            ratio = 1
        }
        setupLayout(with: image, ratio: ratio)
        applyStyle()
        imageView.image = image
        grid.isHidden = !YPConfig.showsCropOverlayGrid
        grid.isCircle = isCircle
    }
    
    private func setupViewHierarchy() {
        sv(
            imageView,
            topCurtain,
            cropArea,
            bottomCurtain,
            toolbar,
            grid
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
            let screenWidth = YPImagePickerConfiguration.screenWidth
            let scaledDownRatio = screenWidth / image.size.width
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
        
        grid.followEdges(cropArea)
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
            v.backgroundColor = isCircle ? YPConfig.cropOverlayColor ?? .ypSystemBackground : .clear
            v.isCircle = isCircle
            v.isUserInteractionEnabled = false
        }
        bottomCurtain.style(curtainStyle)
        
        if YPConfig.cropToolbarTransparent {
            toolbar.style { t in
                t.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
                t.setShadowImage(UIImage(), forToolbarPosition: .any)
            }
        }
    }
    
    func curtainStyle(v: UIView) {
        v.backgroundColor = YPConfig.cropOverlayColor ?? UIColor.ypSystemBackground.withAlphaComponent(0.7)
        v.isUserInteractionEnabled = false
    }
}
