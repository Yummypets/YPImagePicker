//
//  FullLayoutTests.swift
//  Stevia
//
//  Created by Sacha Durand Saint Omer on 21/02/16.
//  Copyright © 2016 Sacha Durand Saint Omer. All rights reserved.
//

import XCTest
import Stevia

class TestView: UIView {
    
    let email = UITextField()
    let password = UITextField()
    let login = UIButton()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        sv(
            email,
            password,
            login
        )
        
        layout(
            100,
            |-email-22-| ~ 80,
            20,
            |password.width(54) ~ 47,
            "",
            login.centerHorizontally() ~ 99,
            7
        )
    }
}

class FullLayoutTests: XCTestCase {
        
    var win: UIWindow!
    var vc: UIViewController!
    var v: TestView!
    
    override func setUp() {
        super.setUp()
        win = UIWindow(frame: UIScreen.main.bounds)
        vc = UIViewController()///TestVC()
        win.rootViewController = vc
        v = TestView()
        v.frame = vc.view.frame
        vc.view = v
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFullLayout() {
        XCTAssertEqual(vc.view.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(vc.view.frame.origin.y, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(vc.view.frame.width, win.frame.width,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(vc.view.frame.height, win.frame.height,
                                   accuracy: CGFloat(Float.ulpOfOne))
        
        v.layoutIfNeeded()

        // Email
        XCTAssertEqual(v.email.frame.origin.y, 100, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.email.frame.origin.x, 8, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.email.frame.width, win.frame.width - 8 - 22,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.email.frame.height, 80, accuracy: CGFloat(Float.ulpOfOne))
        
        // Password
        XCTAssertEqual(v.password.frame.origin.y,
                                   v.email.frame.origin.y+v.email.frame.height + 20,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.password.frame.origin.x, 0, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.password.frame.width, 54, accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.password.frame.height, 47, accuracy: CGFloat(Float.ulpOfOne))
        
        // Password
        XCTAssertEqual(v.login.frame.origin.y,
                                   win.frame.height - v.login.frame.height - 7,
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.login.frame.origin.x,
                                   win.frame.width/2.0 - (v.login.frame.width/2.0),
                                   accuracy: CGFloat(Float.ulpOfOne))
        XCTAssertEqual(v.login.frame.height, 99, accuracy: CGFloat(Float.ulpOfOne))
    }
}
