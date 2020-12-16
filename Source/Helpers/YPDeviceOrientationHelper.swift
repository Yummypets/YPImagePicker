//
//  YPDeviceOrientationHelper.swift
//  YPImagePicker
//
//  Created by Kf on 2019/7/22.
//  Copyright © 2019 Yummypets. All rights reserved.
//

import UIKit
import CoreMotion

// Reference: https://medium.com/@PabloDomine/developing-camille-how-to-determine
// -device-orientation-in-a-camera-app-4c622d251993
class YPDeviceOrientationHelper {
	// Singleton is recommended because an app should create only a single instance of the CMMotionManager class.
    static let shared = YPDeviceOrientationHelper()
    
    private let motionManager: CMMotionManager
    private let queue: OperationQueue
    
    typealias DeviceOrientationHandler = ((_ deviceOrientation: UIDeviceOrientation) -> Void)?
    private var deviceOrientationAction: DeviceOrientationHandler?
    
    public var currentDeviceOrientation: UIDeviceOrientation = .portrait

	// Smallers values makes it much sensitive to detect an orientation change. [0 to 1]
    private let motionLimit: Double = 0.6
    
    init() {
        motionManager = CMMotionManager()
		// Specify an update interval in seconds, personally found this value provides a good UX
        motionManager.accelerometerUpdateInterval = 0.2
        
        queue = OperationQueue()
    }
    
    public func startDeviceOrientationNotifier(with handler: DeviceOrientationHandler) {
        self.deviceOrientationAction = handler
        
        //  Using main queue is not recommended.
		// So create new operation queue and pass it to startAccelerometerUpdatesToQueue.
        //  Dispatch U/I code to main thread using dispach_async in the handler.
        
        motionManager.startAccelerometerUpdates(to: queue) { (data, _) in
            if let accelerometerData = data {
                var newDeviceOrientation: UIDeviceOrientation?
                
                if accelerometerData.acceleration.x >= self.motionLimit {
                    newDeviceOrientation = .landscapeRight
                } else if accelerometerData.acceleration.x <= -self.motionLimit {
                    newDeviceOrientation = .landscapeLeft
                } else if accelerometerData.acceleration.y <= -self.motionLimit {
                    newDeviceOrientation = .portrait
                } else if accelerometerData.acceleration.y >= self.motionLimit {
                    newDeviceOrientation = .portraitUpsideDown
                } else {
                    return
                }
                
                // Only if a different orientation is detect, execute handler
                if let newDeviceOrientation = newDeviceOrientation,
					newDeviceOrientation != self.currentDeviceOrientation {
                    self.currentDeviceOrientation = newDeviceOrientation
                    if let deviceOrientationHandler = self.deviceOrientationAction {
                        DispatchQueue.main.async {
                            deviceOrientationHandler!(self.currentDeviceOrientation)
                        }
                    }
                }
            }
        }
    }
    
    public func stopDeviceOrientationNotifier() {
        motionManager.stopAccelerometerUpdates()
    }
}
