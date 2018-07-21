//
//  CIImage+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 21.07.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

internal extension CIImage {
    func toUIImage() -> UIImage {
        return UIImage(ciImage: self)
    }
    
    func toCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        return nil
    }
}
