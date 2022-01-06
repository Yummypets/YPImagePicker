//
//  YPLibraryVC.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

internal final class YPLibraryVC: UIViewController, YPPermissionCheckable {
    internal weak var delegate: YPLibraryViewDelegate?
    internal var v = YPLibraryView(frame: .zero)
    internal var isProcessing = false // true if video or image is in processing state
    internal var selectedItems = [YPLibrarySelection]()
    internal let mediaManager = LibraryMediaManager()
    internal var isMultipleSelectionEnabled = false
    internal var currentlySelectedIndex: Int = 0
    internal let panGestureHelper = PanGestureHelper()
    internal var isInitialized = false

    // MARK: - Init

    internal override func loadView() {
        view = v
    }

    required init() {
        super.init(nibName: nil, bundle: nil)
        title = YPConfig.wordings.libraryTitle
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialize() {
        guard isInitialized == false else {
            return
        }

        defer {
            isInitialized = true
        }

        mediaManager.initialize()
        mediaManager.v = v

        setupCollectionView()
        registerForLibraryChanges()
        panGestureHelper.registerForPanGesture(on: v)
        registerForTapOnPreview()
        refreshMediaRequest()

        v.assetViewContainer.multipleSelectionButton.isHidden = !(YPConfig.library.maxNumberOfItems > 1)
        v.maxNumberWarningLabel.text = String(format: YPConfig.wordings.warningMaxItemsLimit,
											  YPConfig.library.maxNumberOfItems)
        
        if let preselectedItems = YPConfig.library.preselectedItems,
           !preselectedItems.isEmpty {
            selectedItems = preselectedItems.compactMap { item -> YPLibrarySelection? in
                var itemAsset: PHAsset?
                switch item {
                case .photo(let photo):
                    itemAsset = photo.asset
                case .video(let video):
                    itemAsset = video.asset
                }
                guard let asset = itemAsset else {
                    return nil
                }
                
                // The negative index will be corrected in the collectionView:cellForItemAt:
                return YPLibrarySelection(index: -1, assetIdentifier: asset.localIdentifier)
            }
            v.assetViewContainer.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
            v.collectionView.reloadData()
        }

        guard mediaManager.hasResultItems else {
            return
        }

        if YPConfig.library.defaultMultipleSelection || selectedItems.count > 1 {
            toggleMultipleSelection()
        }
    }

    func setAlbum(_ album: YPAlbum) {
        title = album.title
        mediaManager.collection = album.collection
        currentlySelectedIndex = 0
        if !isMultipleSelectionEnabled {
            selectedItems.removeAll()
        }
        refreshMediaRequest()
    }

    // MARK: - View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // When crop area changes in multiple selection mode,
        // we need to update the scrollView values in order to restore
        // them when user selects a previously selected item.
        v.assetZoomableView.cropAreaDidChange = { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.updateCropInfo()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        v.assetViewContainer.squareCropButton
            .addTarget(self,
                       action: #selector(squareCropButtonTapped),
                       for: .touchUpInside)
        v.assetViewContainer.multipleSelectionButton
            .addTarget(self,
                       action: #selector(multipleSelectionButtonTapped),
                       for: .touchUpInside)
        
        // Forces assetZoomableView to have a contentSize.
        // otherwise 0 in first selection triggering the bug : "invalid image size 0x0"
        // Also fits the first element to the square if the onlySquareFromLibrary = true
        if !YPConfig.library.onlySquare && v.assetZoomableView.contentSize == CGSize(width: 0, height: 0) {
            v.assetZoomableView.setZoomScale(1, animated: false)
        }
        
        // Activate multiple selection when using `minNumberOfItems`
        if YPConfig.library.minNumberOfItems > 1 {
            multipleSelectionButtonTapped()
        }
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
        doAfterLibraryPermissionCheck { [weak self] in
            self?.v.assetViewContainer.squareCropButtonTapped()
        }
    }
    
    // MARK: - Multiple Selection

    @objc
    func multipleSelectionButtonTapped() {
        // If no items, than preventing multiple selection
        guard mediaManager.hasResultItems else {
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            }

            return
        }

        doAfterLibraryPermissionCheck { [weak self] in
            if self?.isMultipleSelectionEnabled == false {
                self?.selectedItems.removeAll()
            }
            self?.toggleMultipleSelection()
        }
    }
    
