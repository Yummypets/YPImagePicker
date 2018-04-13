//
//  Stevia+Tap.swift
//  LoginStevia
//
//  Created by Sacha Durand Saint Omer on 01/10/15.
//  Copyright © 2015 Sacha Durand Saint Omer. All rights reserved.
//

import UIKit

typealias ActionBlock = (() -> Void)?

class ClosureWrapper {
    var closure: ActionBlock
    
    init(_ closure: ActionBlock) {
        self.closure = closure
    }
}

private var kButtonBlockAssociationKey: UInt8 = 0
public extension UIButton {
    
    internal var testButtonBlock: ActionBlock {
        get {
            if let cw = objc_getAssociatedObject(self,
                                                 &kButtonBlockAssociationKey) as? ClosureWrapper {
                return cw.closure
            }
            return nil
        }
        set(newValue) {
            objc_setAssociatedObject(self,
                                     &kButtonBlockAssociationKey,
                                     ClosureWrapper(newValue),
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /** Links UIButton tap (TouchUpInside) event to a block.
     
    Example Usage:
     
    ```
    button.tap {
        // do something
    }
    ```
     
    Or
    ```
    button.tap(doSomething)

    // later
    func doSomething() {
        // ...
    }
    ```
     
     - Returns: Itself for chaining purposes
     
     */
    @available(*, deprecated: 4.1.0,
                  message: "Use classic .addTarget(self, action: #selector(mySelector), for: .touchUpInside)")
    @discardableResult
    public func tap(_ block:@escaping () -> Void) -> UIButton {
        #if swift(>=2.2)
        addTarget(self, action: #selector(UIButton.tapped), for: .touchUpInside)
        #else
        addTarget(self, action: "tapped", forControlEvents: .TouchUpInside)
        #endif
        testButtonBlock = block
        return self
    }
    
    /** */
    @objc func tapped() {
        testButtonBlock?()
    }
}
