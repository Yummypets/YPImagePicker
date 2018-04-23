//
//  YPPhotoFiltersVC.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import UIKit

open class YPPhotoFiltersVC: UIViewController {
    
    override open var prefersStatusBarHidden: Bool { return YPImagePickerConfiguration.shared.hidesStatusBar }
    
    var v = YPFiltersView()
    
    var filterPreviews = [YPFilterPreview]()
    var filters = [YPFilter]()
    
    var inputPhoto: YPPhoto!
    var thumbImage = UIImage()
    
    var saveCallback: ((YPPhoto) -> Void)?
    var isImageFiltered = false
    public var isFromSelectionVC = false
    
    override open func loadView() { view = v }
    
    required public init(inputPhoto: YPPhoto, isFromSelectionVC: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.inputPhoto = inputPhoto
        self.isFromSelectionVC = isFromSelectionVC
        title = YPImagePickerConfiguration.shared.wordings.filter
        
        for filterDescriptor in YPImagePickerConfiguration.shared.filters {
            filterPreviews.append(YPFilterPreview(filterDescriptor.name))
            filters.append(YPFilter(filterDescriptor.filterName))
        }
    }
    
    func thumbFromImage(_ img: UIImage) -> UIImage {
        let width: CGFloat = img.size.width / 5
        let height: CGFloat = img.size.height / 5
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        img.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return smallImage!
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        v.imageView.image = inputPhoto.image
        thumbImage = thumbFromImage(inputPhoto.image)
        v.collectionView.register(YPFilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                                  animated: false,
                                                  scrollPosition: UICollectionViewScrollPosition.bottom)
        
        // Navigation bar setup
        navigationController?.navigationBar.tintColor = YPImagePickerConfiguration.shared.colors.pickerNavigationBarTextColor
        let rightBarButtonTitle = isFromSelectionVC ? YPImagePickerConfiguration.shared.wordings.save : YPImagePickerConfiguration.shared.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
    }
    
    @objc func save() {
        let outputImage = v.imageView.image!

        if isImageFiltered && YPImagePickerConfiguration.shared.shouldSaveNewPicturesToAlbum {
            YPPhotoSaver.trySaveImage(outputImage, inAlbumNamed: YPImagePickerConfiguration.shared.albumName)
        }
        
        saveCallback?(YPPhoto(image: v.imageView.image!))
    }
}

extension YPPhotoFiltersVC: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterPreviews.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filterPreview = filterPreviews[indexPath.row]
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell",
                                                         for: indexPath) as? YPFilterCollectionViewCell {
            cell.name.text = filterPreview.name
            if let img = filterPreview.image {
                cell.imageView.image = img
            } else {
                let filter = self.filters[indexPath.row]
                let filteredImage = filter.filter(self.thumbImage)
                cell.imageView.image = filteredImage
                filterPreview.image = filteredImage // Cache
            }
            return cell
        }
        return UICollectionViewCell()
    }
}

extension YPPhotoFiltersVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedFilter = filters[indexPath.row]
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            let filteredImage = selectedFilter.filter(self.inputPhoto.image)
            DispatchQueue.main.async {
                self.v.imageView.image = filteredImage
            }
        }
        
        self.isImageFiltered = selectedFilter.name != ""
    }
}
