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
import Stevia

public enum YPVideoFiltersType {
    case Trimmer
    case Cover
}

open class YPVideoFiltersVC: UIViewController, IsMediaFilterVC {

    /// Designated initializer
    public class func initWith(video: YPMediaVideo,
                               isFromSelectionVC: Bool,
                               type: YPVideoFiltersType = .Trimmer) -> YPVideoFiltersVC {
        let vc = YPVideoFiltersVC()
        vc.inputVideo = video
        vc.isFromSelectionVC = isFromSelectionVC
        vc.vcType = type
        return vc
    }

    // MARK: - Public vars

    public var inputVideo: YPMediaVideo!
    public var inputAsset: AVAsset { return AVAsset(url: inputVideo.url) }
    public var didSave: ((YPMediaItem) -> Void)?
    public var didCancel: (() -> Void)?

    public let mediaManager = LibraryMediaManager() // used to crop and trim video
    public let progressView = UIProgressView()

    public var vcType: YPVideoFiltersType = .Trimmer

    public var playbackTimeCheckerTimer: Timer?
    public var imageGenerator: AVAssetImageGenerator?
    public var isFromSelectionVC = false

    public let trimmerContainerView: UIView = {
        let v = UIView()
        return v
    }()
    public var trimmerView: TrimmerView = {
        let v = TrimmerView()
        v.mainColor = YPConfig.colors.trimmerMainColor
        v.handleColor = YPConfig.colors.trimmerHandleColor
        v.positionBarColor = YPConfig.colors.positionLineColor
        v.maxDuration = YPConfig.video.trimmerMaxDuration
        v.minDuration = YPConfig.video.trimmerMinDuration
        return v
    }()
    public var coverThumbSelectorView: ThumbSelectorView = {
        let v = ThumbSelectorView()
        v.thumbBorderColor = YPConfig.colors.coverSelectorBorderColor
        v.isHidden = true
        return v
    }()
    public lazy var trimBottomItem: YPMenuItem = {
        let v = YPMenuItem()
        v.textLabel.text = YPConfig.wordings.trim
        v.button.addTarget(self, action: #selector(selectTrim), for: .touchUpInside)
        return v
    }()
    public lazy var coverBottomItem: YPMenuItem = {
        let v = YPMenuItem()
        v.textLabel.text = YPConfig.wordings.cover
        v.button.addTarget(self, action: #selector(selectCover), for: .touchUpInside)
        return v
    }()
    public var videoView: YPVideoView = {
        let v = YPVideoView()
        return v
    }()
    public var coverImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        return v
    }()

    // MARK: - Live cycle
    deinit {
        ypLog("deinit filters vc")
        mediaManager.forseCancelExporting()
        NotificationCenter.default.removeObserver(self)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        videoView.cropRect = inputVideo.cropRect // pass the crop rect over to the video so it can present the video relative to the crop rect
        videoView.asset = inputVideo.asset // pass the asset over so we can use it to determine the original video dimensions

        mediaManager.initialize()
        
        trimBottomItem.isHidden = true
        coverBottomItem.isHidden = true

        setupLayout()
        title = YPConfig.wordings.trim
        view.backgroundColor = YPConfig.colors.filterBackgroundColor
        setupNavigationBar(isFromSelectionVC: self.isFromSelectionVC)

        // Remove the default and add a notification to repeat playback from the start
        videoView.removeReachEndObserver()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(itemDidFinishPlaying(_:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: videoView.player.currentItem)

        videoView.clipsToBounds = true

        // configure progress view
        view.addSubview(progressView)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.fillHorizontally().height(5)
        progressView.Top == videoView.Bottom

        progressView.progressViewStyle = .bar
        progressView.trackTintColor = YPConfig.colors.progressBarTrackColor
        progressView.progressTintColor = YPConfig.colors.progressBarCompletedColor ?? YPConfig.colors.tintColor
        progressView.isHidden = true
        progressView.isUserInteractionEnabled = false
        progressView.progress = 0
    }

    open override func viewDidAppear(_ animated: Bool) {
        
        // Set initial video cover
        imageGenerator = AVAssetImageGenerator(asset: self.inputAsset)
        imageGenerator?.appliesPreferredTrackTransform = true
        didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))

        trimmerView.asset = inputAsset
        trimmerView.delegate = self
        
        coverThumbSelectorView.asset = inputAsset
        coverThumbSelectorView.delegate = self
        
        selectTrim()
        videoView.loadVideo(inputVideo)
        videoView.showPlayImage(show: true)
        startPlaybackTimeChecker()

        super.viewDidAppear(animated)

        if isMovingToParent {
            prepareThumbnails()
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // should be harmless to start the timer again, just ensure that this gets removed on disappear. we need to start this timer
        // here because the user can tap the video to start playback and this view controller isn't informed when that occurs.
        if let startTime = trimmerView.startTime {
            // seek to start time first
            videoView.player.seek(to: startTime)
        }

        startPlaybackTimeChecker()

        // reset progress
        progressView.isHidden = true
        progressView.progress = 0
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaybackTimeChecker()
        videoView.pause()
    }

    // MARK: - Setup

    private func setupGenerator() {
        // Set initial video cover
        imageGenerator = AVAssetImageGenerator(asset: inputAsset)
        imageGenerator?.appliesPreferredTrackTransform = true
        imageGenerator?.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator?.requestedTimeToleranceBefore = CMTime.zero
    }

    private func prepareThumbnails() {
        if vcType == .Trimmer {
            if trimmerView.asset != nil {
                return
            }

            trimmerView.asset = inputAsset
            trimmerView.delegate = self
            selectTrim()
            videoView.loadVideo(inputVideo)
            videoView.pause()
        } else {
            if coverThumbSelectorView.asset != nil {
                return
            }

            setupGenerator()
            coverThumbSelectorView.delegate = self
            coverThumbSelectorView.asset = inputAsset
            selectCover()
        }
    }

    private func setupNavigationBar(isFromSelectionVC: Bool) {
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
            navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
        }
        setupRightBarButtonItem()
    }

