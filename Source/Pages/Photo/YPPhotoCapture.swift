//
//  YPPhotoCapture.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 08/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol YPPhotoCapture: class {
    
    // Public api
    func start(with previewView: UIView, completion: @escaping () -> Void)
    func stopCamera()
    func focus(on point: CGPoint)
    func tryToggleFlash()
    var hasFlash: Bool { get }
    var currentFlashMode: YPFlashMode { get }
    func flipCamera()
    func shoot(completion: @escaping (Data) -> Void)
    var videoLayer: AVCaptureVideoPreviewLayer! { get set }
    var device: AVCaptureDevice? { get }
    
    // Used by Default extension
    var previewView: UIView! { get set }
    var isCaptureSessionSetup: Bool { get set }
    var isPreviewSetup: Bool { get set }
    var sessionQueue: DispatchQueue { get }
    var session: AVCaptureSession { get }
    var output: AVCaptureOutput { get }
    var deviceInput: AVCaptureDeviceInput? { get set }
    func configure()
}

func newPhotoCapture() -> YPPhotoCapture {
    if #available(iOS 10.0, *) {
        return PostiOS10PhotoCapture()
    } else {
        return PreiOS10PhotoCapture()
    }
}

enum YPFlashMode {
    case off
    case on
    case auto
}

extension YPFlashMode {
    func flashImage() -> UIImage {
        switch self {
        case .on: return YPConfig.icons.flashOnIcon
        case .off: return YPConfig.icons.flashOffIcon
        case .auto: return YPConfig.icons.flashAutoIcon
        }
    }
}
