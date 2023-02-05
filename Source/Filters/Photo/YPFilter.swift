//
//  YPFilter.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import UIKit
import CoreImage

public typealias FilterApplierType = ((_ image: CIImage) -> CIImage?)

public struct YPFilter {
    var name = ""
    var applier: FilterApplierType?
    
    public init(name: String, coreImageFilterName: String) {
        self.name = name
        self.applier = YPFilter.coreImageFilter(name: coreImageFilterName)
    }
    
    public init(name: String, applier: FilterApplierType?) {
        self.name = name
        self.applier = applier
    }
}

extension YPFilter {
    public static func coreImageFilter(name: String) -> FilterApplierType {
        return { (image: CIImage) -> CIImage? in
            let filter = CIFilter(name: name)
            filter?.setValue(image, forKey: kCIInputImageKey)
            return filter?.outputImage!
        }
    }
    
    public static func clarendonFilter(foregroundImage: CIImage) -> CIImage? {
        let backgroundImage = getColorImage(red: 127, green: 187, blue: 227, alpha: Int(255 * 0.2),
											rect: foregroundImage.extent)
        return foregroundImage.applyingFilter("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": backgroundImage
            ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.35,
                "inputBrightness": 0.05,
                "inputContrast": 1.1
                ])
    }
    
    public static func nashvilleFilter(foregroundImage: CIImage) -> CIImage? {
        let backgroundImage = getColorImage(red: 247, green: 176, blue: 153, alpha: Int(255 * 0.56),
											rect: foregroundImage.extent)
        let backgroundImage2 = getColorImage(red: 0, green: 70, blue: 150, alpha: Int(255 * 0.4),
											 rect: foregroundImage.extent)
        return foregroundImage
            .applyingFilter("CIDarkenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage
                ])
            .applyingFilter("CISepiaTone", parameters: [
                "inputIntensity": 0.2
                ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.2,
                "inputBrightness": 0.05,
                "inputContrast": 1.1
                ])
            .applyingFilter("CILightenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage2
                ])
    }
    
    public static func apply1977Filter(ciImage: CIImage) -> CIImage? {
        let filterImage = getColorImage(red: 243, green: 106, blue: 188, alpha: Int(255 * 0.1), rect: ciImage.extent)
        let backgroundImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.3,
                "inputBrightness": 0.1,
                "inputContrast": 1.05
                ])
            .applyingFilter("CIHueAdjust", parameters: [
                "inputAngle": 0.3
                ])
        return filterImage
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage
                ])
            .applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.20),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.80),
                "inputPoint4": CIVector(x: 1, y: 1)
                ])
    }
    
    public static func toasterFilter(ciImage: CIImage) -> CIImage? {
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        let centerWidth = width / 2.0
        let centerHeight = height / 2.0
        let radius0 = min(width / 4.0, height / 4.0)
        let radius1 = min(width / 1.5, height / 1.5)
        
        let color0 = self.getColor(red: 128, green: 78, blue: 15, alpha: 255)
        let color1 = self.getColor(red: 79, green: 0, blue: 79, alpha: 255)
        let circle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: centerWidth, y: centerHeight),
            "inputRadius0": radius0,
            "inputRadius1": radius1,
            "inputColor0": color0,
            "inputColor1": color1
            ])?.outputImage?.cropped(to: ciImage.extent)
        
        return ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.0,
                "inputBrightness": 0.01,
                "inputContrast": 1.1
                ])
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": circle!
                ])
    }
    
    private static func getColor(red: Int, green: Int, blue: Int, alpha: Int = 255) -> CIColor {
        return CIColor(red: CGFloat(Double(red) / 255.0),
                       green: CGFloat(Double(green) / 255.0),
                       blue: CGFloat(Double(blue) / 255.0),
                       alpha: CGFloat(Double(alpha) / 255.0))
    }
    
    private static func getColorImage(red: Int, green: Int, blue: Int, alpha: Int = 255, rect: CGRect) -> CIImage {
        let color = self.getColor(red: red, green: green, blue: blue, alpha: alpha)
        return CIImage(color: color).cropped(to: rect)
    }
}
