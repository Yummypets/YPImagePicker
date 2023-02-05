//
//  AVCaptureDevice+Extensions.swift
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Octopepper. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice {
    func tryToggleTorch() {
        guard hasFlash else {
            return
        }

        do {
            try lockForConfiguration()

            switch torchMode {
            case .auto:
                torchMode = .on
            case .on:
                torchMode = .off
            case .off:
                torchMode = .auto
            @unknown default:
                throw YPError.custom(message: "unknown default case")
            }

            unlockForConfiguration()
        } catch {
            ypLog("Error with torch \(error).")
        }
    }
}

internal extension AVCaptureDevice {
    class var audioCaptureDevice: AVCaptureDevice? {
        let availableMicrophoneAudioDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices
        return availableMicrophoneAudioDevices.first
    }

    /// Best available device for selected position.
    class func deviceForPosition(_ p: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devicesSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: p)
        let devices = devicesSession.devices
        guard !devices.isEmpty else {
            print("Don't have supported cameras for this position: \(p.rawValue)")
            return nil
        }

        return devices.first
    }
}
