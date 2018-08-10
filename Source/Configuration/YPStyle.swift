//
//  YPStyle.swift
//  YPImagePicker
//
//  Created by Wellington Moreno on 08/09/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit


public struct YPStyle {

    public init() { }
    
    public var navBarIsTranslucent: Bool = false
    /// Solid background color of the navigation bar itself
    public var navBarBackgroundColor: UIColor = .white
    /// Tint color of items contained within the navigation bar
    public var navBarTintColor: UIColor = .black
    /// The font of the title in the navigation bar
    public var navBarTitleFont: UIFont = .systemFont(ofSize: 21, weight: .bold)
    /// The color of the title in the navigation bar
    public var navBarTitleColor: UIColor = .black
    /// Helps define the color of the status bar
    public var navBarStyle: UIBarStyle = .default

    /// The color of the 'Next' button located on the right navigation bar item
    public var nextButtonColor: UIColor = YPColors().tintColor
    /// The background color of the currently selected photo, from within the Gallery
    public var selectedPhotoBackgroundColor: UIColor = .white
    /// The background color of the photos presented from the gallery view
    public var photoCollectionBackgroundColor: UIColor = .white

    /// The background color of the pager items on the bottom of the YPImagePicker
    public var bottomPagerBackgroundColor: UIColor = .clear
    /// The font of the text on the bottom pager
    public var bottomPagerTextFont: UIFont = .systemFont(ofSize: 16)
    /// The color of the text for the currently active tab
    public var bottomPagerTextSelectedColor: UIColor = .black
    /// The color of the text for any unselected tabs
    public var bottomPagerTextUnselectedColor: UIColor = .lightGray

    /// The color of any progress spinners that appear
    public var progressSpinnerTintColor: UIColor = .black

}
