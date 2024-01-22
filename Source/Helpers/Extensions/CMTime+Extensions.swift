//
//  CMTime+Extensions.swift
//  YPImagePicker
//
//  Created by Zeph Cohen on 1/22/24.
//  Copyright © 2024 Yummypets. All rights reserved.
//

import AVFoundation
import Foundation

extension CMTime {
    var durationText:String {
        let totalSeconds = Int(CMTimeGetSeconds(self))
        let hours:Int = Int(totalSeconds / 3600)
        let minutes:Int = Int(totalSeconds % 3600 / 60)
        let seconds:Int = Int((totalSeconds % 3600) % 60)

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%2i:%02i", minutes, seconds)
        }
    }
}
