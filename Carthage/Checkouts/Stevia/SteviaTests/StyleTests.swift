//
//  StyleTests.swift
//  Stevia
//
//  Created by krzat on 17/03/16.
//  Copyright © 2016 Sacha Durand Saint Omer. All rights reserved.
//

import XCTest
import Stevia

class StyleTests: XCTestCase {

    func styleView(_ view: UIView) {
        view.backgroundColor = UIColor.yellow
    }
    
    func styleLabel(_ label: UILabel) {
        label.textColor = UIColor.yellow
    }

    func testStyle() {
        let label = UILabel()
        
        label.style(styleLabel).style(styleView)
        label.style(styleView).style(styleLabel)
        
        let view: UIView = label
        view.style(styleView)
        
        XCTAssertEqual(view.backgroundColor, UIColor.yellow)
        XCTAssertEqual(label.textColor, UIColor.yellow)
        
        //check type deduction
        label.style { (label) -> () in
            label.textColor = UIColor.blue
        }
        XCTAssertEqual(label.textColor, UIColor.blue)
    }


}
