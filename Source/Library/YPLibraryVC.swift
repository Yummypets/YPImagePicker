//
//  YPLibraryVC.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Photos

public class YPLibraryVC: UIViewController, PermissionCheckable {
    
    weak var delegate: YPLibraryViewDelegate?
    
    internal let configuration: YPImagePickerConfiguration!
    private var initialized = false
    
    var multipleSelectionEnabled = false
    internal var selectedIndices = [Int]()
    internal var currentlySelectedIndex: Int?
    internal let mediaManager = LibraryMediaManager()
    internal var latestImageTapped = ""
    private var imageLoadingTimer: Timer?
    var v: YPLibraryView!
    
    internal let panGestureHelper = PanGestureHelper()

    // MARK: - Init
    
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        title = configuration.wordings.libraryTitle
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAlbum(_ album: YPAlbum) {
        mediaManager.collection = album.collection
    }
    
    func initialize() {
        mediaManager.initialize()
    
        if mediaManager.fetchResult != nil {
            return
        }
        setupCollectionView()
        registerForLibraryChanges()
        panGestureHelper.registerForPanGesture(on: v)
        registerForTapOnPreview()
        refreshMediaRequest()
        v.imageCropViewContainer.onlySquareImages = configuration.onlySquareImagesFromLibrary
        
        v.imageCropViewContainer.multipleSelectionButton.isHidden = !(configuration.maxNumberOfItems > 1)
        v.imageCropView.onlySquareImages = configuration.onlySquareImagesFromLibrary
        v.maxNumberWarningLabel.text = String(format: configuration.wordings.warningMaxItemsLimit, configuration.maxNumberOfItems)
    }
    
    // MARK: - View Lifecycle
    
