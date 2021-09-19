//
//  YPError.swift
//  YPImagePicker
//
//  Created by Nik Kov on 13.08.2021.
//

import UIKit

enum YPError: Error, LocalizedError {
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .custom(let message):
            return message
        }
    }
}
