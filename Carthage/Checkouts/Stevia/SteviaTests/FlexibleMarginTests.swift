//
//  FlexibleMarginTests.swift
//  Stevia
//
//  Created by Sacha Durand Saint Omer on 21/02/16.
//  Copyright © 2016 Sacha Durand Saint Omer. All rights reserved.
//

import XCTest
import Stevia

class FlexibleMarginTests: XCTestCase {
        
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
        v.size(100.0)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /// Todo stress test by pushing views
    
    func testGreaterTop() {
        v.top(>=23)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 23, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testGreaterBottom() {
        v.bottom(>=45)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, ctrler.view.frame.height - v.frame.height - 45,
                        accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testGreaterLeft() {
        v.left(>=23)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 23, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }

    func testGreaterRight() {
        v.right(>=74)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, ctrler.view.frame.width - v.frame.width - 74,
                       accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testLessTop() {
        v.top(<=23)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 23, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testLessBottom() {
        v.bottom(<=45)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y,
                                   ctrler.view.frame.height - v.frame.height - 45,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testLessLeft() {
        v.left(<=23)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 23, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testLessLeftOperator() {
        |-(<=23)-v
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, 23, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testLessRight() {
        v.right(<=74)
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, ctrler.view.frame.width - v.frame.width - 74,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    
    func testLessRightOperator() {
        v-(<=74)-|
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.origin.x, ctrler.view.frame.width - v.frame.width - 74,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.width, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.frame.height, 100, accuracy: CGFloat(Float.ulpOfOne))
    }
    
    func testMarginGreaterBetweenTwoViews() {
        let v1 = UIView()
        let v2 = UIView()
        v.removeFromSuperview()
        ctrler.view.sv(v1, v2)
        for view in ctrler.view.subviews {
            XCTAssertEqual(view.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
            XCTAssertEqual(view.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
            XCTAssertEqual(view.frame.width, 0, accuracy: CGFloat(Float.ulpOfOne))
            XCTAssertEqual(view.frame.height, 0, accuracy: CGFloat(Float.ulpOfOne))
        }
        
        |v1.width(10)-(>=25)-v2
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v1.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v1.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v1.frame.width, 10, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v1.frame.height, 0, accuracy: CGFloat(Float.ulpOfOne))
        
        XCTAssertEqual(v2.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v2.frame.origin.x, 35, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v2.frame.width, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v2.frame.height, 0, accuracy: CGFloat(Float.ulpOfOne))
        
    }
    
    func testMarginLesserBetweenTwoViews() {
        let v1 = UIView()
        let v2 = UIView()
        v.removeFromSuperview()
        ctrler.view.sv(v1, v2)
        for view in ctrler.view.subviews {
            XCTAssertEqual(view.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
            XCTAssertEqual(view.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
            XCTAssertEqual(view.frame.width, 0, accuracy: CGFloat(Float.ulpOfOne))
            XCTAssertEqual(view.frame.height, 0, accuracy: CGFloat(Float.ulpOfOne))
        }
        
        |v1.width(10)-(<=25)-v2
        ctrler.view.layoutIfNeeded()
        XCTAssertEqual(v1.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v1.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v1.frame.width, 10, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v1.frame.height, 0, accuracy: CGFloat(Float.ulpOfOne))
        
        XCTAssertEqual(v2.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v2.frame.origin.x, 35, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v2.frame.width, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v2.frame.height, 0, accuracy: CGFloat(Float.ulpOfOne))
        
    }
    
}
