//
//  Array+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 06.01.2022.
//  Copyright © 2022 Yummypets. All rights reserved.
//

internal extension Array {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
