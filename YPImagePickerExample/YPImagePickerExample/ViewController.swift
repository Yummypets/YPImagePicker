//
//  ViewController.swift
//  YPImagePickerExample
//
//  Created by Sacha DSO on 17/03/2017.
//  Copyright © 2017 Octopepper. All rights reserved.
//

import UIKit
import YPImagePicker

class ViewController: UIViewController {
    
    let imageView = UIImageView()
    
    let button = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.frame = view.frame
        
        button.setTitle("Pick", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.addSubview(button)
        button.center = view.center
        button.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
    }
    
    func showPicker() {
        let picker = YPImagePicker()
//        picker.onlySquareImages = true
        // picker.showsFilters = false
        // picker.startsOnCameraMode = true
        // picker.usesFrontCamera = true
//        picker.showsVideo = true
        picker.didSelectImage = { img in
            // image picked
            self.imageView.image = img
            picker.dismiss(animated: true, completion: nil)
        }
        picker.didSelectVideo = { videoData in
            // video picked
        }
        present(picker, animated: true, completion: nil)
    }
}
