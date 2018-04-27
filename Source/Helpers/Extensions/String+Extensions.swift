//
//  String+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 27.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation

extension Thread {
    class func printCurrent() {
        print("\r⚡️: \(Thread.current)\r" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")\r")
    }
}
