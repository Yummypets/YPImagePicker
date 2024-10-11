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

public final class YPLibraryVC: UIViewController, YPPermissionCheckable {
    public weak var delegate: YPLibraryViewDelegate?
    internal var v = YPLibraryView(frame: .zero)
    public var isProcessing = false // true if video or image is in processing state
    public var selectedItems = [YPLibrarySelection]()
    public let mediaManager = LibraryMediaManager()
    public var isMultipleSelectionEnabled = YPConfig.library.isBulkUploading
    public var currentlySelectedIndex: Int = 0
    internal let panGestureHelper = PanGestureHelper()
    internal var isInitialized = false
    var disableAutomaticCellSelection = false

    public var isAnimating: Bool {
        v.assetZoomableView.isAnimating
    }

    // MARK: - Init

    public override func loadView() {
        view = v
    }

    internal required init() {
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

        v.multipleSelectionButton.isHidden = YPConfig.library.isBulkUploading || !(YPConfig.library.maxNumberOfItems > 1)
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
            let image = isMultipleSelectionEnabled ? YPConfig.icons.multipleSelectionOnIcon : YPConfig.icons.multipleSelectionOffIcon
            v.multipleSelectionButton.setImage(image, for: .normal)
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
        disableAutomaticCellSelection = isMultipleSelectionEnabled
        if YPConfig.showsLibraryButtonInTitle {
            title = album.title
        } else {
            v.setAlbumButtonTitle(aTitle: album.title)
        }
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

        v.onAlbumsButtonTap = { [weak self] in
            self?.delegate?.libraryViewDidTapAlbum()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        v.assetViewContainer.squareCropButton
            .addTarget(self,
                       action: #selector(squareCropButtonTapped),
                       for: .touchUpInside)
        v.multipleSelectionButton
            .addTarget(self,
                       action: #selector(multipleSelectionButtonTapped),
                       for: .touchUpInside)

        v.bulkUploadRemoveAllButton.addTarget(self,
                                              action: #selector(bulkUploadRemoveAllButtonTapped),
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

    // MARK: - Bulk Upload Selection

    @objc
    func bulkUploadRemoveAllButtonTapped() {
        self.selectedItems.removeAll()
        v.collectionView.reloadData()
        updateBulkUploadRemoveAllButton()
        delegate?.libraryViewFinishedLoading()
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
        if (YPConfig.library.minNumberOfItems > 1 && isMultipleSelectionEnabled) {
            ypLog("Selected minNumberOfItems greater than one :\(YPConfig.library.minNumberOfItems). Don't deselecting multiple selection.")
            return
        }

        isMultipleSelectionEnabled.toggle()

        if isMultipleSelectionEnabled {
            let needPreselectItemsAndNotSelectedAnyYet = selectedItems.isEmpty && YPConfig.library.preSelectItemOnMultipleSelection
            let shouldSelectByDelegate = delegate?.libraryViewShouldAddToSelection(indexPath: IndexPath(row: currentlySelectedIndex, section: 0), numSelections: selectedItems.count) ?? true
            if needPreselectItemsAndNotSelectedAnyYet,
               shouldSelectByDelegate,
               let asset = mediaManager.getAsset(at: currentlySelectedIndex) {

                if !YPImagePickerConfiguration.shared.library.allowPhotoAndVideoSelection,
                   asset.mediaType == .video,
                   case (let image?, let index?) = mediaManager.getFirstImageAsset()
                {
                    currentlySelectedIndex = index
                    changeAsset(image)
                }
                addToSelection(indexPath: IndexPath(row: currentlySelectedIndex, section: 0))
            }
        } else {
            selectedItems.removeAll()
            addToSelection(indexPath: IndexPath(row: currentlySelectedIndex, section: 0))
        }
        
        v.assetViewContainer.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
        let image = isMultipleSelectionEnabled ? YPConfig.icons.multipleSelectionOnIcon : YPConfig.icons.multipleSelectionOffIcon
        v.multipleSelectionButton.setImage(image, for: .normal)
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
    public func tappedImage() {
        if !panGestureHelper.isImageShown {
            panGestureHelper.resetToOriginalState()
            // no dragup? needed? dragDirection = .up
            v.refreshImageCurtainAlpha()
        }
    }
    
    func refreshMediaRequest() {
        let options = buildPHFetchOptions()

        if
            YPConfig.library.shouldPreselectRecentsAlbum,
            let allMediaAlbum = fetchAllMedia() {

            if mediaManager.collection == nil {
                mediaManager.fetchResult = PHAsset.fetchAssets(in: allMediaAlbum, options: nil)
            } else if let _ = mediaManager.collection, mediaManager.isSelectedCollectionRecentsAlbum() {
                mediaManager.fetchResult = PHAsset.fetchAssets(in: allMediaAlbum, options: nil)
            } else if let collection = mediaManager.collection {
                // In this path the selected collection could be any album that is not "Recents" Therefore just fetch the media
                // in those albums.
                mediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
            }
        } else {
            if let collection = mediaManager.collection {
                mediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
            } else {
                mediaManager.fetchResult = PHAsset.fetchAssets(with: options)
            }
        }

        if mediaManager.hasResultItems,
        let firstAsset = mediaManager.getAsset(with: selectedItems.last?.assetIdentifier) ?? mediaManager.getAsset(at: 0) {
            changeAsset(firstAsset)
            v.collectionView.reloadData()

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
            ypLog("No asset to change.")
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
                                                  customSize: self.getFirstSelectedItemSize(),
                                                  completion: completion,
                                                  updateCropInfo: updateCropInfo)
            case .video:
                self.v.assetZoomableView.setVideo(asset,
                                                  mediaManager: self.mediaManager,
                                                  storedCropPosition: self.fetchStoredCrop(),
                                                  customSize: self.getFirstSelectedItemSize(),
                                                  completion: { completion(false) },
                                                  updateCropInfo: updateCropInfo)
            case .audio, .unknown:
                ()
            @unknown default:
                ypLog("Bug. Unknown default.")
            }
        }
    }

    private func getFirstSelectedItemSize() -> CGSize? {
        guard isMultipleSelectionEnabled,
              let firstSelectedItem = selectedItems.first,
              let cropRect = firstSelectedItem.cropRect,
              let selectedAsset = mediaManager.getAsset(at: firstSelectedItem.index)
        else { return nil }

        let width = firstSelectedItem.isAspectRatioOutOfRange ? CGFloat(selectedAsset.pixelWidth) * cropRect.width : CGFloat(selectedAsset.pixelWidth)
        let height = firstSelectedItem.isAspectRatioOutOfRange ? CGFloat(selectedAsset.pixelHeight) * cropRect.height : CGFloat(selectedAsset.pixelHeight)

        return CGSize(width: width, height: height)
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
        selectedAsset.isAspectRatioOutOfRange = v.assetZoomableView.isAspectRatioOutOfRange

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

    func fetchAllMedia() -> PHAssetCollection? {
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        return collections.firstObject
    }

    private func fetchImageAndCrop(for asset: PHAsset,
                                   withCropRect: CGRect? = nil,
                                   callback: @escaping (_ photo: UIImage, _ exif: [String: Any]) -> Void) {
        delegate?.libraryViewDidTapNext()
        let cropRect = withCropRect ?? DispatchQueue.main.sync { v.assetZoomableView.photoImageView.frame }
        let ts = targetSize(for: asset, cropRect: cropRect)
        mediaManager.imageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }

    private func fetchImage(for asset: PHAsset,
                                   callback: @escaping (_ photo: UIImage, _ exif: [String: Any]) -> Void) {
        delegate?.libraryViewDidTapNext()
        mediaManager.imageManager?.fetchImage(for: asset, callback: callback)
    }

    private func getCropRect(for asset:PHAsset, cropRect: CGRect? = nil) -> CGRect {
        let normalizedCropRect = cropRect ?? v.currentCropRect()
        let ts = targetSize(for: asset, cropRect: normalizedCropRect)
        let xCrop: CGFloat = normalizedCropRect.origin.x * CGFloat(asset.pixelWidth)
        let yCrop: CGFloat = normalizedCropRect.origin.y * CGFloat(asset.pixelHeight)
        let resultCropRect = CGRect(x: xCrop,
                                    y: yCrop,
                                    width: ts.width,
                                    height: ts.height)

        return resultCropRect
    }

    private func checkVideoLengthAndCrop(for asset: PHAsset,
                                         withCropRect: CGRect? = nil,
                                         result: @escaping (Result<ProcessedVideo, LibraryMediaManagerError>) -> Void) {
        if fitsVideoLengthLimits(asset: asset) == true {
            delegate?.libraryViewDidTapNext()
            let normalizedCropRect = withCropRect ?? DispatchQueue.main.sync { v.currentCropRect() }
            let ts = targetSize(for: asset, cropRect: normalizedCropRect)
            let xCrop: CGFloat = normalizedCropRect.origin.x * CGFloat(asset.pixelWidth)
            let yCrop: CGFloat = normalizedCropRect.origin.y * CGFloat(asset.pixelHeight)
            let resultCropRect = CGRect(x: xCrop,
                                        y: yCrop,
                                        width: ts.width,
                                        height: ts.height)
            if !YPImagePickerConfiguration.shared.library.allowPhotoAndVideoSelection {
                mediaManager.fetchVideoUrlAndCrop(for: asset, cropRect: resultCropRect, result: result)
            } else {
                mediaManager.fetchVideoUrl(for: asset, result: result)
            }
        }
    }

    private func checkVideoLengthAndFetch(for asset: PHAsset,
                                          result: @escaping (Result<ProcessedVideo, LibraryMediaManagerError>) -> Void) {
        if fitsVideoLengthLimits(asset: asset) == true {
            delegate?.libraryViewDidTapNext()
            mediaManager.fetchVideoUrl(for: asset, result: result)
        }
    }
    
    public func selectedMedia(photoCallback: @escaping (_ photo: YPMediaPhoto) -> Void,
                              videoCallback: @escaping (_ videoURL: YPMediaVideo) -> Void,
                              multipleItemsCallback: @escaping (_ items: [YPMediaItem]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            let selectedAssets: [(asset: PHAsset, cropRect: CGRect?)] = self.selectedItems.map {
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [$0.assetIdentifier], options: PHFetchOptions()).firstObject else { fatalError("local identifier incorrect: \($0.assetIdentifier)") }
                return (asset, $0.cropRect)
            }

            DispatchQueue.global(qos: .userInitiated).async {
                // Multiple selection
                if self.isMultipleSelectionEnabled && selectedAssets.count > 1 {

                    // Check video length
                    for asset in selectedAssets {
                        if self.fitsVideoLengthLimits(asset: asset.asset) == false {
                            return
                        }
                    }

                    // Fill result media items array
                    var resultMediaItems: [YPMediaItem?] = Array(repeating: nil, count: selectedAssets.count)
                    let asyncGroup = DispatchGroup()

                    for (index, asset) in selectedAssets.enumerated() {
                        asyncGroup.enter()

                        switch asset.asset.mediaType {
                        case .image:
                            self.fetchImage(for: asset.asset) { image, exifMeta in
                                let photo = YPMediaPhoto(image: image.resizedImageIfNeeded(), exifMeta: exifMeta, asset: asset.asset)
                                let cropRect = self.selectedItems[index].cropRect
                                photo.cropRect = self.getCropRect(for: asset.asset, cropRect: cropRect)
                                resultMediaItems[index] = YPMediaItem.photo(p: photo)
                                asyncGroup.leave()
                            }

                        case .video:
                            self.checkVideoLengthAndCrop(for: asset.asset, withCropRect: asset.cropRect) { result in
                                switch result {
                                case let .success(video):
                                    let videoItem = YPMediaVideo(thumbnail: thumbnailFromVideoPath(video.videoUrl),
                                                                 videoURL: video.videoUrl, asset: asset.asset)
                                    videoItem.cropRect = self.getCropRect(for: asset.asset, cropRect: self.selectedItems[index].cropRect)
                                    resultMediaItems[index] = YPMediaItem.video(v: videoItem)
                                case let .failure(error):
                                    ypLog("YPLibraryVC -> selectedMedia -> Problems with fetching videoURL.")
                                }
                                asyncGroup.leave()
                            }
                        default:
                            break
                        }
                    }

                    asyncGroup.notify(queue: .main) {
                        multipleItemsCallback(resultMediaItems.compactMap { $0 })
                        self.delegate?.libraryViewFinishedLoading()
                    }
                } else {
                    let asset = selectedAssets.first!.asset
                    switch asset.mediaType {
                    case .audio, .unknown:
                        return
                    case .video:
                        self.checkVideoLengthAndFetch(for: asset) { result in
                            DispatchQueue.main.async {
                                self.delegate?.libraryViewFinishedLoading() // reset UI regardless if a video url is returned
                                switch result {
                                case let .success(video):
                                    let video = YPMediaVideo(thumbnail: thumbnailFromVideoPath(video.videoUrl),
                                                             videoURL: video.videoUrl, asset: asset)
                                    video.cropRect = self.getCropRect(for: asset)
                                    videoCallback(video)
                                case let .failure(error):
                                    ypLog("YPLibraryVC -> selectedMedia -> Problems with fetching videoURL.")
                                }
                            }
                        }


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
                        fatalError()
                    }
                    return
                }
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
