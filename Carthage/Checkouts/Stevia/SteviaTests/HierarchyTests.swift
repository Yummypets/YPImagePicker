//
//  HierarchyTests.swift
//  Stevia
//
//  Created by Naabed on 12/02/16.
//  Copyright © 2016 Sacha Durand Saint Omer. All rights reserved.
//

import XCTest

import Stevia

class HierarchyTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSv() {
        let view = UIView()
        let v1 = UIView()
        let v2 = UIView()
        view.sv(
            v1,
            v2
        )
        XCTAssertEqual(view.subviews.count, 2)
        XCTAssertTrue(view.subviews.contains(v1))
        XCTAssertTrue(view.subviews.contains(v2))
        XCTAssertFalse(v1.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(v2.translatesAutoresizingMaskIntoConstraints)
    }

    func testVariadicSv() {
        let view = UIView()
        let v1 = UIView()
        let v2 = UIView()
        view.sv(
            v1,
            v2
            )
        XCTAssertEqual(view.subviews.count, 2)
        XCTAssertTrue(view.subviews.contains(v1))
        XCTAssertTrue(view.subviews.contains(v2))
        XCTAssertFalse(v1.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(v2.translatesAutoresizingMaskIntoConstraints)
    }

    func testTableViewCellSV() {
        let cell = UITableViewCell()
        let v1 = UIView()
        let v2 = UIView()
        cell.sv(
            v1,
            v2
            )
        XCTAssertEqual(cell.contentView.subviews.count, 2)
        XCTAssertTrue(cell.contentView.subviews.contains(v1))
        XCTAssertTrue(cell.contentView.subviews.contains(v2))
        XCTAssertFalse(v1.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(v2.translatesAutoresizingMaskIntoConstraints)
    }

    func testTableViewCellVariadicSV() {
        let cell = UITableViewCell()
        let v1 = UIView()
        let v2 = UIView()
        cell.sv(
            v1,
            v2
            )
        XCTAssertEqual(cell.contentView.subviews.count, 2)
        XCTAssertTrue(cell.contentView.subviews.contains(v1))
        XCTAssertTrue(cell.contentView.subviews.contains(v2))
        XCTAssertFalse(v1.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(v2.translatesAutoresizingMaskIntoConstraints)
    }

    func testCollectionViewCellSV() {
        let cell = UICollectionViewCell()
        let v1 = UIView()
        let v2 = UIView()
        cell.sv(
            v1,
            v2
            )
        XCTAssertEqual(cell.contentView.subviews.count, 2)
        XCTAssertTrue(cell.contentView.subviews.contains(v1))
        XCTAssertTrue(cell.contentView.subviews.contains(v2))
        XCTAssertFalse(v1.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(v2.translatesAutoresizingMaskIntoConstraints)
    }

    func testCollectionViewCellVariadicSV() {
        let cell = UICollectionViewCell()
        let v1 = UIView()
        let v2 = UIView()
        cell.sv(
            v1,
            v2
            )
        XCTAssertEqual(cell.contentView.subviews.count, 2)
        XCTAssertTrue(cell.contentView.subviews.contains(v1))
        XCTAssertTrue(cell.contentView.subviews.contains(v2))
        XCTAssertFalse(v1.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(v2.translatesAutoresizingMaskIntoConstraints)
    }
}
