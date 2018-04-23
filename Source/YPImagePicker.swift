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
    
    private let loadingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.8)
        return view
    }()
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.hidesWhenStopped = true
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()
    
    private let processingTitleLabel: UILabel = {
        let frame = CGRect(x: 0, y: 0, width: 200, height: 20)
        let label = UILabel(frame: frame)
        label.textColor = .white
        return label
    }()
    
    private func setupActivityIndicator() {
        self.view.addSubview(loadingContainerView)
        loadingContainerView.alpha = 0
        loadingContainerView.frame = self.view.bounds
        
        loadingContainerView.addSubview(processingTitleLabel)
        let labelWidth: CGFloat = 200.0
        let labelHeight: CGFloat = 20.0
        let offset: CGFloat = 40.0
        let frame = CGRect(x: (loadingContainerView.frame.width/2) - offset,
                           y: (loadingContainerView.frame.height/2) + offset,
                           width: labelWidth,
                           height: labelHeight)
        processingTitleLabel.frame = frame
        processingTitleLabel.text = YPImagePickerConfiguration.shared.wordings.processing
        
        loadingContainerView.addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: loadingContainerView.centerYAnchor).isActive = true
    }
    
    private func setupNavigationBar() {
        navigationBar.isTranslucent = false
        YPHelpers.changeBackButtonIcon(self)
    }
    
    func showHideActivityIndicator() {
        
        if !activityIndicatorView.isAnimating {
            activityIndicatorView.startAnimating()
            loadingContainerView.alpha = 1
        } else {
            activityIndicatorView.stopAnimating()
            loadingContainerView.alpha = 0
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        picker.didClose = {
            YPImagePickerConfiguration.shared.delegate?.imagePickerDidCancel(self)
        }
        viewControllers = [picker]
        setupActivityIndicator()
        setupNavigationBar()
        
        picker.didSelectImage = { [unowned self] pickedImage, isNewPhoto in
            if YPImagePickerConfiguration.shared.showsFilters {
                let filterVC = YPFiltersVC(image: pickedImage, configuration: YPImagePickerConfiguration.shared)
                filterVC.didSelectImage = { filteredImage, isImageFiltered in
                    
                    let completion = { (image: UIImage) in
                        let mediaItem = YPMediaItem.photo(p: YPPhoto(image: image))
                        YPImagePickerConfiguration.shared.delegate?.imagePicker(self, didSelect: [mediaItem])
                        
                        if (isNewPhoto || isImageFiltered) && YPImagePickerConfiguration.shared.shouldSaveNewPicturesToAlbum {
                            YPPhotoSaver.trySaveImage(filteredImage, inAlbumNamed: YPImagePickerConfiguration.shared.albumName)
                        }
                    }
                    
                    if case let YPCropType.rectangle(ratio) = YPImagePickerConfiguration.shared.showsCrop {
                        let cropVC = YPCropVC(configuration: YPImagePickerConfiguration.shared, image: filteredImage, ratio: ratio)
                        cropVC.didFinishCropping = { croppedImage in
                            completion(croppedImage)
                        }
                        self.pushViewController(cropVC, animated: true)
                    } else {
                        completion(filteredImage)
                    }
                }
                
                // Use Fade transition instead of default push animation
                let transition = CATransition()
                transition.duration = 0.3
                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                transition.type = kCATransitionFade
                self.view.layer.add(transition, forKey: nil)
                
                self.pushViewController(filterVC, animated: false)
            } else {
                let completion = { (image: UIImage) in
                    let mediaItem = YPMediaItem.photo(p: YPPhoto(image: image))
                    YPImagePickerConfiguration.shared.delegate?.imagePicker(self, didSelect: [mediaItem])
                    
                    if isNewPhoto && YPImagePickerConfiguration.shared.shouldSaveNewPicturesToAlbum {
                        YPPhotoSaver.trySaveImage(pickedImage, inAlbumNamed: YPImagePickerConfiguration.shared.albumName)
                    }
                }
                if case let YPCropType.rectangle(ratio) = YPImagePickerConfiguration.shared.showsCrop {
                    let cropVC = YPCropVC(configuration: YPImagePickerConfiguration.shared, image: pickedImage, ratio: ratio)
                    cropVC.didFinishCropping = { croppedImage in
                        completion(croppedImage)
                    }
                    self.pushViewController(cropVC, animated: true)
                } else {
                    completion(pickedImage)
                }
            }
        }
        
        picker.didSelectVideo = { [unowned self] videoURL in
            createVideoItem(videoURL: videoURL,
                            activityIdicatorClosure: { _ in
                                self.showHideActivityIndicator()
            },
                            configuration: YPImagePickerConfiguration.shared,
                            completion: { video in
                                let mediaItem = YPMediaItem.video(v: video)
                                YPImagePickerConfiguration.shared.delegate?.imagePicker(self, didSelect: [mediaItem])
            })
        }
        
        picker.didSelectMultipleItems = { items in
            let selectionsGalleryVC = YPSelectionsGalleryVC.initWith(items: items,
                                                                     imagePicker: self)
            self.pushViewController(selectionsGalleryVC, animated: true)
        }
    }
}