    func toggleMultipleSelection() {
        // Prevent desactivating multiple selection when using `minNumberOfItems`
        if YPConfig.library.minNumberOfItems > 1 && isMultipleSelectionEnabled {
            print("Selected minNumberOfItems greater than one :\(YPConfig.library.minNumberOfItems). Don't deselecting multiple selection.")
            return
        }

        isMultipleSelectionEnabled.toggle()

        if isMultipleSelectionEnabled {
            let needPreselectItemsAndNotSelectedAnyYet = selectedItems.isEmpty && YPConfig.library.preSelectItemOnMultipleSelection
            let shouldSelectByDelegate = delegate?.libraryViewShouldAddToSelection(indexPath: IndexPath(row: currentlySelectedIndex, section: 0), numSelections: selectedItems.count) ?? true
            if needPreselectItemsAndNotSelectedAnyYet,
               shouldSelectByDelegate,
               let asset = mediaManager.getAsset(at: currentlySelectedIndex) {
                selectedItems = [
                    YPLibrarySelection(index: currentlySelectedIndex,
                                       cropRect: v.currentCropRect(),
                                       scrollViewContentOffset: v.assetZoomableView.contentOffset,
                                       scrollViewZoomScale: v.assetZoomableView.zoomScale,
                                       assetIdentifier: asset.localIdentifier)
                ]
            }
        } else {
            selectedItems.removeAll()
            addToSelection(indexPath: IndexPath(row: currentlySelectedIndex, section: 0))
        }
        
        v.assetViewContainer.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
        v.collectionView.reloadData()
        checkLimit()
        delegate?.libraryViewDidToggleMultipleSelection(enabled: isMultipleSelectionEnabled)
    }
    
    // MARK: - Tap Preview
    
    func registerForTapOnPreview() {
        let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        v.assetViewContainer.addGestureRecognizer(tapImageGesture)
    }
    
    @objc
    func tappedImage() {
        if !panGestureHelper.isImageShown {
            panGestureHelper.resetToOriginalState()
            // no dragup? needed? dragDirection = .up
            v.refreshImageCurtainAlpha()
        }
    }
    
    func refreshMediaRequest() {
        let options = buildPHFetchOptions()

        if let collection = mediaManager.collection {
            mediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            mediaManager.fetchResult = PHAsset.fetchAssets(with: options)
        }
        
        if mediaManager.hasResultItems,
        let firstAsset = mediaManager.getAsset(at: 0) {
            changeAsset(firstAsset)
            v.collectionView.reloadData()
            v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                        animated: false,
                                        scrollPosition: UICollectionView.ScrollPosition())
            if !isMultipleSelectionEnabled && YPConfig.library.preSelectItemOnMultipleSelection {
                addToSelection(indexPath: IndexPath(row: 0, section: 0))
            }
        } else {
            delegate?.libraryViewHaveNoItems()
        }

