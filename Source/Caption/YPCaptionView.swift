//
//  YPCaptionView.swift
//  YPImagePicker
//
//  Created by Umut Genlik on 10/26/18.
//

import Stevia

class YPCaptionView: UIView {
    
    let imageView = UIImageView()
    let textView = YPPlaceHolderTextView()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        sv(
            imageView,
            textView
        )
        
        let isIphone4 = UIScreen.main.bounds.height == 480
        let sideMargin: CGFloat = isIphone4 ? 20 : 0
        let textViewMargin: CGFloat = isIphone4 ? 20 : 10
        
        
        |-sideMargin-imageView.top(0)-sideMargin-|
        |-textViewMargin-textView-textViewMargin-|
        textView.bottom(0)
        textView.Top == imageView.Bottom
        |textView.centerVertically().height(200)|
        
        
        backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // TODO Make this editable thru config
        textView.placeholder = YPConfig.wordings.caption.placeholder
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.textColor = UIColor(r: 30, g: 30, b: 30)
    }
}
