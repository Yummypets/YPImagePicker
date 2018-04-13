//
//  CropMaskView.swift
//  PryntTrimmerView
//
//  Created by Henry on 10/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class CropMaskView: UIView {

    let cropBoxView = UIView()
    let frameView = UIView()
    let maskLayer = CAShapeLayer()
    let frameLayer = CAShapeLayer()

    private let lineWidth: CGFloat = 4.0
    private var cropFrame: CGRect = CGRect.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {

        maskLayer.fillRule = kCAFillRuleEvenOdd
        maskLayer.fillColor = UIColor.black.cgColor
        maskLayer.opacity = 1.0

        frameLayer.strokeColor = UIColor.white.cgColor
        frameLayer.fillColor = UIColor.clear.cgColor

        frameView.layer.addSublayer(frameLayer)
        cropBoxView.layer.mask = maskLayer

        cropBoxView.translatesAutoresizingMaskIntoConstraints = false
        cropBoxView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        addSubview(cropBoxView)
        addSubview(frameView)

        cropBoxView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        cropBoxView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        cropBoxView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        cropBoxView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath(rect: bounds)
        let framePath = UIBezierPath(rect: cropFrame)
        path.append(framePath)
        path.usesEvenOddFillRule = true
        maskLayer.path = path.cgPath

        framePath.lineWidth = lineWidth
        frameLayer.path = framePath.cgPath
    }

    func setCropFrame(_ frame: CGRect, animated: Bool) {

        cropFrame = frame
        guard animated else {
            setNeedsLayout()
            return
        }

        let (path, framePath) = getPaths(with: cropFrame)

        CATransaction.begin()

        let animation = getPathAnimation(with: path)
        maskLayer.path = maskLayer.presentation()?.path
        frameLayer.path = frameLayer.presentation()?.path

        maskLayer.removeAnimation(forKey: "maskPath")
        maskLayer.add(animation, forKey: "maskPath")

        animation.toValue = framePath
        frameLayer.removeAnimation(forKey: "framePath")
        frameLayer.add(animation, forKey: "framePath")
        CATransaction.commit()
    }

    private func getPaths(with cropFrame: CGRect) -> (path: CGPath, framePath: CGPath) {

        let path = UIBezierPath(rect: bounds)
        let framePath = UIBezierPath(rect: cropFrame)
        framePath.lineWidth = lineWidth
        path.append(framePath)
        path.usesEvenOddFillRule = true

        return (path.cgPath, framePath.cgPath)
    }

    private func getPathAnimation(with path: CGPath) -> CABasicAnimation {

        let animation = CABasicAnimation(keyPath: "path")
        animation.toValue = path
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.fillMode = kCAFillModeBoth
        animation.isRemovedOnCompletion = false

        return animation
    }
}
