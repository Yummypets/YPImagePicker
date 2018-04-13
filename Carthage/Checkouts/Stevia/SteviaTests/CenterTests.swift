//
//  CenterTests.swift
//  Stevia
//
//  Created by Sacha Durand Saint Omer on 21/02/16.
//  Copyright © 2016 Sacha Durand Saint Omer. All rights reserved.
//

import XCTest

class CenterTests: XCTestCase {
    
    var win: UIWindow!
    var ctrler: UIViewController!
    var v: UIView!
    
    override func setUp() {
        super.setUp()
        win = UIWindow(frame: UIScreen.main.bounds)
        ctrler =  UIViewController()
        win.rootViewController = ctrler
        v = UIView()
        ctrler.view.sv(v)
        verifyViewHasDefaultValues()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCenterHorizontally() {
        v.size(100)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
        v.centerHorizontally()
        ctrler.view.setNeedsLayout()
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x,
                                   ctrler.view.frame.width/2.0 - (v.frame.width/2.0),
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testCenterHorizontallyWithOffset() {
        v.size(100)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
        v.centerHorizontally(50)
        ctrler.view.setNeedsLayout()
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x - 50,
                                   ctrler.view.frame.width/2.0 - (v.frame.width/2.0),
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }

    
    func testCenterVertically() {
        v.size(100)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
        v.centerVertically()
        ctrler.view.setNeedsLayout()
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y,
                                   ctrler.view.frame.height/2.0 - (v.frame.height/2.0),
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testCenterVerticallyWithOffset() {
        v.size(100)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
        v.centerVertically(50)
        ctrler.view.setNeedsLayout()
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y - 50,
                                   ctrler.view.frame.height/2.0 - (v.frame.height/2.0),
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testCenterInContainer() {
        v.size(100)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
        v.centerInContainer()
        ctrler.view.setNeedsLayout()
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y,
                                   ctrler.view.frame.height/2.0 - (v.frame.height/2.0),
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x,
                                   ctrler.view.frame.width/2.0 - (v.frame.width/2.0),
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }

    func verifyViewHasDefaultValues() {
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 0, accuracy: CGFloat(Float.ulpOfOne))
    }
}
