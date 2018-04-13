//
//  ContentTests.swift
//  Stevia
//
//  Created by Naabed on 12/02/16.
//  Copyright © 2016 Sacha Durand Saint Omer. All rights reserved.
//

import XCTest

import Stevia

let title = "TitleTest"

class UIButtonContentTests: XCTestCase {
    var button = UIButton()

    override func setUp() {
        super.setUp()
        button = UIButton()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testText() {
        button.text(title)
        XCTAssertEqual(button.currentTitle, title)
        XCTAssertEqual(button.state, .normal)
    }
    
    func testTextKey() {
        button.textKey(title)
        XCTAssertEqual(button.currentTitle, title)
    }
    
    func testImage() {
        button.image("foo")
        //XCTAssertEqual(button.currentImage, title)
    }
}

class UILabelContentTests: XCTestCase {
    var label = UILabel()
    
    override func setUp() {
        super.setUp()
        label = UILabel()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testText() {
        label.text(title)
        XCTAssertEqual(label.text, title)
    }
    
    func testTextKey() {
        label.textKey(title)
        XCTAssertEqual(label.text, title)
    }
}

class UITextFieldContentTests: XCTestCase {
    var textField = UITextField()
    
    override func setUp() {
        super.setUp()
        textField = UITextField()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPlaceholder() {
        textField.placeholder(title)
        XCTAssertEqual(textField.placeholder, title)
    }
}

class UIImageViewContentTests: XCTestCase {
    var imageView = UIImageView()
    
    override func setUp() {
        super.setUp()
        imageView = UIImageView()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImage() {
        imageView.image("foo")
        //XCTAssertEqual(button.currentImage, title)
    }
}
