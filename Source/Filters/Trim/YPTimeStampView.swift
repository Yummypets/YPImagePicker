//
//  YPTimeStampView.swift
//  YPImagePicker
//
//  Created by Zeph Cohen on 1/22/24.
//  Copyright © 2024 Yummypets. All rights reserved.
//

import UIKit

class YPTimeStampView: UIView {

    var shouldRenderBoldCircle: Bool = false
    var timeStampText: String?

    let timeStampFont: UIFont?
    let timeStampColor: UIColor?
    let timeBarColor: UIColor?

    required init(timeStampFont: UIFont?, timeStampColor: UIColor?, timeBarColor: UIColor?) {
        self.timeStampFont = timeStampFont
        self.timeStampColor = timeStampColor
        self.timeBarColor = timeBarColor
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        renderCircle()
        if let timeStampText = timeStampText {
            renderTimeStamp(text: timeStampText)
        }
    }

    func renderTimeStamp(text: String) {
        let timeStamp = UILabel()
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        timeStamp.textColor = timeStampColor
        timeStamp.textAlignment = .center
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.97
        timeStamp.attributedText = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.kern: 0.1, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        timeStamp.font = timeStampFont
        addSubview(timeStamp)
        timeStamp.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        timeStamp.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }

    func renderCircle() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: 4), radius: CGFloat(shouldRenderBoldCircle ? 2 : 1), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = timeBarColor?.cgColor
        layer.addSublayer(shapeLayer)
    }
}
