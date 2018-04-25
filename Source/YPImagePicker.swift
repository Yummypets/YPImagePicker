//
//  YPImagePicker.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

public class YPImagePicker: UINavigationController {
    
    let loadingView = YPLoadingView()
    private let picker: YPPickerVC!
    
    /// Get a YPImagePicker instance with the default configuration.
    public convenience init() {
        self.init(configuration: YPImagePickerConfiguration.shared)
    }
    
    /// Get a YPImagePicker with the specified configuration.
    public required init(configuration: YPImagePickerConfiguration) {
        YPImagePickerConfiguration.shared = configuration
        picker = YPPickerVC(configuration: YPImagePickerConfiguration.shared)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNavigationBar() {
        navigationBar.isTranslucent = false
        YPHelper.changeBackButtonIcon(self)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        picker.didClose = {
            YPImagePickerConfiguration.shared.delegate?.imagePickerDidCancel(self)
        }
        viewControllers = [picker]
        setupLoadingView()
        setupNavigationBar()
        
        picker.didSelectItems = { [unowned self] items in
            let showsFilters = YPImagePickerConfiguration.shared.showsFilters
            
            // Use Fade transition instead of default push animation
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionFade
            self.view.layer.add(transition, forKey: nil)
            
            // Multiple items flow
            if items.count > 1 {
                let selectionsGalleryVC = YPSelectionsGalleryVC.initWith(items: items,
                                                                         imagePicker: self)
                self.pushViewController(selectionsGalleryVC, animated: true)
                return
            }
            
            // One item flow
            let item = items.first!
            
            switch item {
            case .photo(let photo):
                // TODO: Save new photo ?
                let completion = { (image: UIImage) in
                    let mediaItem = YPMediaItem.photo(p: YPPhoto(image: image))
                    YPImagePickerConfiguration.shared.delegate?.imagePicker(self, didSelect: [mediaItem])
                }
                
                func showCropVC(photo: YPPhoto, completion: @escaping (_ image: UIImage) -> Void) {
                    if case let YPCropType.rectangle(ratio) = YPImagePickerConfiguration.shared.showsCrop {
                        let cropVC = YPCropVC(image: photo.image, ratio: ratio)
                        cropVC.didFinishCropping = { croppedImage in
                            completion(croppedImage)
                        }
                        self.pushViewController(cropVC, animated: true)
                    } else {
                        completion(photo.image)
                    }
                }
                
                if showsFilters {
                    let filterVC = YPPhotoFiltersVC(inputPhoto: photo,
                                                    isFromSelectionVC: false)
                    // Show filters and then crop
                    filterVC.saveCallback = { outputPhoto in
                        showCropVC(photo: outputPhoto, completion: completion)
                    }
                    self.pushViewController(filterVC, animated: false)
                } else {
                    showCropVC(photo: photo, completion: completion)
                }
            case .video(let video):
                if showsFilters {
                    let videoFiltersVC = YPVideoFiltersVC.initWith(video: video,
                                                                   isFromSelectionVC: false)
                    videoFiltersVC.saveCallback = { [unowned self] outputVideo in
                        YPImagePickerConfiguration.shared.delegate?.imagePicker(self, didSelect: [YPMediaItem.video(v: outputVideo)])
                    }
                    self.pushViewController(videoFiltersVC, animated: true)
                } else {
                    YPImagePickerConfiguration.shared.delegate?.imagePicker(self, didSelect: [YPMediaItem.video(v: video)])
                }
            }
        }
    }
    
    private func setupLoadingView() {
        view.sv(
            loadingView
        )
        loadingView.fillContainer()
        loadingView.alpha = 0
    }
}

