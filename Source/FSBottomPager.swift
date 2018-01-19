//
//  FSBottomPager.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class PagerMenu: UIView {
    
    var didSetConstraints = false
    var menuItems = [MenuItem]()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = UIColor(r: 247, g: 247, b: 247)
    }
    
    var separators = [UIView]()
    
    func setUpMenuItemsConstraints() {
        let menuItemWidth: CGFloat = UIScreen.main.bounds.width / CGFloat(menuItems.count)
        var previousMenuItem: MenuItem?
        for m in menuItems {
            
            sv(
                m
            )

            m.fillVertically().width(menuItemWidth)
            if let pm = previousMenuItem {
                pm-0-m
            } else {
                |-m
            }
                        
            previousMenuItem = m
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        if !didSetConstraints {
            setUpMenuItemsConstraints()
        }
        didSetConstraints = true
    }
    
    func refreshMenuItems() {
        didSetConstraints = false
        updateConstraints()
    }
}

final class MenuItem: UIView {
    
    var text = UILabel()
    var button = UIButton()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        
        sv(
            text,
            button
        )
        
        text.centerInContainer()
        button.fillContainer()
        
        text.style { l in
            l.textAlignment = .center
            l.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
            l.textColor = self.unselectedColor()
        }
    }
    
    func selectedColor() -> UIColor {
        return UIColor(r: 38, g: 38, b: 38)
    }
    
    func unselectedColor() -> UIColor {
        return UIColor(r: 153, g: 153, b: 153)
    }
    
    func select() {
        text.textColor = selectedColor()
    }
    
    func unselect() {
        text.textColor = unselectedColor()
    }
}

final class PagerView: UIView {
    
    var header = PagerMenu()
    var scrollView = UIScrollView()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = UIColor(red: 239/255, green: 238/255, blue: 237/255, alpha: 1)
        
        sv(
            scrollView,
            header
        )
        
        layout(
            0,
            |scrollView|,
            0,
            |header| ~ 50
        )
        
        if #available(iOS 11.0, *) {
            header.Bottom == safeAreaLayoutGuide.Bottom
        } else {
            header.bottom(0)
        }

        clipsToBounds = false
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.bounces = false
    }
}

protocol PagerDelegate: class {
    func pagerScrollViewDidScroll(_ scrollView: UIScrollView)
    func pagerDidSelectController(_ vc: UIViewController)
}

public class FSBottomPager: UIViewController, UIScrollViewDelegate {
    
    weak var delegate: PagerDelegate?
    var controllers = [UIViewController]() { didSet { reload() } }
    
    var v = PagerView()
    
    var currentPage = 0
    
    override public func loadView() {
        self.automaticallyAdjustsScrollViewInsets = false
        v.scrollView.delegate = self
        view = v
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.pagerScrollViewDidScroll(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !v.header.menuItems.isEmpty {
            let menuIndex = (targetContentOffset.pointee.x + v.frame.size.width) / v.frame.size.width
            let selectedIndex = Int(round(menuIndex)) - 1
            if selectedIndex != currentPage {
                selectPage(selectedIndex)
            }
        }
    }
    
    func reload() {
        let viewWidth: CGFloat = UIScreen.main.bounds.width
        for (index, c) in controllers.enumerated() {
            addChildViewController(c)
            let x: CGFloat = CGFloat(index) * viewWidth
            v.scrollView.sv(c.view)
            c.view.left(x)
            c.view.top(0)
            c.view.width(viewWidth)
            equalHeights(c.view, v.scrollView)
        }
        
        let scrollableWidth: CGFloat = CGFloat(controllers.count) * CGFloat(viewWidth)
        v.scrollView.contentSize = CGSize(width: scrollableWidth, height: 0)
        
        // Build headers
        for (index, c) in controllers.enumerated() {
            let menuItem = MenuItem()
            menuItem.text.text = c.title?.capitalized
            menuItem.button.tag = index
            menuItem.button.addTarget(self,
                                      action: #selector(tabTapped(_:)),
                                      for: .touchUpInside)
            v.header.menuItems.append(menuItem)
        }
        
        let currentMenuItem = v.header.menuItems[0]
        currentMenuItem.select()
        v.header.refreshMenuItems()
    }
    
    @objc
    func tabTapped(_ b: UIButton) {
        showPage(b.tag)
    }
    
    func showPage(_ page: Int, animated: Bool = true) {
        let x = CGFloat(page) * UIScreen.main.bounds.width
        v.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
        selectPage(page)
    }

    func selectPage(_ page: Int) {
        currentPage = page
        //select menut item and deselect others
        for mi in v.header.menuItems {
            mi.unselect()
        }
        let currentMenuItem = v.header.menuItems[page]
        currentMenuItem.select()
        delegate?.pagerDidSelectController(controllers[page])
    }
    
    func startOnPage(_ page: Int) {
        currentPage = page
        let x = CGFloat(page) * UIScreen.main.bounds.width
        v.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
        //select menut item and deselect others
        for mi in v.header.menuItems {
            mi.unselect()
        }
        let currentMenuItem = v.header.menuItems[page]
        currentMenuItem.select()
    }
}
