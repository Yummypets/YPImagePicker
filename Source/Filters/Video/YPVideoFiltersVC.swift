//
//  VideoFiltersVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos
import Trimmer

public class YPVideoFiltersVC: UIViewController {
    @IBOutlet weak var trimBottomItem: YPMenuItem!
    @IBOutlet weak var coverBottomItem: YPMenuItem!
    
    @IBOutlet weak var videoView: YPVideoView!
    @IBOutlet weak var trimmerView: TrimmerView!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var coverThumbSelectorView: ThumbSelectorView!

    public var inputVideo: YPVideo!
    public var inputAsset: AVAsset { return AVAsset(url: inputVideo.url!) }
    public var configuration: YPImagePickerConfiguration!
    
    private var playbackTimeCheckerTimer: Timer?
    private var imageGenerator: AVAssetImageGenerator?

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

        trimmerView.mainColor = configuration.colors.trimmerMainColor
        trimmerView.handleColor = configuration.colors.trimmerHandleColor
        trimmerView.positionBarColor = configuration.colors.positionLineColor
        trimmerView.maxDuration = configuration.trimmerMaxDuration
        trimmerView.minDuration = configuration.trimmerMinDuration
        
        coverThumbSelectorView.thumbBorderColor = configuration.colors.coverSelectorColor
        
        trimBottomItem.textLabel.text = configuration.wordings.trim
        coverBottomItem.textLabel.text = configuration.wordings.cover

        trimBottomItem.button.addTarget(self, action: #selector(selectTrim), for: .touchUpInside)
        coverBottomItem.button.addTarget(self, action: #selector(selectCover), for: .touchUpInside)
        
        // Add a notification to repeat playback from the start
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(itemDidFinishPlaying(_:)),
                         name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                         object: nil)
        
        // Set initial video cover
        imageGenerator = AVAssetImageGenerator(asset: self.inputAsset)
        imageGenerator?.appliesPreferredTrackTransform = true
        didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))
        
        // Navigation bar setup
        navigationController?.navigationBar.tintColor = configuration.colors.pickerNavigationBarTextColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: configuration.wordings.save,
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(save))
        YPHelpers.changeBackButtonTitle(self)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        trimmerView.asset = inputAsset
        trimmerView.delegate = self
        
        coverThumbSelectorView.asset = inputAsset
        coverThumbSelectorView.delegate = self
        
        selectTrim()
        videoView.loadVideo(video: inputVideo)

        super.viewDidAppear(animated)
    }
    
    @objc public func save() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: Bottom buttons

    @objc public func selectTrim() {
        trimBottomItem.select()
        coverBottomItem.deselect()

        trimmerView.isHidden = false
        videoView.isHidden = false
        coverImageView.isHidden = true
        coverThumbSelectorView.isHidden = true
    }
    
    @objc public func selectCover() {
        trimBottomItem.deselect()
        coverBottomItem.select()
        
        trimmerView.isHidden = true
        videoView.isHidden = true
        coverImageView.isHidden = false
        coverThumbSelectorView.isHidden = false
        
        stopPlaybackTimeChecker()
        videoView.stop()
    }
    
    // MARK: Trimmer playback
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            videoView.player.seek(to: startTime)
        }
    }
    
    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer
            .scheduledTimer(timeInterval: 0.1, target: self,
                            selector: #selector(onPlaybackTimeChecker),
                            userInfo: nil,
                            repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {
        guard let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime else {
            return
        }
        
        let playBackTime = videoView.player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            videoView.player.seek(to: startTime,
                                  toleranceBefore: kCMTimeZero,
                                  toleranceAfter: kCMTimeZero)
            trimmerView.seek(to: startTime)
        }
    }
}

// MARK: - TrimmerViewDelegate
extension YPVideoFiltersVC: TrimmerViewDelegate {
    public func positionBarStoppedMoving(_ playerTime: CMTime) {
        videoView.player.seek(to: playerTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        videoView.play()
        startPlaybackTimeChecker()
    }
    
    public func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        videoView.pause()
        videoView.player.seek(to: playerTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
    }
}

// MARK: - ThumbSelectorViewDelegate
extension YPVideoFiltersVC: ThumbSelectorViewDelegate {
    public func didChangeThumbPosition(_ imageTime: CMTime) {
        let imageRef = try! imageGenerator?.copyCGImage(at: imageTime, actualTime: nil)
        if let imageRef = imageRef {
            coverImageView.image = UIImage(cgImage: imageRef)
        }
    }
}
