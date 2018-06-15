//
//  SelectionsGalleryVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

// TODO: Add paging to collection view

public class YPSelectionsGalleryVC: UIViewController {
    @IBOutlet weak var collectionV: UICollectionView!

    public var items: [YPMediaItem] = []
    public var didFinishHandler: ((_ gallery: YPSelectionsGalleryVC, _ items: [YPMediaItem]) -> Void)?

    /// Designated initializer
    public class func initWith(items: [YPMediaItem],
                               didFinishHandler:
        @escaping ((_ gallery: YPSelectionsGalleryVC, _ items: [YPMediaItem]) -> Void)) -> YPSelectionsGalleryVC {
        let vc = YPSelectionsGalleryVC(nibName: "YPSelectionsGalleryVC",
                                       bundle: Bundle(for: YPSelectionsGalleryVC.self))
        vc.items = items
        vc.didFinishHandler = didFinishHandler
        return vc
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Register collection view cell
        let bundle = Bundle(for: YPSelectionsGalleryVC.self)
        collectionV.register(UINib(nibName: "YPSelectionsGalleryCVCell",
                                   bundle: bundle), forCellWithReuseIdentifier: "item")
        
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
                                                            for: indexPath) as? YPSelectionsGalleryCVCell else {
            return UICollectionViewCell()
        }
        let item = items[indexPath.row]
        switch item {
        case .photo(let photo):
            cell.imageV.image = photo.image
        case .video(let video):
            cell.imageV.image = video.thumbnail
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
}

extension YPSelectionsGalleryVC: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sideSize = collectionView.frame.size.height - 30
        return CGSize(width: sideSize, height: sideSize)
    }
}
