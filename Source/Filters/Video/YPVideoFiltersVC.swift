//
//  VideoFiltersVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

public class YPVideoFiltersVC: UIViewController {
    @IBOutlet weak var videoView: YPVideoView!
    @IBOutlet weak var trimBottomItem: YPMenuItem!
    @IBOutlet weak var coverBottomItem: YPMenuItem!
    
    @IBOutlet weak var trimmerView: TrimmerView!
    
    public var inputVideo: YPVideo!
    public var configuration: YPImagePickerConfiguration!

    /// Designated initializer
    public class func initWith(video: YPVideo,
                        configuration: YPImagePickerConfiguration) -> YPVideoFiltersVC {
        let vc = YPVideoFiltersVC(nibName: "YPVideoFiltersVC", bundle: Bundle(for: YPVideoFiltersVC.self))
        vc.configuration = configuration
        vc.inputVideo = video
        
        return vc
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        trimBottomItem.textLabel.text = configuration.wordings.trim
        coverBottomItem.textLabel.text = configuration.wordings.cover

        trimBottomItem.button.addTarget(self, action: #selector(selectTrim), for: .touchUpInside)
        coverBottomItem.button.addTarget(self, action: #selector(selectCover), for: .touchUpInside)
        
        selectTrim()
        videoView.startPlayingVideo(video: inputVideo)
    }
    
    @objc public func selectTrim() {
        trimBottomItem.select()
        coverBottomItem.deselect()
        print("🧀 Trimmer view frame: \(trimmerView.frame)")

//        let asset = AVAsset(url: inputVideo.url!)
        let asset2 = AVAsset(url: URL(fileURLWithPath: "file:///var/mobile/Media/DCIM/100APPLE/IMG_0068.MOV"))
        trimmerView.asset = asset2
        trimmerView.delegate = self
    }
    
    @objc public func selectCover() {
        trimBottomItem.deselect()
        coverBottomItem.select()
    }
}

// MARK: - TrimmerViewDelegate
extension YPVideoFiltersVC: TrimmerViewDelegate {
    public func positionBarStoppedMoving(_ playerTime: CMTime) {
        videoView.player.seek(to: playerTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        videoView.player.play()
//        startPlaybackTimeChecker()
    }
    
    public func didChangePositionBar(_ playerTime: CMTime) {
//        stopPlaybackTimeChecker()
        videoView.player.pause()
        videoView.player.seek(to: playerTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
    }
}
