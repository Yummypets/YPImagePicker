//
//  YPLibraryVC.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Photos

@objc
public protocol YPLibraryViewDelegate: class {
    func libraryViewCameraRollUnauthorized()
    func libraryViewStartedLoadingImage()
    func libraryViewFinishedLoadingImage()
}

public class YPLibraryVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, PermissionCheckable {
    
    private let configuration: YPImagePickerConfiguration!
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        title = ypLocalized("YPImagePickerLibrary")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate: YPLibraryViewDelegate?
    
    private var fetchResult: PHFetchResult<PHAsset>!
    
    var imageManager: PHCachingImageManager?
    var previousPreheatRect: CGRect = CGRect.zero
    let cellSize = CGSize(width: UIScreen.main.bounds.width/4 * UIScreen.main.scale,
                          height: UIScreen.main.bounds.width/4 * UIScreen.main.scale)
    var phAsset: PHAsset!
    
    // Variables for calculating the position
    enum Direction {
        case scroll
        case stop
        case up
        case down
    }
    let imageCropViewOriginalConstraintTop: CGFloat = 0
    let imageCropViewMinimalVisibleHeight: CGFloat  = 50
    var dragDirection = Direction.up
    var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    
    var cropBottomY: CGFloat  = 0.0
    var dragStartPos: CGPoint = CGPoint.zero
    let dragDiff: CGFloat     = 0//20.0

    var _isImageShown = true
    var isImageShown: Bool {
        get { return self._isImageShown }
        set {
            if newValue != isImageShown {
                self._isImageShown = newValue
                v.imageCropViewContainer.isShown = newValue
                
                //Update imageCropContainer
                if isImageShown {
                    v.imageCropView.isScrollEnabled = true
                } else {
                   v.imageCropView.isScrollEnabled = false
                }
            }
        }
    }

    var v: YPLibraryView!
    
    public override func loadView() {
        let bundle = Bundle(for: self.classForCoder)
        let xibView = UINib(nibName: "YPLibraryView",
                            bundle: bundle).instantiate(withOwner: self,
                                                        options: nil)[0] as? YPLibraryView
        v = xibView
        view = v
    }
    
