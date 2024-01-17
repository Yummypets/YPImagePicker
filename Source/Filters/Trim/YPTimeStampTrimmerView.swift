//
//  YPTimeStampTrimmerView.swift
//  YPImagePicker
//
//  Created by Zeph Cohen on 1/16/24.
//  Copyright © 2024 Yummypets. All rights reserved.
//

import AVFoundation
import UIKit
import PryntTrimmerView

public class YPTimeStampTrimmerView: UIView {

    let trimmerView = TrimmerView()
    let timeStampView = UIView()
    let rightHandleTimeStamp = UILabel()
    let leftHandleTimeStamp = UILabel()
    private(set) var rightHandleTimeStampConstraint: NSLayoutConstraint?
    private(set) var leftHandleTimeStampConstraint: NSLayoutConstraint?

    public var startTime: CMTime? {
        trimmerView.startTime
    }

    public var endTime: CMTime? {
        trimmerView.endTime
    }

    private(set) var isLaidOut = false

    override init(frame: CGRect) {
        super.init(frame: frame)
       setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func setupSubviews() {
        setupTrimmerView()
        setupTimeStampView()
        setupRightHandleTimeStamp()
        setupLeftHandleTimeStamp()
        backgroundColor = .darkGray
        timeStampView.backgroundColor = .black
    }

    public override func layoutSubviews() {
        if !isLaidOut {
            isLaidOut = true
            constraintTrimView()
            constraintTimeStampView()
            constrainRightHandleTimeStamp()
            constraintLeftHandleTimeStamp()
        }
    }

    func setupLeftHandleTimeStamp() {
        leftHandleTimeStamp.translatesAutoresizingMaskIntoConstraints = false
        leftHandleTimeStamp.isHidden = true
        addSubview(leftHandleTimeStamp)
        leftHandleTimeStamp.backgroundColor = .gray
        leftHandleTimeStamp.text = "0:00"
    }

    func setupRightHandleTimeStamp() {
        rightHandleTimeStamp.translatesAutoresizingMaskIntoConstraints = false
        rightHandleTimeStamp.isHidden = true
        addSubview(rightHandleTimeStamp)
        rightHandleTimeStamp.backgroundColor = .gray
        rightHandleTimeStamp.text = "0:00"
    }

    func setupTrimmerView() {
        trimmerView.translatesAutoresizingMaskIntoConstraints = false
        trimmerView.delegate = self
        addSubview(trimmerView)
    }

    func constraintLeftHandleTimeStamp() {
        leftHandleTimeStamp.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftHandleTimeStampConstraint = leftHandleTimeStamp.leftAnchor.constraint(equalTo: trimmerView.leftAnchor)
        leftHandleTimeStamp.bottomAnchor.constraint(equalTo: trimmerView.topAnchor).isActive = true
        leftHandleTimeStampConstraint?.isActive = true
    }

    func constrainRightHandleTimeStamp() {
        rightHandleTimeStamp.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightHandleTimeStampConstraint = rightHandleTimeStamp.rightAnchor.constraint(equalTo: trimmerView.rightAnchor)
        rightHandleTimeStamp.bottomAnchor.constraint(equalTo: trimmerView.topAnchor).isActive = true
        rightHandleTimeStampConstraint?.isActive = true
    }

    func constraintTrimView() {
        trimmerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        trimmerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        trimmerView.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
        trimmerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    func constraintTimeStampView() {
        timeStampView.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 7).isActive = true
        timeStampView.leftAnchor.constraint(equalTo: trimmerView.leftAnchor).isActive = true
        timeStampView.rightAnchor.constraint(equalTo: trimmerView.rightAnchor).isActive = true
        timeStampView.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
    }

    func setupTimeStampView() {
        timeStampView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeStampView)
    }
}

extension YPTimeStampTrimmerView: TrimmerViewDelegate {
    public func didDragLeftHandleBar(to updatedConstant: CGFloat) {
        self.leftHandleTimeStampConstraint?.constant = updatedConstant
    }

    public func didBeginDraggingLeftHandleBar() {
        leftHandleTimeStamp.isHidden = false
    }

    public func didBeginDraggingRightHandleBar() {
        rightHandleTimeStamp.isHidden = false
    }

    public func didDragRightHandleBar(to updatedConstant: CGFloat) {
        self.rightHandleTimeStampConstraint?.constant = updatedConstant
    }

    public func didChangePositionBar(_ playerTime: CMTime) {
        // Implement if needed
    }

    public func positionBarStoppedMoving(_ playerTime: CMTime) {
        // Implement if needed
        rightHandleTimeStamp.isHidden = true
        leftHandleTimeStamp.isHidden = true
    }
}

