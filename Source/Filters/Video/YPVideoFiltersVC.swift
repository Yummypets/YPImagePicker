//
//  VideoFiltersVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos
import PryntTrimmerView

public class YPVideoFiltersVC: UIViewController, IsMediaFilterVC {
    
    @IBOutlet weak var trimBottomItem: YPMenuItem!
    @IBOutlet weak var coverBottomItem: YPMenuItem!
    
    @IBOutlet weak var videoView: YPVideoView!
    @IBOutlet weak var trimmerView: TrimmerView!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var coverThumbSelectorView: ThumbSelectorView!

    public var inputVideo: YPVideo!
    public var inputAsset: AVAsset { return AVAsset(url: inputVideo.url) }
    
    private var playbackTimeCheckerTimer: Timer?
    private var imageGenerator: AVAssetImageGenerator?
    private var isFromSelectionVC = false
    
    var didSave: ((YPMediaItem) -> Void)?
    var didCancel: (() -> Void)?

    /// Designated initializer
    public class func initWith(video: YPVideo,
                               isFromSelectionVC: Bool) -> YPVideoFiltersVC {
        let vc = YPVideoFiltersVC(nibName: "YPVideoFiltersVC", bundle: Bundle(for: YPVideoFiltersVC.self))
        vc.inputVideo = video
        vc.isFromSelectionVC = isFromSelectionVC
        
        return vc
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        trimmerView.mainColor = YPConfig.colors.trimmerMainColor
        trimmerView.handleColor = YPConfig.colors.trimmerHandleColor
        trimmerView.positionBarColor = YPConfig.colors.positionLineColor
        trimmerView.maxDuration = YPConfig.trimmerMaxDuration
        trimmerView.minDuration = YPConfig.trimmerMinDuration
        
        coverThumbSelectorView.thumbBorderColor = YPConfig.colors.coverSelectorColor
        
        trimBottomItem.textLabel.text = YPConfig.wordings.trim
        coverBottomItem.textLabel.text = YPConfig.wordings.cover

        trimBottomItem.button.addTarget(self, action: #selector(selectTrim), for: .touchUpInside)
        coverBottomItem.button.addTarget(self, action: #selector(selectCover), for: .touchUpInside)
        
        // Remove the default and add a notification to repeat playback from the start
        videoView.removeReachEndObserver()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(itemDidFinishPlaying(_:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: nil)
        
        // Set initial video cover
        imageGenerator = AVAssetImageGenerator(asset: self.inputAsset)
        imageGenerator?.appliesPreferredTrackTransform = true
        didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))
        
        // Navigation bar setup
        title = YPConfig.wordings.filter
        navigationController?.navigationBar.tintColor = YPConfig.colors.navigationBarTextColor
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
        }
        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.save : YPConfig.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(save))
        YPHelper.changeBackButtonTitle(self)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        trimmerView.asset = inputAsset
        trimmerView.delegate = self
        
        coverThumbSelectorView.asset = inputAsset
        coverThumbSelectorView.delegate = self
        
        selectTrim()
        videoView.loadVideo(inputVideo)

        super.viewDidAppear(animated)
    }
    
    @objc
    func cancel() {
        didCancel?()
    }
    
    @objc
    public func save() {
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        YPLoaders.enableActivityIndicator(barButtonItem: &self.navigationItem.rightBarButtonItem)

        do {
            let asset = AVURLAsset(url: inputVideo.url)
            let trimmedAsset = try asset
                .assetByTrimming(startTime: trimmerView.startTime ?? kCMTimeZero,
                                 endTime: trimmerView.endTime ?? inputAsset.duration)
            
            // Looks like file:///private/var/mobile/Containers/Data/Application/FAD486B4-784D-4397-B00C-AD0EFFB45F52/tmp/8A2B410A-BD34-4E3F-8CB5-A548A946C1F1.mov
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingUniquePathComponent(pathExtension: YPConfig.videoExtension.fileExtension)
            
            try trimmedAsset.export(to: destinationURL) { [weak self] in
                guard let weakSelf = self else { return }
                
                DispatchQueue.main.async {
                    let resultVideo = YPVideo(thumbnail: weakSelf.coverImageView.image!,
                                              videoURL: destinationURL)
                    didSave(YPMediaItem.video(v: resultVideo))
                }
            }
        } catch let error {
            print("💩 \(error)")
        }
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
            .scheduledTimer(timeInterval: 0.05, target: self,
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
