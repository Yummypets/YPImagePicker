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
    internal var previouslySelectedIndex: Int?
    internal let mediaManager = LibraryMediaManager()
    internal var latestImageTapped = ""
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
        v.imageCropView.onlySquareImages = configuration.onlySquareImagesFromLibrary
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
        v.showLoader()
        v.refreshCropControl()
        downloadAndSetPreviewFor(video: asset)
        downloadAndPlay(video: asset)
    }
    
    private func changeImagePhoto(_ asset: PHAsset) {
        mediaManager.imageManager?.fetch(photo: asset) { image, isFromCloud in
            // Prevent long images to come after user selected
            // another in the meantime.
            if self.latestImageTapped == asset.localIdentifier {
                if isFromCloud {
                    self.v.showLoader()
                } else {
                    self.v.fadeOutLoader()
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
    
    private func showVideoTooLongAlert() {
        let alert = YPAlerts.videoTooLongAlert(with: configuration)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Fetching Media
    
    private func fetchImage(for asset: PHAsset, callback: @escaping (_ photo: UIImage) -> Void) {
        delegate?.libraryViewStartedLoadingImage()
        let cropRect = DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: cropRect)
        mediaManager.imageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }
    
    private func fetchVideoURL(for asset: PHAsset, callback: @escaping (_ videoURL: URL) -> Void) {
        if asset.duration > configuration.videoFromLibraryTimeLimit {
            showVideoTooLongAlert()
        } else {
            delegate?.libraryViewStartedLoadingImage()
            mediaManager.imageManager?.fetchUrl(for: asset, callback: callback)
        }
    }
    
    // MARK: - TargetSize
    
    private func targetSize(for asset: PHAsset, cropRect: CGRect) -> CGSize {
        let width = floor(CGFloat(asset.pixelWidth) * cropRect.width)
        let height = floor(CGFloat(asset.pixelHeight) * cropRect.height)
        return CGSize(width: width, height: height)
    }
    
    public func selectedMedia(photoCallback:@escaping (_ photo: UIImage) -> Void,
                              videoCallback: @escaping (_ videoURL: URL) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
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
        player.togglePlayPause()
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