    private func setupRightBarButtonItem() {
        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.done : YPConfig.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
    }

    private func setupLayout() {

        view.sv(
            trimBottomItem,
            coverBottomItem,
            videoView,
            coverImageView,
            trimmerContainerView.sv(
                trimmerView,
                coverThumbSelectorView
            )
        )

        trimBottomItem.leading(0).height(40)
        trimBottomItem.Bottom == view.safeAreaLayoutGuide.Bottom
        trimBottomItem.Trailing == coverBottomItem.Leading
        coverBottomItem.Bottom == view.safeAreaLayoutGuide.Bottom
        coverBottomItem.trailing(0)
        equal(sizes: trimBottomItem, coverBottomItem)

        videoView.heightEqualsWidth().fillHorizontally().top(0)
        videoView.Bottom == trimmerContainerView.Top

        coverImageView.followEdges(videoView)

        trimmerContainerView.fillHorizontally()
        trimmerContainerView.Top == videoView.Bottom
        trimmerContainerView.Bottom == trimBottomItem.Top

        trimmerView.fillHorizontally(padding: 30).centerVertically()
        trimmerView.Height == trimmerContainerView.Height / 3

        coverThumbSelectorView.followEdges(trimmerView)
    }

    // MARK: - Actions

    private func completeSave(thumbnail:UIImage, videoUrl:URL, asset:PHAsset?) {
        guard let didSave = didSave else { return ypLog("Don't have saveCallback") }

        let resultVideo = YPMediaVideo(thumbnail: thumbnail, videoURL: videoUrl, asset: asset)
        didSave(YPMediaItem.video(v: resultVideo))
        setupRightBarButtonItem()

        // reset user interaction
        view.isUserInteractionEnabled = true

        // invalidate the timer to prevent memory leak
        stopPlaybackTimeChecker()
    }

    private func resetView() {
        // restore user interaction and right bar button item.
        view.isUserInteractionEnabled = true
        setupRightBarButtonItem()

        // reset progress
        progressView.isHidden = true
        progressView.progress = 0
    }

    @objc public func save() {
        guard let _ = didSave else { return ypLog("Don't have saveCallback") }
        navigationItem.rightBarButtonItem = YPLoaders.defaultLoader

        // disable user interaction so user cannot make more adjustments
        view.isUserInteractionEnabled = false

        // if the view is in cover image selection mode, just pass the asset straight through because it's not transforming the asset in any way
        if vcType == .Cover {
            if let coverImage = self.coverImageView.image {
                self.completeSave(thumbnail: coverImage, videoUrl: self.inputVideo.url, asset: self.inputVideo.asset)
            } else {
                ypLog("YPVideoFiltersVC -> Don't have coverImage.")
                self.resetView()
            }

            return
        }

        do {
            let asset = AVURLAsset(url: inputVideo.url)
            let startTime = trimmerView.startTime ?? CMTime.zero
            let endTime = trimmerView.endTime ?? inputAsset.duration

            // check if any trimming and cropping is involved - wc
            let untrimmed = CMTimeCompare(startTime, CMTime.zero) == 0 && CMTimeCompare(endTime, inputAsset.duration) == 0

            var cropped = false

            if let cropRect = self.inputVideo.cropRect, let asset = self.inputVideo.asset {
                let pixelWidth = CGFloat(asset.pixelWidth)
                let pixelHeight = CGFloat(asset.pixelHeight)
                cropped = cropRect.size.width < pixelWidth || cropRect.size.height < pixelHeight
            }

            // check if video is rotated
            guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
                ypLog("⚠️ Problems with video track")
                return
            }

            let rotated = !videoTrack.preferredTransform.isIdentity

            if untrimmed && !cropped && !rotated {
                // if video remains untrimmed and uncropped, use existing video url to eliminate video transcoding effort
                // we will be selecting a cover image next, use generic uiimage for now
                self.completeSave(thumbnail: UIImage(), videoUrl: self.inputVideo.url, asset: self.inputVideo.asset)

                return
            }

            let timeRange = CMTimeRange(start: startTime, end: endTime)

            // cropping and trimming simultaneously to reduce total transcoding time
            mediaManager.fetchVideoUrlAndCrop(for: inputVideo.asset!, cropRect: inputVideo.cropRect!, timeRange: timeRange) { [weak self] (url) in
                DispatchQueue.main.async {
                    if let url = url {
                        self?.completeSave(thumbnail:  UIImage(), videoUrl: url, asset: self?.inputVideo.asset)
                    } else {
                        ypLog("YPVideoFiltersVC -> Invalid asset url.")
                        self?.resetView()
                    }
                }
            }

            // set up notification listener
            progressView.isHidden = false

            NotificationCenter.default.addObserver(self, selector: #selector(onExportProgressUpdate(notification:)), name: .LibraryMediaManagerExportProgressUpdate, object: mediaManager)
        } catch let error {
            ypLog("💩 \(error)")
        }
    }

