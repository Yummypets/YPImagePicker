//
//  YPTimeStampScrollView.swift
//  YPImagePicker
//
//  Created by Zeph Cohen on 1/22/24.
//  Copyright © 2024 Yummypets. All rights reserved.
//

import AVFoundation
import UIKit

class YPTimeStampScrollableView: UIScrollView {

    var asset: AVAsset?
    var timeStampColor: UIColor?
    var timeBarColor: UIColor?
    var timeStampFont: UIFont?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    func setupSubviews() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    func renderContentViews() {
        let width: Int = 32
        let startOffset: Int = 0

        var viewCount = Int(contentSize.width) / width

        viewCount += 1

        for i in 0..<viewCount{
            let contentViewSubView = YPTrimmerTimeStampView(
                timeStampFont: timeStampFont,
                timeStampColor: timeStampColor,
                timeBarColor: timeBarColor
            )
            if i == 0 || i % 3 == 0 {
                contentViewSubView.shouldRenderBoldCircle = true
            }

            let xPosition = i * width

            if i % 6 == 0, let asset = asset {
                contentViewSubView.timeStampText = getTime(from: CGFloat(xPosition), for: asset)?.durationText
            }

//            if let asset = asset {
//                let xPosition = i * width
//                print("DEBUG: X POSITION:\(xPosition) TIME FOR POSITION: \(String(describing: getTime(from: CGFloat(xPosition), for: asset)?.durationText)) ASSET LENGTH: \(asset.duration.durationText)")
//            }

            contentViewSubView.frame = CGRect(x: (i * width) + startOffset, y: 0, width: width, height: 30)
            addSubview(contentViewSubView)
        }
    }

    func getTime(from position: CGFloat, for asset: AVAsset) -> CMTime? {
        let normalizedRatio = max(min(1, position / contentSize.width), 0)
        let positionTimeValue = Double(normalizedRatio) * Double(asset.duration.value)
        return CMTime(value: Int64(positionTimeValue), timescale: asset.duration.timescale)
    }
}