        scrollToTop()
    }
    
    func buildPHFetchOptions() -> PHFetchOptions {
        // Sorting condition
        if let userOpt = YPConfig.library.options {
            return userOpt
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = YPConfig.library.mediaType.predicate()
        return options
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
    
    func changeAsset(_ asset: PHAsset?) {
        guard let asset = asset else {
            print("No asset to change.")
            return
        }

        delegate?.libraryViewStartedLoadingImage()
        
        let completion = { (isLowResIntermediaryImage: Bool) in
            self.v.hideOverlayView()
            self.v.assetViewContainer.updateSquareCropButtonState()
            self.updateCropInfo()
            if !isLowResIntermediaryImage {
                self.v.hideLoader()
                self.delegate?.libraryViewFinishedLoading()
            }
        }
        
        let updateCropInfo = {
            self.updateCropInfo()
        }
		
        // MARK: add a func(updateCropInfo) after crop multiple
        DispatchQueue.global(qos: .userInitiated).async {
            switch asset.mediaType {
            case .image:
                self.v.assetZoomableView.setImage(asset,
                                                  mediaManager: self.mediaManager,
                                                  storedCropPosition: self.fetchStoredCrop(),
                                                  completion: completion,
                                                  updateCropInfo: updateCropInfo)
            case .video:
                self.v.assetZoomableView.setVideo(asset,
                                                  mediaManager: self.mediaManager,
                                                  storedCropPosition: self.fetchStoredCrop(),
                                                  completion: { completion(false) },
                                                  updateCropInfo: updateCropInfo)
            case .audio, .unknown:
                ()
            @unknown default:
                ypLog("Bug. Unknown default.")
            }
        }
    }

    // MARK: - Verification
    
    private func fitsVideoLengthLimits(asset: PHAsset) -> Bool {
        guard asset.mediaType == .video else {
            return true
        }
        
        let tooLong = floor(asset.duration) > YPConfig.video.libraryTimeLimit
        let tooShort = floor(asset.duration) < YPConfig.video.minimumTimeLimit
        
        if tooLong || tooShort {
            DispatchQueue.main.async {
                let alert = tooLong ? YPAlert.videoTooLongAlert(self.view) : YPAlert.videoTooShortAlert(self.view)
                self.present(alert, animated: true, completion: nil)
            }
            return false
        }
        
        return true
    }
    
    // MARK: - Stored Crop Position
    
    internal func updateCropInfo(shouldUpdateOnlyIfNil: Bool = false) {
        guard let selectedAssetIndex = selectedItems.firstIndex(where: { $0.index == currentlySelectedIndex }) else {
            return
        }
        
        if shouldUpdateOnlyIfNil && selectedItems[selectedAssetIndex].scrollViewContentOffset != nil {
            return
        }
        
        // Fill new values
        var selectedAsset = selectedItems[selectedAssetIndex]
        selectedAsset.scrollViewContentOffset = v.assetZoomableView.contentOffset
        selectedAsset.scrollViewZoomScale = v.assetZoomableView.zoomScale
        selectedAsset.cropRect = v.currentCropRect()
        
        // Replace
        selectedItems.remove(at: selectedAssetIndex)
        selectedItems.insert(selectedAsset, at: selectedAssetIndex)
    }
    
    internal func fetchStoredCrop() -> YPLibrarySelection? {
        if self.isMultipleSelectionEnabled,
            self.selectedItems.contains(where: { $0.index == self.currentlySelectedIndex }) {
            guard let selectedAssetIndex = self.selectedItems
                .firstIndex(where: { $0.index == self.currentlySelectedIndex }) else {
                return nil
            }
            return self.selectedItems[selectedAssetIndex]
        }
        return nil
    }
    
    internal func hasStoredCrop(index: Int) -> Bool {
        return self.selectedItems.contains(where: { $0.index == index })
    }
    
    // MARK: - Fetching Media
    
    private func fetchImageAndCrop(for asset: PHAsset,
                                   withCropRect: CGRect? = nil,
                                   callback: @escaping (_ photo: UIImage, _ exif: [String: Any]) -> Void) {
        delegate?.libraryViewDidTapNext()
        let cropRect = withCropRect ?? DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: cropRect)
        mediaManager.imageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }
    
    private func fetchVideoAndApplySettings(for asset: PHAsset,
                                            withCropRect rect: CGRect? = nil,
                                            callback: @escaping (_ videoURL: URL?) -> Void) {
        let normalizedCropRect = rect ?? DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: normalizedCropRect)
        let xCrop: CGFloat = normalizedCropRect.origin.x * CGFloat(asset.pixelWidth)
        let yCrop: CGFloat = normalizedCropRect.origin.y * CGFloat(asset.pixelHeight)
        let resultCropRect = CGRect(x: xCrop,
                                    y: yCrop,
                                    width: ts.width,
                                    height: ts.height)
        
        guard fitsVideoLengthLimits(asset: asset) else {
            return
        }
        
        if YPConfig.video.automaticTrimToTrimmerMaxDuration {
            fetchVideoAndCropWithDuration(for: asset,
                                          withCropRect: resultCropRect,
                                          duration: YPConfig.video.trimmerMaxDuration,
                                          callback: callback)
        } else {
            delegate?.libraryViewDidTapNext()
            mediaManager.fetchVideoUrlAndCrop(for: asset, cropRect: resultCropRect, callback: callback)
        }
    }
    
    private func fetchVideoAndCropWithDuration(for asset: PHAsset,
                                               withCropRect rect: CGRect,
                                               duration: Double,
                                               callback: @escaping (_ videoURL: URL?) -> Void) {
        delegate?.libraryViewDidTapNext()
        let timeDuration = CMTimeMakeWithSeconds(duration, preferredTimescale: 1000)
        mediaManager.fetchVideoUrlAndCropWithDuration(for: asset,
                                                      cropRect: rect,
                                                      duration: timeDuration,
                                                      callback: callback)
    }
    
    public func selectedMedia(photoCallback: @escaping (_ photo: YPMediaPhoto) -> Void,
                              videoCallback: @escaping (_ videoURL: YPMediaVideo) -> Void,
                              multipleItemsCallback: @escaping (_ items: [YPMediaItem]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            let selectedAssets: [(asset: PHAsset, cropRect: CGRect?)] = self.selectedItems.compactMap {
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [$0.assetIdentifier],
                                                      options: PHFetchOptions()).firstObject else {
                    ypLog("Error!")
                    return nil
                }
                return (asset, $0.cropRect)
            }
            
            // Multiple selection
            if self.isMultipleSelectionEnabled && self.selectedItems.count > 1 {
                
                // Check video length
                for asset in selectedAssets {
                    if self.fitsVideoLengthLimits(asset: asset.asset) == false {
                        return
                    }
                }
                
                // Fill result media items array
                var resultMediaItems: [YPMediaItem] = []
                let asyncGroup = DispatchGroup()
                
                var assetDictionary: [PHAsset?: Int] = .init()
                for (index, assetPair) in selectedAssets.enumerated() {
                    assetDictionary[assetPair.asset] = index
                }
                
                for asset in selectedAssets {
                    asyncGroup.enter()
                    
                    switch asset.asset.mediaType {
                    case .image:
                        self.fetchImageAndCrop(for: asset.asset, withCropRect: asset.cropRect) { image, exifMeta in
                            let photo = YPMediaPhoto(image: image.resizedImageIfNeeded(),
													 exifMeta: exifMeta, asset: asset.asset)
                            resultMediaItems.append(YPMediaItem.photo(p: photo))
                            asyncGroup.leave()
                        }
                        
                    case .video:
                        self.fetchVideoAndApplySettings(for: asset.asset,
                                                             withCropRect: asset.cropRect) { videoURL in
                            if let videoURL = videoURL {
                                let videoItem = YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                                             videoURL: videoURL, asset: asset.asset)
                                resultMediaItems.append(YPMediaItem.video(v: videoItem))
                            } else {
                                ypLog("Problems with fetching videoURL.")
                            }
                            asyncGroup.leave()
                        }
                    default:
                        break
                    }
                }
                
                asyncGroup.notify(queue: .main) {
                    // TODO: sort the array based on the initial order of the assets in selectedAssets
                    resultMediaItems.sort { (first, second) -> Bool in
                        var firstAsset: PHAsset?
                        var secondAsset: PHAsset?
                        
                        switch first {
                        case .photo(let photo):
                            firstAsset = photo.asset
                        case .video(let video):
                            firstAsset = video.asset
                        }
                        guard let firstIndex = assetDictionary[firstAsset] else {
                            return false
                        }
                        
                        switch second {
                        case .photo(let photo):
                            secondAsset = photo.asset
                        case .video(let video):
                            secondAsset = video.asset
                        }
                        
                        guard let secondIndex = assetDictionary[secondAsset] else {
                            return false
                        }
                        
                        return firstIndex < secondIndex
                    }
                    multipleItemsCallback(resultMediaItems)
                    self.delegate?.libraryViewFinishedLoading()
                }
            } else {
                let asset = selectedAssets.first!.asset
                switch asset.mediaType {
                case .audio, .unknown:
                    return
                case .video:
                    self.fetchVideoAndApplySettings(for: asset, callback: { videoURL in
                        DispatchQueue.main.async {
                            if let videoURL = videoURL {
                                self.delegate?.libraryViewFinishedLoading()
                                let video = YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                                         videoURL: videoURL, asset: asset)
                                videoCallback(video)
                            } else {
                                ypLog("Problems with fetching videoURL.")
                            }
                        }
                    })
                case .image:
                    self.fetchImageAndCrop(for: asset) { image, exifMeta in
                        DispatchQueue.main.async {
                            self.delegate?.libraryViewFinishedLoading()
                            let photo = YPMediaPhoto(image: image.resizedImageIfNeeded(),
                                                     exifMeta: exifMeta,
                                                     asset: asset)
                            photoCallback(photo)
                        }
                    }
                @unknown default:
                    ypLog("unknown default reached. Check code.")
                }
                return
            }
        }
    }
    
    // MARK: - TargetSize
    
    private func targetSize(for asset: PHAsset, cropRect: CGRect) -> CGSize {
        var width = (CGFloat(asset.pixelWidth) * cropRect.width).rounded(.toNearestOrEven)
        var height = (CGFloat(asset.pixelHeight) * cropRect.height).rounded(.toNearestOrEven)
        // round to lowest even number
        width = (width.truncatingRemainder(dividingBy: 2) == 0) ? width : width - 1
        height = (height.truncatingRemainder(dividingBy: 2) == 0) ? height : height - 1
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Player
    
    func pausePlayer() {
        v.assetZoomableView.videoView.pause()
    }
    
    // MARK: - Deinit
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        ypLog("\(type(of: self)) deinited 👌🏻")
    }
}
