//
//  CGFloat+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 16.05.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

infix operator &/

// With that you can devide to zero
extension CGFloat {
    public static func &/ (lhs: CGFloat, rhs: CGFloat) -> CGFloat {
        if rhs == 0 {
            return 0
        }
        return lhs/rhs
    }
}
