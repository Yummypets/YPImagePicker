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
        
    }
    
    @IBAction func goToSettingsbuttonTapped() {
        delegate?.goToSettingsButtonTaped()
    }
}
