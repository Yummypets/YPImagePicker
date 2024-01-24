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

    func buildTime(seconds: Double) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: Int32(NSEC_PER_SEC))
    }
    func renderRanges() {
        guard let videoDuration = asset?.duration else { return }

        let ranges = generateTimeRanges(for: videoDuration)
        let subViewWidth = contentSize.width / CGFloat(ranges.count)
        let handleBarWidth: CGFloat = 15

        for i in 0..<ranges.count {
            let contentViewSubView = YPTrimmerTimeStampView(
                timeStampFont: timeStampFont,
                timeStampColor: timeStampColor,
                timeBarColor: timeBarColor
            )

            let range = ranges[i]

            guard var xPosition = getPosition(from: range.startTime) else { continue }

            if range.shouldRenderTimeStamp, let asset = asset {
                contentViewSubView.shouldRenderBoldCircle = true
                contentViewSubView.timeStampText = range.durationText
            }
            // We want the first 0:00 dot to line up just after the left handle bar. This offset is to account for the handle bar width and
            // start the first timestamp just to the right of the left handle.
            let xPositionWithHandleOffset = xPosition + handleBarWidth
            // We slightly pull back the the x posotion by the subViewWidth / 2 to properly align the timestamp with where the drag handle time should
            // be. In other words, the center of the draggable handle should reflect the correct timestamp at the very center of the dot.
            contentViewSubView.frame = CGRect(x: xPositionWithHandleOffset  - (subViewWidth / 2), y: 0, width: subViewWidth, height: 23)
            addSubview(contentViewSubView)
        }
    }

    func getTime(from position: CGFloat, for asset: AVAsset) -> CMTime? {
        let normalizedRatio = max(min(1, position / contentSize.width), 0)
        let positionTimeValue = Double(normalizedRatio) * Double(asset.duration.value)
        return CMTime(value: Int64(positionTimeValue), timescale: asset.duration.timescale)
    }

    func getPosition(from time: CMTime) -> CGFloat? {
        guard let asset = asset else {
            return nil
        }
        let timeRatio = CGFloat(time.value) * CGFloat(asset.duration.timescale) /
        (CGFloat(time.timescale) * CGFloat(asset.duration.value))
        return timeRatio * contentSize.width
    }
}
