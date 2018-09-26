//
//  UIImage+ResetOrientation.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 20/02/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

internal extension UIImage {
    
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Kudos to Trevor Harmon and his UIImage+Resize category from
    // which this code is heavily inspired.
    func resetOrientation() -> UIImage {
        
        // Image has no orientation, so keep the same
        if imageOrientation == .up {
            return self
        }
        
        // Process the transform corresponding to the current orientation
        var transform = CGAffineTransform.identity
        switch imageOrientation {
        case .down, .downMirrored:           // EXIF = 3, 4
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            
        case .left, .leftMirrored:           // EXIF = 6, 5
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            
        case .right, .rightMirrored:          // EXIF = 8, 7
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat((Double.pi / 2)))
        default:
            ()
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:     // EXIF = 2, 4
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:   //EXIF = 5, 7
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            ()
        }
        
        // Draw a new image with the calculated transform
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: cgImage!.bitsPerComponent,
                                bytesPerRow: 0,
                                space: cgImage!.colorSpace!,
                                bitmapInfo: cgImage!.bitmapInfo.rawValue)
        context?.concatenate(transform)
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        if let newImageRef =  context?.makeImage() {
            let newImage = UIImage(cgImage: newImageRef)
            return newImage
        }
        
        // In case things go wrong, still return self.
        return self
    }
    
    // Reduce image size further if needed targetImageSize is capped.
    func resizedImageIfNeeded() -> UIImage {
        if case let YPImageSize.cappedTo(size: capped) = YPConfig.targetImageSize {
            let size = cappedSize(for: self.size, cappedAt: capped)
            if let resizedImage = self.resized(to: size) {
                return resizedImage
            }
        }
        return self
    }
    
    fileprivate func cappedSize(for size: CGSize, cappedAt: CGFloat) -> CGSize {
        var cappedWidth: CGFloat = 0
        var cappedHeight: CGFloat = 0
        if size.width > size.height {
            // Landscape
            let heightRatio = size.height / size.width
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = cappedWidth * heightRatio
        } else if size.height > size.width {
            // Portrait
            let widthRatio = size.width / size.height
            cappedHeight = min(size.height, cappedAt)
            cappedWidth = cappedHeight * widthRatio
        } else {
            // Squared
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = min(size.height, cappedAt)
        }
        return CGSize(width: cappedWidth, height: cappedHeight)
    }
    
    func toCIImage() -> CIImage? {
        return self.ciImage ?? CIImage(cgImage: self.cgImage!)
    }
}
