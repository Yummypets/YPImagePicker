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
        /*
			If need to reduce the process time, than use next code.
			But ot produce a bug with wrong filling in the simulator.
			return UIImage(ciImage: self)
         */
        let context: CIContext = CIContext.init(options: nil)
        let cgImage: CGImage = context.createCGImage(self, from: self.extent)!
        let image: UIImage = UIImage(cgImage: cgImage)
        return image
    }
    
    func toCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        return nil
    }
}