    var initialized = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForPlayerReachedEndNotifications()
        v.imageCropViewContainer.squareCropButton
            .addTarget(self,
                       action: #selector(squareCropButtonTapped),
                       for: .touchUpInside)
        
    }
    
    @objc
    func squareCropButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.v.imageCropViewContainer.squareCropButtonTapped()
        }
    }
    
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
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func initialize() {
        imageManager = PHCachingImageManager()
        
        if fetchResult != nil {
            return
        }
        
        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        panGesture.delegate = self
        v.addGestureRecognizer(panGesture)
        
        v.imageCropViewConstraintTop.constant = 0
        dragDirection = Direction.up
        
        v.imageCropViewContainer.layer.shadowColor   = UIColor.black.cgColor
        v.imageCropViewContainer.layer.shadowRadius  = 30.0
        v.imageCropViewContainer.layer.shadowOpacity = 0.9
        v.imageCropViewContainer.layer.shadowOffset  = CGSize.zero
        
        v.collectionView.register(YPLibraryViewCell.self, forCellWithReuseIdentifier: "YPLibraryViewCell")
        
        refreshMediaRequest()

        let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        v.imageCropViewContainer.addGestureRecognizer(tapImageGesture)
        
        v.imageCropViewContainer.onlySquareImages = configuration.onlySquareImagesFromLibrary
        v.imageCropView.onlySquareImages = configuration.onlySquareImagesFromLibrary
    }
    
    var collection: PHAssetCollection?
    
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
    
    @objc
    func tappedImage() {
        if !isImageShown {
            v.imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
            UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.v.layoutIfNeeded()
            }, completion: nil)
            refreshImageCurtainAlpha()
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
                                  otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(ofTouch: 0, in: v)
        // Desactivate pan on image when it is shown.
        if isImageShown {
            if p.y < v.imageCropView.frame.height {
                return false
            }
        }
        return true
    }
    
    @objc
    func panned(_ sender: UIPanGestureRecognizer) {
        
        let containerHeight = v.imageCropViewContainer.frame.height
        if sender.state == UIGestureRecognizerState.began {
            let view    = sender.view
            let loc     = sender.location(in: view)
            let subview = view?.hitTest(loc, with: nil)
            
            if subview == v.imageCropView
                && v.imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop {
                return
            }
            
            dragStartPos = sender.location(in: v)
            cropBottomY = v.imageCropViewContainer.frame.origin.y + containerHeight
            
            // Move
            if dragDirection == Direction.stop {
                dragDirection = (v.imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop)
                    ? Direction.up
                    : Direction.down
            }
            
            // Scroll event of CollectionView is preferred.
            if (dragDirection == Direction.up && dragStartPos.y < cropBottomY + dragDiff) ||
                (dragDirection == Direction.down && dragStartPos.y > cropBottomY) {
                dragDirection = Direction.stop
            }
        } else if sender.state == UIGestureRecognizerState.changed {
            let currentPos = sender.location(in: v)
            if dragDirection == Direction.up && currentPos.y < cropBottomY - dragDiff {
                v.imageCropViewConstraintTop.constant =
                    max(imageCropViewMinimalVisibleHeight - containerHeight, currentPos.y + dragDiff - containerHeight)
            } else if dragDirection == Direction.down && currentPos.y > cropBottomY {
                v.imageCropViewConstraintTop.constant =
                    min(imageCropViewOriginalConstraintTop, currentPos.y - containerHeight)
            } else if dragDirection == Direction.stop && v.collectionView.contentOffset.y < 0 {
                dragDirection = Direction.scroll
                imaginaryCollectionViewOffsetStartPosY = currentPos.y
            } else if dragDirection == Direction.scroll {
                v.imageCropViewConstraintTop.constant =
                    imageCropViewMinimalVisibleHeight - containerHeight
                    + currentPos.y - imaginaryCollectionViewOffsetStartPosY
            }
        } else {
            imaginaryCollectionViewOffsetStartPosY = 0.0
            if sender.state == UIGestureRecognizerState.ended && dragDirection == Direction.stop {
                return
            }
            let currentPos = sender.location(in: v)
            if currentPos.y < cropBottomY - dragDiff
                && v.imageCropViewConstraintTop.constant != imageCropViewOriginalConstraintTop {
                // The largest movement
                v.imageCropViewConstraintTop.constant =
                    imageCropViewMinimalVisibleHeight - containerHeight
                UIView.animate(withDuration: 0.3,
                               delay: 0.0,
                               options: UIViewAnimationOptions.curveEaseOut,
                               animations: {
                    self.v.layoutIfNeeded()
                    }, completion: nil)
                dragDirection = Direction.down
            } else {
                // Get back to the original position
                v.imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
                UIView.animate(withDuration: 0.3,
                               delay: 0.0,
                               options: UIViewAnimationOptions.curveEaseOut,
                               animations: {
                    self.v.layoutIfNeeded()
                    }, completion: nil)
                dragDirection = Direction.up
            }
        }
        
        // Update isImageShown
        isImageShown = v.imageCropViewConstraintTop.constant == 0

        refreshImageCurtainAlpha()
    }
    
    func refreshImageCurtainAlpha() {
        let imageCurtainAlpha = abs(v.imageCropViewConstraintTop.constant)
            / (v.imageCropViewContainer.frame.height - imageCropViewMinimalVisibleHeight)
        v.imageCropViewContainer.curtain.alpha = imageCurtainAlpha
    }
    
    // MARK: - UICollectionViewDelegate Protocol
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YPLibraryViewCell",
                                                         for: indexPath) as? YPLibraryViewCell else {
            fatalError("unexpected cell in collection view")
        }
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager?.requestImage(for: asset,
                                  targetSize: cellSize,
                                  contentMode: .aspectFill,
                                  options: nil) { image, _ in
            // The cell may have been recycled when the time this gets called
            // set image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                cell.imageView.image = image
            }
        }
        
        let isVideo = (asset.mediaType == .video)
        cell.durationLabel.isHidden = !isVideo
        cell.durationLabel.text = isVideo ? formattedStrigFrom(asset.duration) : ""
        
        // Prevent weird animation where thumbnail fills cell on first scrolls.
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }
        return cell
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
    
    var previouslySelectedIndex: Int?
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == previouslySelectedIndex {
            return
        }
        changeImage(fetchResult[indexPath.row])
        v.imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.v.layoutIfNeeded()
            }, completion: nil)
        dragDirection = Direction.up
        collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        refreshImageCurtainAlpha()
        
        previouslySelectedIndex = indexPath.row
    }
    
    // MARK: - ScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == v.collectionView {
            updateCachedAssets()
        }
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            let collectionChanges = changeInstance.changeDetails(for: self.fetchResult)
            if collectionChanges != nil {
                self.fetchResult = collectionChanges!.fetchResultAfterChanges
                let collectionView = self.v.collectionView!
                if !collectionChanges!.hasIncrementalChanges || collectionChanges!.hasMoves {
                    collectionView.reloadData()
                } else {
                    collectionView.performBatchUpdates({
                        let removedIndexes = collectionChanges!.removedIndexes
                        if (removedIndexes?.count ?? 0) != 0 {
                            collectionView.deleteItems(at: removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let insertedIndexes = collectionChanges!.insertedIndexes
                        if (insertedIndexes?.count ?? 0) != 0 {
                            collectionView
                                .insertItems(at: insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let changedIndexes = collectionChanges!.changedIndexes
                        if (changedIndexes?.count ?? 0) != 0 {
                            collectionView.reloadItems(at: changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                    }, completion: nil)
                }
                self.resetCachedAssets()
            }
        }
    }
    
    var latestImageTapped = ""

    func changeImage(_ asset: PHAsset) {
        phAsset = asset
        latestImageTapped = asset.localIdentifier
        v.imageCropViewContainer.isVideoMode = asset.mediaType == .video
        
        v.imageCropViewContainer.playerLayer.player?.pause()
        v.imageCropViewContainer.playerLayer.isHidden = true
        
        switch asset.mediaType {
        case .image:
            DispatchQueue.global(qos: .default).async {
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                self.imageManager?.requestImage(for: asset,
                                               targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                                               contentMode: .aspectFill,
                                               options: options) { result, info in
                                                // Prevent long images to come after user selected
                                                // another in the meantime.
                                                if self.latestImageTapped == asset.localIdentifier {
                                                    DispatchQueue.main.async {
                                                        
                                                        if let isFromCloud = info?[PHImageResultIsDegradedKey] as? Bool,
                                                            isFromCloud == true {
                                                            self.v.imageCropViewContainer.spinnerView.alpha = 1
                                                        } else {
                                                            UIView.animate(withDuration: 0.2) {
                                                                self.v.imageCropViewContainer.spinnerView.alpha = 0
                                                            }
                                                        }
                                                    
                                                        self.v.imageCropView.imageSize = CGSize(
                                                            width: asset.pixelWidth,
                                                            height: asset.pixelHeight)
                                                        self.v.imageCropView.image = result
                                                        
                                                        if self.configuration.onlySquareImagesFromLibrary {
                                                            self.v.imageCropView.setFitImage(true)
                                                            self.v.imageCropView.minimumZoomScale =
                                                                self.v.imageCropView.squaredZoomScale
                                                        }
                                                        self.v.imageCropViewContainer.refreshSquareCropButton()
                                                    }
                                                }
                }
        }
        case .video:
            
            DispatchQueue.main.async {
                self.v.imageCropViewContainer.grid.alpha = 0
                self.v.imageCropViewContainer.spinnerView.alpha = 1
                self.v.imageCropViewContainer.refreshSquareCropButton()
            }
            
            DispatchQueue.global(qos: .default).async {
                
                // Load video image preview.
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .opportunistic
                let screenWidth = UIScreen.main.bounds.width
                self.imageManager?.requestImage(for: asset,
                                               targetSize: CGSize(width: screenWidth, height: screenWidth),
                                               contentMode: .aspectFill,
                                               options: options) { result, _ in
                                                // Prevent long images to come after user selected
                                                // another in the meantime.
                                                if self.latestImageTapped == asset.localIdentifier {
                                                    DispatchQueue.main.async {
                                                        self.v.imageCropView.image = result
                                                        self.v.imageCropViewContainer.cropView?
                                                            .setFitImage(true, animated: false)
                                                    }
                                                }
                }
                
                // Play video
                let videosOptions = PHVideoRequestOptions()
                videosOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
                videosOptions.isNetworkAccessAllowed = true
                self.imageManager?.requestPlayerItem(forVideo: asset,
                                                           options: videosOptions,
                                                           resultHandler: { playerItem, _ in
                    // Prevent long videos to come after user selected another in the meantime.
                    if self.latestImageTapped == asset.localIdentifier {
                        DispatchQueue.main.async {
                            let player = AVPlayer(playerItem: playerItem)
                            self.v.imageCropViewContainer.playerLayer.player = player
                            self.v.imageCropViewContainer.playerLayer.isHidden = false
                            self.v.imageCropViewContainer.spinnerView.alpha = 0
                            player.play()
                        }
                    }
                })
            }
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
            
            computeDifferenceBetweenRect(previousPreheatRect,
                                              andRect: preheatRect,
                                              removedHandler: { removedRect in
                let indexPaths = self.v.collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
                }, addedHandler: {addedRect in
                    let indexPaths = self.v.collectionView.aapl_indexPathsForElementsInRect(addedRect)
                    addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths)
            
            imageManager?.startCachingImages(for: assetsToStartCaching,
                                                  targetSize: cellSize,
                                                  contentMode: .aspectFill,
                                                  options: nil)
            imageManager?.stopCachingImages(for: assetsToStopCaching,
                                                 targetSize: cellSize,
                                                 contentMode: .aspectFill,
                                                 options: nil)
            
            previousPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(_ oldRect: CGRect,
                                      andRect newRect: CGRect,
                                      removedHandler: (CGRect) -> Void,
                                      addedHandler: (CGRect) -> Void) {
        if newRect.intersects(oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x,
                                       y: oldMaxY,
                                       width: newRect.size.width,
                                       height: (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x,
                                       y: newMinY,
                                       width: newRect.size.width,
                                       height: (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: newRect.origin.x,
                                          y: newMaxY,
                                          width: newRect.size.width,
                                          height: (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRect(x: newRect.origin.x,
                                          y: oldMinY,
                                          width: newRect.size.width,
                                          height: (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 { return [] }
        
        var assets: [PHAsset] = []
        assets.reserveCapacity(indexPaths.count)
        for indexPath in indexPaths {
                let asset = fetchResult[indexPath.item]
                assets.append(asset)
        }
        return assets
    }
    
    public func selectedMedia(photo:@escaping (_ photo: UIImage) -> Void,
                              video: @escaping (_ videoURL: URL) -> Void) {
        
        // Get crop rect if cropped to square
        var cropRect = CGRect.zero
        if let cropView = v.imageCropView {
            let normalizedX = min(1, cropView.contentOffset.x / cropView.contentSize.width)
            let normalizedY = min(1, cropView.contentOffset.y / cropView.contentSize.height)
            let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
            let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
            cropRect = CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = self.phAsset!
            switch asset.mediaType {
            case .video:
                if asset.duration > self.configuration.videoFromLibraryTimeLimit {
                    
                    let msg = String(format: NSLocalizedString("YPImagePickerVideoTooLongDetail",
                                                tableName: nil,
                                                bundle: Bundle(for: YPPickerVC.self),
                                                value: "",
                                                comment: ""), "\(self.configuration.videoFromLibraryTimeLimit)")
                    
                    let alert = UIAlertController(title: ypLocalized("YPImagePickerVideoTooLongTitle"),
                                                  message: msg,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let videosOptions = PHVideoRequestOptions()
                    videosOptions.isNetworkAccessAllowed = true
                    self.delegate?.libraryViewStartedLoadingImage()
                    self.imageManager?.requestAVAsset(forVideo: asset,
                                                      options: videosOptions) { v, _, _ in
                                                        if let urlAsset = v as? AVURLAsset {
                                                            DispatchQueue.main.async {
                                                                self.delegate?.libraryViewFinishedLoadingImage()
                                                                video(urlAsset.url)
                                                            }
                                                        }
                    }
                }
            case .image:
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.normalizedCropRect = cropRect
                options.resizeMode = PHImageRequestOptionsResizeMode.exact
                options.isSynchronous = true // Ok since we're already in a Backgroudn thread
                
                let targetWidth = floor(CGFloat(self.phAsset.pixelWidth) * cropRect.width)
                let targetHeight = floor(CGFloat(self.phAsset.pixelHeight) * cropRect.height)
                var targetSize = CGSize.zero
                switch self.configuration.libraryTargetImageSize {
                case .original:
                    targetSize = CGSize(width: targetWidth, height: targetHeight)
                case .cappedTo(size: let capped):
                    // If image is smaller than limit, use original image size.
                    if targetWidth <= capped && targetHeight <= capped {
                        targetSize = CGSize(width: targetWidth, height: targetHeight)
                    } else {
                        targetSize = CGSize(width: capped, height: capped)
                    }
                }
                
                self.delegate?.libraryViewStartedLoadingImage()
                self.imageManager?
                    .requestImage(for: asset,
                                  targetSize: targetSize,
                                  contentMode: .aspectFit,
                                  options: options) { result, _ in
                                    DispatchQueue.main.async {
                                        self.delegate?.libraryViewFinishedLoadingImage()
                                        photo(result!)
                                    }
                }
            case .audio, .unknown:
                ()
            }
        }
    }
    
    private func registerForPlayerReachedEndNotifications() {
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerItemDidReachEnd(_:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: nil)
    }
    
    // MARK: Private
    
    var player: AVPlayer? {
        return v.imageCropViewContainer.playerLayer.player
    }
    
    @objc
    func playerItemDidReachEnd(_ note: Notification) {
        player?.actionAtItemEnd = .none
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        player.togglePlayPause()
    }
}

extension AVPlayer {
    func togglePlayPause() {
        if rate == 0 {
            play()
        } else {
            pause()
        }
    }
}

internal extension UICollectionView {
    
    func aapl_indexPathsForElementsInRect(_ rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)
        if (allLayoutAttributes?.count ?? 0) == 0 {return []}
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(allLayoutAttributes!.count)
        for layoutAttributes in allLayoutAttributes! {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        return indexPaths
    }
}

internal extension IndexSet {
    
    func aapl_indexPathsFromIndexesWithSection(_ section: Int) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(count)
        (self as NSIndexSet).enumerate({idx, _ in
            indexPaths.append(IndexPath(item: idx, section: section))
        })
        return indexPaths
    }
}
