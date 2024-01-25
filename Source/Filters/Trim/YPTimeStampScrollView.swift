//
//  YPTimeStampScrollView.swift
//  YPImagePicker
//
//  Created by Zeph Cohen on 1/22/24.
//  Copyright © 2024 Yummypets. All rights reserved.
//

import AVFoundation
import UIKit

struct YPTimeStampViewModel {
    let shouldRenderTimeStamp: Bool
    let timeRange: CMTimeRange
    let startTime: CMTime
    let endTime: CMTime
    let durationText: String

    init(shouldRenderTimeStamp: Bool, timeRange: CMTimeRange) {
        self.shouldRenderTimeStamp = shouldRenderTimeStamp
        self.timeRange = timeRange
        self.startTime = timeRange.start
        self.endTime = timeRange.end
        self.durationText = timeRange.start.durationText
    }
}

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



    func generateTimeStampViewModels(timeRangeAmount: Int) -> [YPTimeStampViewModel] {
        var timeStamps: [YPTimeStampViewModel] = []

        return []


    }

    func generateTimeRanges(for assetDuration: CMTime) -> [YPTimeStampViewModel] {
        let totalSeconds = CMTimeGetSeconds(assetDuration)
        var timeStamps: [YPTimeStampViewModel] = []

        var timeRangeAmount: Double = 0
        if totalSeconds < 30 {
            timeRangeAmount = totalSeconds
            for i in 0...Int(timeRangeAmount) {
                if i == 0 {
                    timeStamps.append(YPTimeStampViewModel(shouldRenderTimeStamp: true, timeRange: CMTimeRange(start: buildTime(seconds: 0), duration: buildTime(seconds: 1))))
                } else {
                    let previousTimeStamp = timeStamps[i-1]
                    timeStamps.append(YPTimeStampViewModel(shouldRenderTimeStamp: i % 5 == 0, timeRange: CMTimeRange(start: previousTimeStamp.endTime, duration: buildTime(seconds: 1))))
                }
            }
        } else if totalSeconds >= 30, totalSeconds <= 60 {
            let fiveSecondDivisor: Double = 5.0
            timeRangeAmount = round(totalSeconds / fiveSecondDivisor)

            for i in 0...Int(timeRangeAmount) {
                if i == 0 {
                    timeStamps.append(YPTimeStampViewModel(shouldRenderTimeStamp: true, timeRange: CMTimeRange(start: buildTime(seconds: 0), duration: buildTime(seconds: 5))))
                } else {
                    let previousTimeStamp = timeStamps[i-1]
                    timeStamps.append(YPTimeStampViewModel(shouldRenderTimeStamp: i % 3 == 0, timeRange: CMTimeRange(start: previousTimeStamp.endTime, duration: buildTime(seconds: 5))))
                }
            }
        } else {
            let tenSecondDivisor: Double = 10
            timeRangeAmount = round(totalSeconds / tenSecondDivisor)

            for i in 0...Int(timeRangeAmount) {
                if i == 0 {
                    timeStamps.append(YPTimeStampViewModel(shouldRenderTimeStamp: true, timeRange: CMTimeRange(start: buildTime(seconds: 0), duration: buildTime(seconds: 10))))
                } else {
                    let previousTimeStamp = timeStamps[i-1]
                    timeStamps.append(YPTimeStampViewModel(shouldRenderTimeStamp: i % 3 == 0, timeRange: CMTimeRange(start: previousTimeStamp.endTime, duration: buildTime(seconds: 10))))
                }
            }
        }

        return timeStamps
    }


    func renderRanges() {
        guard let videoDuration = asset?.duration else { return }

        let ranges = generateTimeRanges(for: videoDuration)
        let subViewWidth = contentSize.width / CGFloat(ranges.count)
        let handleBarWidth: CGFloat = 15

        for i in 0..<ranges.count {
            let contentViewSubView = YPTimeStampView(
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
            
            //We also need to move the xPosition forward by the same offset value used to pull the time stamp UI back to the left. This pullback is
            // done so the time stamp UI appears to "scroll before" the trim UI. This additional offset is to compensate for that adjustment and allow
            // the trim bar handle calculations to match up with the timestamps below.
            let xPositionWithHandleOffset = xPosition + handleBarWidth + YPTimeStampTrimmerView.Constant.timeStampTrimViewPadding
            // We slightly pull back the the x posotion by the subViewWidth / 2 to properly align the timestamp with where the drag handle time should
            // be. In other words, the center of the draggable handle should reflect the correct timestamp at the very center of the dot.
            contentViewSubView.frame = CGRect(x: xPositionWithHandleOffset - (subViewWidth / 2), y: 0, width: subViewWidth, height: 23)
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
