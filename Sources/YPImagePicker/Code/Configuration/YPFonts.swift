//
//  YPFonts.swift
//  YPImagePicker
//
//  Created by Sebastiaan Seegers on 28/02/2020.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit

public struct YPFonts {

    /// The font used in the picker title
    public var pickerTitleFont: UIFont = .boldSystemFont(ofSize: 17)

    /// The font used in the warning label of the LibraryView
    public var libaryWarningFont: UIFont = UIFont(name: "Helvetica Neue", size: 14)!

    /// The font used to show the duration in the LibraryViewCell
    public var durationFont: UIFont = .systemFont(ofSize: 12)

    public var multipleSelectionIndicatorFont: UIFont = .systemFont(ofSize: 12, weight: .regular)

    public var albumCellTitleFont: UIFont = .systemFont(ofSize: 16, weight: .regular)

    public var albumCellNumberOfItemsFont: UIFont = .systemFont(ofSize: 12, weight: .regular)

    public var menuItemFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)

    public var filterNameFont: UIFont = .systemFont(ofSize: 11, weight: .regular)
    public var filterSelectionSelectedFont: UIFont = .systemFont(ofSize: 11, weight: .semibold)
    public var filterSelectionUnSelectedFont: UIFont = .systemFont(ofSize: 11, weight: .regular)

    public var cameraTimeElapsedFont: UIFont = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)

    public var navigationBarTitleFont: UIFont = .boldSystemFont(ofSize: 17)

    /// The font used in the UINavigationBar rightBarButtonItem
    public var rightBarButtonFont: UIFont?

    /// The font used in the UINavigationBar leftBarButtonItem
    public var leftBarButtonFont: UIFont?
}
