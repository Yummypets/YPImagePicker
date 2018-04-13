//
//  FillTests.swift
//  Stevia
//
//  Created by Naabed on 12/02/16.
//  Copyright © 2016 Sacha Durand Saint Omer. All rights reserved.
//

import XCTest

import Stevia

class FillTests: XCTestCase {
    var win: UIWindow!
    var ctrler: UIViewController!

    override func setUp() {
        super.setUp()
        win = UIWindow(frame: UIScreen.main.bounds)
        ctrler =  UIViewController()
        win.rootViewController = ctrler
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testFillContainer() {
        let b = UIButton()
        ctrler.view.sv(b)
        b.fillContainer()
        ctrler.view.layoutIfNeeded() // This is needed to force auto-layout to kick-in
        XCTAssertEqual(ctrler.view.frame, b.frame)
    }
    
    func testFillContainerWithPadding() {
        let padding: CGFloat = 10.0
        let b = UIButton()
        ctrler.view.sv(b)
        b.fillContainer(padding)
        ctrler.view.layoutIfNeeded() // This is needed to force auto-layout to kick-in
        XCTAssertEqual(ctrler.view.frame.height, b.frame.height + padding * 2,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(ctrler.view.frame.width, b.frame.width + padding * 2,
                                   accuracy: CGFloat(Float.ulpOfOne))
    }
}
