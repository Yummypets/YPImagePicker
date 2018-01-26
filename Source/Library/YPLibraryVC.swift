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
    var collection: PHAssetCollection?
    
    internal let configuration: YPImagePickerConfiguration!
    private var initialized = false
    internal var previouslySelectedIndex: Int?
    internal var fetchResult: PHFetchResult<PHAsset>!
    internal var imageManager: PHCachingImageManager?
    internal var previousPreheatRect: CGRect = CGRect.zero
    private var selectedAsset: PHAsset!
    internal var latestImageTapped = ""
    var v: YPLibraryView!
    internal static let cellSize = CGSize(width: UIScreen.main.bounds.width/4 * UIScreen.main.scale,
                                          height: UIScreen.main.bounds.width/4 * UIScreen.main.scale)
    
    // Pan gesture
    internal let imageCropViewOriginalConstraintTop: CGFloat = 0
    internal var dragDirection = YPDragDirection.up
    internal var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    internal var cropBottomY: CGFloat  = 0.0
    internal var dragStartPos: CGPoint = .zero
    internal let dragDiff: CGFloat = 0
    var _isImageShown = true
    var isImageShown: Bool {
        get { return self._isImageShown }
        set {
            if newValue != isImageShown {
                self._isImageShown = newValue
                v.imageCropViewContainer.isShown = newValue
                // Update imageCropContainer
                v.imageCropView.isScrollEnabled = isImageShown
            }
        }
    }
    
    // MARK: - Init
    
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        title = ypLocalized("YPImagePickerLibrary")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialize() {
        imageManager = PHCachingImageManager()
        if fetchResult != nil {
            return
        }
        resetCachedAssets()
        setupCollectionView()
        registerForLibraryChanges()
        registerForPanGesture()
        registerForTapOnPreview()
        
        v.imageCropViewConstraintTop.constant = 0
        dragDirection = YPDragDirection.up
        
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
        if !isImageShown {
            v.imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
            UIView.animate(withDuration: 0.2,
                           delay: 0.0,
                           options: .curveEaseOut,
                           animations: v.layoutIfNeeded,
                           completion: nil)
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
            let alert = YPPermissionDeniedPopup.popup(cancelBlock: {
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
        
        if let collection = self.collection {
            if !configuration.showsVideo {
                options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            }
            fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            fetchResult = configuration.showsVideo
                ? PHAsset.fetchAssets(with: options)
                : PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
        }
        
        if fetchResult.count > 0 {
            changeImage(fetchResult[0])
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
            updateCachedAssets()
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
        imageManager?.fetch(photo: asset) { image, isFromCloud in
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
        selectedAsset = asset
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
    
    // MARK: - Asset Caching
    
    func resetCachedAssets() {
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    func updateCachedAssets() {
        var preheatRect = v.collectionView!.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > v.collectionView!.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            previousPreheatRect.differenceWith(rect: preheatRect,
                                              removedHandler: { removedRect in
                let indexPaths = self.v.collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
                }, addedHandler: {addedRect in
                    let indexPaths = self.v.collectionView.aapl_indexPathsForElementsInRect(addedRect)
                    addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching =  fetchResult.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = fetchResult.assetsAtIndexPaths(removedIndexPaths)
            
            imageManager?.startCachingImages(for: assetsToStartCaching,
                                                  targetSize: YPLibraryVC.cellSize,
                                                  contentMode: .aspectFill,
                                                  options: nil)
            imageManager?.stopCachingImages(for: assetsToStopCaching,
                                                 targetSize: YPLibraryVC.cellSize,
                                                 contentMode: .aspectFill,
                                                 options: nil)
            previousPreheatRect = preheatRect
        }
    }
    
    private func showVideoTooLongAlert() {
        let alert = YPAlerts.videoTooLongAlert(with: configuration)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Fetching Media
    
    private func fetchImage(for asset: PHAsset, callback: @escaping (_ photo: UIImage) -> Void) {
        delegate?.libraryViewStartedLoadingImage()
        let cropRect = v.currentCropRect()
        let ts = targetSize(for: asset, cropRect: cropRect)
        imageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }
    
    private func fetchVideoURL(for asset: PHAsset, callback: @escaping (_ videoURL: URL) -> Void) {
        if asset.duration > configuration.videoFromLibraryTimeLimit {
            showVideoTooLongAlert()
        } else {
            delegate?.libraryViewStartedLoadingImage()
            imageManager?.fetchUrl(for: asset, callback: callback)
        }
    }
    
    // MARK: - TargetSize
    
    private func targetSize(for asset: PHAsset, cropRect: CGRect) -> CGSize {
        let width = floor(CGFloat(asset.pixelWidth) * cropRect.width)
        let height = floor(CGFloat(asset.pixelHeight) * cropRect.height)
        if case let YPLibraryImageSize.cappedTo(size: capped) = configuration.libraryTargetImageSize {
            let cappedWidth = min(width, capped)
            let cappedHeight = min(height, capped)
            return CGSize(width: cappedWidth, height: cappedHeight)
        }
        return CGSize(width: width, height: height)
    }
    
    public func selectedMedia(photoCallback:@escaping (_ photo: UIImage) -> Void,
                              videoCallback: @escaping (_ videoURL: URL) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = self.selectedAsset!
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
                        photoCallback(image)
                    }
                }
            case .audio, .unknown:
                return
            }
        }
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
