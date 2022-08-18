//
//  RequestDeniedView.swift
//  YPImagePicker
//
//  Created by Görkem Gür on 18.08.2022.
//  Copyright © 2022 Yummypets. All rights reserved.
//

import Foundation
import UIKit

protocol RequestDeniedDelegate {
    func goToSettingsButtonTaped()
}

class RequestDeniedView: BaseView {
    
    @IBOutlet private weak var goToSettingsButton: UIButton!
    @IBOutlet private weak var emptyViewImage: UIImageView!
    @IBOutlet private weak var emptyViewDescriptionLabel: UILabel!
    
    var delegate: RequestDeniedDelegate?
    
    override func setup() {
        super.setup()
        setupFromNib()
        
        emptyViewImage.image = UIImage(systemName: "photo.on.rectangle.angled")
        emptyViewImage.tintColor = .black
        emptyViewDescriptionLabel.textColor = .black
        emptyViewDescriptionLabel.font = UIFont.systemFont(ofSize: 15)
        emptyViewDescriptionLabel.text = ypLocalized("YPLibraryViewRequestDeniedDescription")
        
        goToSettingsButton.setTitle(ypLocalized("YPLibraryViewRequestDeniedButtonText"), for: .normal)
        goToSettingsButton.tintColor = .blue
        goToSettingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        
        
    }
    
    @IBAction func goToSettingsbuttonTapped() {
        delegate?.goToSettingsButtonTaped()
    }
}