    public override func loadView() {
        v = YPLibraryView.xibView()
        view = v
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForPlayerReachedEndNotifications()
        v.imageCropViewContainer.squareCropButton.addTarget(self,
                                                            action: #selector(squareCropButtonTapped),
                                                            for: .touchUpInside)
        v.imageCropViewContainer.multipleSelectionButton.addTarget(self,
                                                            action: #selector(multipleSelectionButtonTapped),
                                                            for: .touchUpInside)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pausePlayer()
        NotificationCenter.default.removeObserver(self)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Crop control
    
    @objc
    func squareCropButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.v.imageCropViewContainer.squareCropButtonTapped()
        }
    }
    
    // MARK: - Multiple Selection

    @objc
    func multipleSelectionButtonTapped() {
        multipleSelectionEnabled = !multipleSelectionEnabled

        if multipleSelectionEnabled {
            if let currentlySelectedIndex = currentlySelectedIndex, selectedIndices.isEmpty {
                selectedIndices = [currentlySelectedIndex]
            }
        } else {
            selectedIndices.removeAll()
        }

        v.imageCropViewContainer.setMultipleSelectionMode(on: multipleSelectionEnabled)
        v.collectionView.reloadData()
        checkLimit()
        delegate?.libraryViewDidToggleMultipleSelection(enabled: multipleSelectionEnabled)
    }
    
    // MARK: - Tap Preview
    
    func registerForTapOnPreview() {
        let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        v.imageCropViewContainer.addGestureRecognizer(tapImageGesture)
    }
    
    @objc
    func tappedImage() {
        if !panGestureHelper.isImageShown {
            panGestureHelper.resetToOriginalState()
            // no dragup? needed? dragDirection = .up
            v.refreshImageCurtainAlpha()
        }
    }
    
    // MARK: - Permissions
    
    func doAfterPermissionCheck(block:@escaping () -> Void) {
        checkPermissionToAccessPhotoLibrary { hasPermission in
            if hasPermission {
                block()
            }
        }
    }
    
    func checkPermission() {
        checkPermissionToAccessPhotoLibrary { [unowned self] hasPermission in
            if hasPermission && !self.initialized {
                self.initialize()
                self.initialized = true
            }
        }
    }

    // Async beacause will prompt permission if .notDetermined
    // and ask custom popup if denied.
    func checkPermissionToAccessPhotoLibrary(block: @escaping (Bool) -> Void) {
        // Only intilialize picker if photo permission is Allowed by user.
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            block(true)
        case .restricted, .denied:
            let popup = YPPermissionDeniedPopup(configuration: configuration)
            let alert = popup.popup(cancelBlock: {
                block(false)
            })
            present(alert, animated: true, completion: nil)
        case .notDetermined:
            // Show permission popup and get new status
            PHPhotoLibrary.requestAuthorization { s in
                DispatchQueue.main.async {
                    block(s == .authorized)
                }
            }
        }
    }
    
    func refreshMediaRequest() {
        
        // Sorting condition
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if let collection = self.mediaManager.collection {
            if !configuration.showsVideoInLibrary {
                options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            }
            mediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            mediaManager.fetchResult = configuration.showsVideoInLibrary
                ? PHAsset.fetchAssets(with: options)
                : PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
        }
        
        if mediaManager.fetchResult.count > 0 {
            changeImage(mediaManager.fetchResult[0])
            v.collectionView.reloadData()
            v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                             animated: false,
                                             scrollPosition: UICollectionViewScrollPosition())
        }
        scrollToTop()
    }
    
    func scrollToTop() {
        tappedImage()
        v.collectionView.contentOffset = CGPoint.zero
    }
    
    // MARK: - ScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == v.collectionView {
            mediaManager.updateCachedAssets(in: self.v.collectionView)
        }
    }
    
    private func changeImageVideo(_ asset: PHAsset) {
        v.hideGrid()
        v.refreshCropControl()
        downloadAndSetPreviewFor(video: asset)
        downloadAndPlay(video: asset)
    }
    
    @objc
    func tick() {
        v.fadeInLoader()
        delegate?.libraryViewStartedLoadingImage()
    }
    
    private func changeImagePhoto(_ asset: PHAsset) {
        self.delegate?.libraryViewFinishedLoadingImage()
        self.v.hideLoader()
        imageLoadingTimer = Timer(timeInterval: 0.3, target: self,
                                  selector: #selector(tick),
                                  userInfo: nil,
                                  repeats: false)
        RunLoop.main.add(imageLoadingTimer!, forMode: .defaultRunLoopMode)
        mediaManager.imageManager?.fetch(photo: asset) { image, isFromCloud in
            // Prevent long images to come after user selected
            // another in the meantime.
            if self.latestImageTapped == asset.localIdentifier {
                if !isFromCloud {
                    self.imageLoadingTimer?.invalidate()
                    self.imageLoadingTimer = nil
                    self.delegate?.libraryViewFinishedLoadingImage()
                    self.v.hideLoader()
                }
                self.display(photo: asset, image: image)
            }
        }
    }

    func changeImage(_ asset: PHAsset) {
        mediaManager.selectedAsset = asset
        latestImageTapped = asset.localIdentifier
        asset.mediaType == .video ? v.setVideoMode() : v.setPhotoMode()
        v.hidePlayer()
        
        switch asset.mediaType {
        case .image:
            self.changeImagePhoto(asset)
        case .video:
            self.changeImageVideo(asset)
        case .audio, .unknown:
            ()
        }
    }
    
    // MARK: - Verification
    
    private func fitsVideoLengthLimits(asset: PHAsset) -> Bool {
        guard asset.mediaType == .video else {
            return true
        }
        
        let tooLong = asset.duration > configuration.videoFromLibraryTimeLimit
        let tooShort = asset.duration < configuration.videoMinimumTimeLimit
        
        if tooLong || tooShort {
            DispatchQueue.main.async {
                let alert = tooLong ? YPAlerts.videoTooLongAlert(with: self.configuration)
                    : YPAlerts.videoTooShortAlert(with: self.configuration)
                self.present(alert, animated: true, completion: nil)
            }
            return false
        }
        
        return true
    }
    
    // MARK: - Fetching Media
    
    private func fetchImage(for asset: PHAsset,
                            callback: @escaping (_ photo: UIImage) -> Void) {
        delegate?.libraryViewStartedLoadingImage()
        let cropRect = DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: cropRect)
        mediaManager.imageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }
    
    private func fetchVideoURL(for asset: PHAsset,
                               callback: @escaping (_ videoURL: URL) -> Void) {
        if fitsVideoLengthLimits(asset: asset) == true {
            delegate?.libraryViewStartedLoadingImage()
            mediaManager.imageManager?.fetchUrl(for: asset, callback: callback)
        }
    }
    
    public func selectedMedia(photoCallback:@escaping (_ photo: UIImage) -> Void,
                              videoCallback: @escaping (_ videoURL: URL) -> Void,
                              multipleItemsCallback: @escaping (_ items: [YPMediaItem]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            // Multiple selection
            if self.multipleSelectionEnabled && self.selectedIndices.count > 1 {
                let selectedAssets = self.selectedIndices.map { self.mediaManager.fetchResult[$0] }
                
                // Check video length
                for asset in selectedAssets {
                    if self.fitsVideoLengthLimits(asset: asset) == false {
                        return
                    }
                }
                
                // Fill result media items array
                var resultMediaItems: [YPMediaItem] = []
                let asyncGroup = DispatchGroup()
                
                for asset in selectedAssets {
                    asyncGroup.enter()
                    
                    switch asset.mediaType {
                    case .image:
                        self.fetchImage(for: asset) { image in
                            let resizedImage = self.resizedImageIfNeeded(image: image)
                            let photo = YPPhoto(image: resizedImage)
                            resultMediaItems.append(YPMediaItem(type: .photo,
                                               photo: photo,
                                               video: nil))
                            asyncGroup.leave()
                        }
                        
                    case .video:
                        self.fetchVideoURL(for: asset, callback: { videoURL in
                            createVideoItem(videoURL: videoURL,
                                            configuration: self.configuration,
                                            completion: { video in
                                                resultMediaItems.append(YPMediaItem(type: .video,
                                                                                    photo: nil,
                                                                                    video: video))
                                                asyncGroup.leave()
                            })
                        })
                    default:
                        break
                    }
                }
                
                asyncGroup.notify(queue: .main) {
                    multipleItemsCallback(resultMediaItems)
                }
        } else {
                let asset = self.mediaManager.selectedAsset!
                switch asset.mediaType {
                case .video:
                    self.fetchVideoURL(for: asset, callback: { videoURL in
                        DispatchQueue.main.async {
                            self.delegate?.libraryViewFinishedLoadingImage()
                            videoCallback(videoURL)
                        }
                    })
                case .image:
                    self.fetchImage(for: asset) { image in
                        DispatchQueue.main.async {
                            self.delegate?.libraryViewFinishedLoadingImage()
                            let resizedImage = self.resizedImageIfNeeded(image: image)
                            photoCallback(resizedImage)
                        }
                    }
                case .audio, .unknown:
                    return
                }
            }
        }
    }
    
    // MARK: - TargetSize
    
    private func targetSize(for asset: PHAsset, cropRect: CGRect) -> CGSize {
        let width = floor(CGFloat(asset.pixelWidth) * cropRect.width)
        let height = floor(CGFloat(asset.pixelHeight) * cropRect.height)
        return CGSize(width: width, height: height)
    }
    
    // Reduce image size further if needed libraryTargetImageSize is capped.
    func resizedImageIfNeeded(image: UIImage) -> UIImage {
                if case let YPLibraryImageSize.cappedTo(size: capped) = self.configuration.libraryTargetImageSize {
            let cappedWidth = min(image.size.width, capped)
            let cappedHeight = min(image.size.height, capped)
            let cappedSize = CGSize(width: cappedWidth, height: cappedHeight)
            if let resizedImage = image.resized(to: cappedSize) {
                return resizedImage
            }
        }
        return image
    }
    
    // MARK: - Player
    
    private func registerForPlayerReachedEndNotifications() {
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerItemDidReachEnd(_:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: nil)
    }
    
    @objc
    func playerItemDidReachEnd(_ note: Notification) {
        v.player?.actionAtItemEnd = .none
        v.player?.seek(to: kCMTimeZero)
        v.player?.play()
    }
    
    func pausePlayer() {
        v.pausePlayer()
    }
    
    func togglePlayPause() {
        guard let player = v.player else { return }
        player.togglePlayPause { _ in }
    }
    
    // MARK: - Deinit
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension UIImage {
    
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
