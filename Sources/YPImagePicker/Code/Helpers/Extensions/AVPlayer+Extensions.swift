//
//  AVPlayer+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import AVFoundation

extension AVPlayer {
    func togglePlayPause(completion: (_ isPlaying: Bool) -> Void) {
        if rate == 0 {
            play()
            completion(true)
        } else {
            pause()
            completion(false)
        }
    }
}
