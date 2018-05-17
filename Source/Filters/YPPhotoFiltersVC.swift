//
//  YPPhotoFiltersVC.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import UIKit

protocol IsMediaFilterVC: class {
    var didSave: ((YPMediaItem) -> Void)? { get set }
    var didCancel: (() -> Void)? { get set }
}

open class YPPhotoFiltersVC: UIViewController, IsMediaFilterVC, UIGestureRecognizerDelegate {
    
    override open var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    
    var v = YPFiltersView()
    
    var filterPreviews = [YPFilterPreview]()
    var filters = [YPFilter]()
    var selectedFilter: YPFilter?
    
    var inputPhoto: YPMediaPhoto!
    var filteredImage: UIImage?
    var thumbImage = UIImage()
    
    private var isFromSelectionVC = false
    
    var didSave: ((YPMediaItem) -> Void)?
    var didCancel: (() -> Void)?
    
    override open func loadView() { view = v }
    
    required public init(inputPhoto: YPMediaPhoto, isFromSelectionVC: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.inputPhoto = inputPhoto
        self.isFromSelectionVC = isFromSelectionVC
        
        for filterDescriptor in YPConfig.filters {
            filterPreviews.append(YPFilterPreview(filterDescriptor.name))
            filters.append(YPFilter(filterDescriptor.filterName))
        }
    }
    
    func thumbFromImage(_ img: UIImage) -> UIImage {
        let k = img.size.height / 160 // 160 is a height of the collection view
        let width: CGFloat = img.size.width / k
        let height: CGFloat = img.size.height / k
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
        thumbImage = thumbFromImage(inputPhoto.originalImage)
        v.collectionView.register(YPFilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                                  animated: false,
                                                  scrollPosition: UICollectionViewScrollPosition.bottom)
        
        // Navigation bar setup
        title = YPConfig.wordings.filter
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(cancel))
        }
        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.done : YPConfig.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
        
        // Touch preview to see original image.
        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        touchDownGR.delegate = self
        v.imageView.addGestureRecognizer(touchDownGR)
        v.imageView.isUserInteractionEnabled = true
    }
    
    @objc
    private func handleTouchDown(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            v.imageView.image = inputPhoto.originalImage
        case .ended:
            v.imageView.image = filteredImage ?? inputPhoto.originalImage
        default: ()
        }
    }
    
    @objc
    func cancel() {
        didCancel?()
    }
    
    @objc
    func save() {
        if selectedFilter != nil {
            inputPhoto.modifiedImage = filteredImage
        }
        didSave?(YPMediaItem.photo(p: inputPhoto))
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
    // TODO: If the image is very big (>3 mb) than the filtering spent much time. In instagram it's instant.
    // I think the make big previews instantly.
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilter = filters[indexPath.row]
        DispatchQueue.global(qos: .userInitiated).async {
            self.filteredImage = self.selectedFilter?.filter(self.inputPhoto.originalImage)
            DispatchQueue.main.async {
                self.v.imageView.image = self.filteredImage
            }
        }
    }
}