    @objc
    func onExportProgressUpdate(notification:Notification) {
        if let info = notification.userInfo as? [String:Float], let progress = info["progress"] {
            if progress < progressView.progress {
                progressView.isHidden = true // progress has reached the end
            }
            
            progressView.progress = progress
        }
    }
    
    @objc private func cancel() {
        didCancel?()
    }

    // MARK: - Bottom buttons

    @objc private func selectTrim() {
        title = YPConfig.wordings.trim

        trimmerView.isHidden = false
        videoView.isHidden = false
        coverImageView.isHidden = true
        coverThumbSelectorView.isHidden = true
    }
    
    @objc private func selectCover() {
        title = YPConfig.wordings.cover

        trimmerView.isHidden = true
        videoView.isHidden = true
        coverImageView.isHidden = false
        coverThumbSelectorView.isHidden = false
        
        stopPlaybackTimeChecker()
        videoView.stop()
    }
    
    // MARK: - Various Methods

    // Updates the bounds of the cover picker if the video is trimmed
    // TODO: Now the trimmer framework doesn't support an easy way to do this.
    // Need to rethink a flow or search other ways.
    private func updateCoverPickerBounds() {
        if let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime {
            if let selectedCoverTime = coverThumbSelectorView.selectedTime {
                let range = CMTimeRange(start: startTime, end: endTime)
                if !range.containsTime(selectedCoverTime) {
                    // If the selected before cover range is not in new trimeed range,
                    // than reset the cover to start time of the trimmed video
                }
            } else {
                // If none cover time selected yet, than set the cover to the start time of the trimmed video
            }
        }
    }
    
    // MARK: - Trimmer playback
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else {
            return
        }

        if item != videoView.player.currentItem {
            return // ignore notifications that aren't for this player item
        }

        if let startTime = trimmerView.startTime {
            videoView.player.actionAtItemEnd = .none
            videoView.player.seek(to: startTime)
            videoView.player.play()
        }
    }
    
    private func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer
            .scheduledTimer(timeInterval: 0.05, target: self,
                            selector: #selector(onPlaybackTimeChecker),
                            userInfo: nil,
                            repeats: true)
    }
    
    private func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc private func onPlaybackTimeChecker() {
        guard let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime else {
            return
        }
        
        let playBackTime = videoView.player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            videoView.player.seek(to: startTime,
                                  toleranceBefore: CMTime.zero,
                                  toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

// MARK: - TrimmerViewDelegate
extension YPVideoFiltersVC: TrimmerViewDelegate {
    public func positionBarStoppedMoving(_ playerTime: CMTime) {
        // user has lifted off trimmer handle so restart the video at trimmer start time
        if let startTime = trimmerView.startTime {
            videoView.player.seek(to: startTime)
            videoView.play()
            videoView.removeReachEndObserver() // videoView.play() adds reach end observer so we need to remove it again.
            startPlaybackTimeChecker()
        }
    }

    public func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        videoView.pause()
        videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
}

// MARK: - ThumbSelectorViewDelegate
extension YPVideoFiltersVC: ThumbSelectorViewDelegate {
    public func didChangeThumbPosition(_ imageTime: CMTime) {
        let generator = imageGenerator
        let time = imageTime

        // fetch new image
        generator?.generateCGImagesAsynchronously(forTimes: [NSValue(time:time)],
                                                  completionHandler: { (_, image, _, _, _) in
            guard let image = image else {
                return
            }

            // it's safe to create UIImages off the main thread
            let uiimage = UIImage(cgImage: image)

            DispatchQueue.main.async { [weak self] in
                generator?.cancelAllCGImageGeneration()
                self?.coverImageView.image = uiimage
            }
        })
    }
}
