//
//  YPPlaceHolderTextView.swift
//  YPImagePicker
//
//  Created by Umut Genlik on 10/29/18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

class YPPlaceHolderTextView: UITextView {
    
    private class YPPlaceholderLabel: UILabel { }
    
    private var placeholderLabel: YPPlaceholderLabel {
        if let label = subviews.compactMap( { $0 as? YPPlaceholderLabel }).first {
            return label
        } else {
            let label = YPPlaceholderLabel(frame: .zero)
            label.font = font
            label.textColor = UIColor.lightGray
            addSubview(label)
            return label
        }
    }
    
    var placeholder: String {
        get {
            return subviews.compactMap( { $0 as? YPPlaceholderLabel }).first?.text ?? ""
        }
        set {
            let placeholderLabel = self.placeholderLabel
            placeholderLabel.text = newValue
            placeholderLabel.numberOfLines = 0
            let width = frame.width - textContainer.lineFragmentPadding * 2
            let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            placeholderLabel.frame.size.height = size.height
            
            if width <= 0
            {
                placeholderLabel.frame.size.width = 200
            }
            else
            {
                placeholderLabel.frame.size.width = width
            }
            
            placeholderLabel.frame.origin = CGPoint(x: textContainer.lineFragmentPadding, y: textContainerInset.top)
            
            textStorage.delegate = self
        }
    }
    
}

extension YPPlaceHolderTextView: NSTextStorageDelegate {
    
    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if editedMask.contains(.editedCharacters) {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }
    
}
