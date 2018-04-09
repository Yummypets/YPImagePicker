//
//  SelectionsGalleryVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

public class SelectionsGalleryVC: UIViewController {
    
    /// Designated initializer
    class func initWith(items: [YPMediaItem]) -> SelectionsGalleryVC {
        let vc = SelectionsGalleryVC(nibName: "SelectionsGalleryVC", bundle: Bundle(for: SelectionsGalleryVC.self))
        vc.items = items
        return vc
    }

    @IBOutlet weak var collectionV: UICollectionView!

    public var items: [YPMediaItem] = []

    override public func viewDidLoad() {
        super.viewDidLoad()

        let bundle = Bundle(for: SelectionsGalleryVC.self)
        collectionV.register(UINib(nibName: "SelectionsGalleryCVCell", bundle: bundle), forCellWithReuseIdentifier: "item")
    }

}

// MARK: - Collection View
extension SelectionsGalleryVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! SelectionsGalleryCVCell
        
        let item = items[indexPath.row]
        switch item.type {
        case .photo:
            cell.imageV.image = item.photo?.image
        case .video:
            cell.imageV.image = item.video?.thumbnail
        }
        
        return cell
    }
}

extension SelectionsGalleryVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let item = items[indexPath.row]

    }
}

extension SelectionsGalleryVC: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sideSize = collectionView.frame.size.height - 20
        return CGSize(width: sideSize, height: sideSize)
    }
}

