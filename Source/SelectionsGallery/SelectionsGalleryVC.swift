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
        let vc = SelectionsGalleryVC()
        vc.items = items
        return vc
    }

    @IBOutlet private weak var collectionV: UICollectionView!

    public var items: [YPMediaItem] = [] { didSet { collectionV.reloadData() } }

    override public func viewDidLoad() {
        super.viewDidLoad()

        collectionV.register(UINib(nibName: "SelectionsGalleryCVCell", bundle: nil), forCellWithReuseIdentifier: "item")
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
            cell.imageV.image = item.image?.image
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
