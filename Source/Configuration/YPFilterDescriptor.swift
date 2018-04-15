//
//  YPFilterDescriptor.swift
//  YPImagePicker
//
//  Created by Emil Atanasov on 14.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation

public class YPFilterDescriptor {
    let name:String
    let filterName:String
    
    public init(name: String, filterName: String ) {
        self.name = name
        self.filterName = filterName
    }
}
