//
//  SelectionsGalleryVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

public class YPSelectionsGalleryVC: UIViewController {
    
    public var items: [YPMediaItem] = []
    public var didFinishHandler: ((_ gallery: YPSelectionsGalleryVC, _ items: [YPMediaItem]) -> Void)?
    private var lastContentOffsetX: CGFloat = 0
    
    var v = YPSelectionsGalleryView()
    public override func loadView() { view = v }

    public required init(items: [YPMediaItem],
                         didFinishHandler:
        @escaping ((_ gallery: YPSelectionsGalleryVC, _ items: [YPMediaItem]) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.items = items
        self.didFinishHandler = didFinishHandler
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Register collection view cell
        v.collectionView.register(YPSelectionsGalleryCell.self, forCellWithReuseIdentifier: "item")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        
        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(done))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
    }

    @objc
    private func done() {
        // Save new images to the photo album.
        if YPConfig.shouldSaveNewPicturesToAlbum {
            for m in items {
                if case let .photo(p) = m, let modifiedImage = p.modifiedImage {
                    YPPhotoSaver.trySaveImage(modifiedImage, inAlbumNamed: YPConfig.albumName)
                }
            }
        }
        didFinishHandler?(self, items)
    }
}

// MARK: - Collection View
extension YPSelectionsGalleryVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item",
                                                            for: indexPath) as? YPSelectionsGalleryCell else {
            return UICollectionViewCell()
        }
        let item = items[indexPath.row]
        switch item {
        case .photo(let photo):
            cell.imageView.image = photo.image
        case .video(let video):
            cell.imageView.image = video.thumbnail
        }
        return cell
    }
}

extension YPSelectionsGalleryVC: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        var mediaFilterVC: IsMediaFilterVC?
        switch item {
        case .photo(let photo):
            if !YPConfig.filters.isEmpty {
                mediaFilterVC = YPPhotoFiltersVC(inputPhoto: photo, isFromSelectionVC: true)
            }
        case .video(let video):
            mediaFilterVC = YPVideoFiltersVC.initWith(video: video, isFromSelectionVC: true)
        }
        
        mediaFilterVC?.didSave = { outputMedia in
            self.items[indexPath.row] = outputMedia
            collectionView.reloadData()
            self.dismiss(animated: true, completion: nil)
        }
        mediaFilterVC?.didCancel = {
            self.dismiss(animated: true, completion: nil)
        }
        if let mediaFilterVC = mediaFilterVC as? UIViewController {
            let navVC = UINavigationController(rootViewController: mediaFilterVC)
            navVC.navigationBar.isTranslucent = false
            present(navVC, animated: true, completion: nil)
        }
    }
    
    // Set "paging" behaviour when scrolling backwards.
    // This works by having `targetContentOffset(forProposedContentOffset: withScrollingVelocity` overriden
    // in the collection view Flow subclass & using UIScrollViewDecelerationRateFast
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isScrollingBackwards = scrollView.contentOffset.x < lastContentOffsetX
        scrollView.decelerationRate = isScrollingBackwards
            ? UIScrollView.DecelerationRate.fast
            : UIScrollView.DecelerationRate.normal
        lastContentOffsetX = scrollView.contentOffset.x
    }
}
