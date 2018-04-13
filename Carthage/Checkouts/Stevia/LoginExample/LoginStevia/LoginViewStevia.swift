//
//  LoginViewStevia.swift
//  LoginStevia
//
//  Created by Sacha Durand Saint Omer on 01/10/15.
//  Copyright © 2015 Sacha Durand Saint Omer. All rights reserved.
//

import UIKit
import Stevia

class LoginViewStevia: UIView {
    
    let email = UITextField()
    let password = UITextField()
    let login = UIButton()
    
    convenience init() {
        self.init(frame:CGRect.zero)
        // This is only needed for live reload as injectionForXcode
        // doesn't swizzle init methods.
        // Get injectionForXcode here : http://johnholdsworth.com/injection.html
        render()
    }
    
    func render() {

        // View Hierarchy
        // This essentially does `translatesAutoresizingMaskIntoConstraints = false`
        // and `addSubsview()`. The neat benefit is that
        // (`sv` calls can be nested which will visually show hierarchy ! )
        sv(
            email,
            password,
            login
        )
        
        // Vertical + Horizontal Layout in one pass
        // With type-safe visual format
        layout(
            100,
            |-email-| ~ 80,
            8,
            |-password-| ~ 80,
            "",
            |login| ~ 80,
            0
        )
        
        // ⛓ Chainable api
//        email.top(100).fillHorizontally(m: 8).height(80)
//        password.Top == email.Bottom + 8
//        password.fillHorizontally(m: 8).height(80)
//        login.bottom(0).fillHorizontally().height(80)
        
        // 📐 Equation based layout (Try it out!)
        //This comes in handy to cover tricky layout cases
//        email.Top == Top + 100
//        email.Left == Left + 8
//        email.Right == Right - 8
//        email.Height == 80
//
//        password.Top == email.Bottom + 8
//        password.Left == Left + 8
//        password.Right == Right - 8
//        password.Height == 80
//
//        password.Top == email.Bottom + 8
//        password.Left == Left + 8
//        password.Right == Right - 8
//        password.Height == 80
//
//        login.Left == Left
//        login.Right == Right
//        login.Bottom == Bottom
//        login.Height == 80
        

        // Styling 🎨
        backgroundColor = .gray
        email.style(commonFieldStyle)
        password.style(commonFieldStyle).style { f in
            f.isSecureTextEntry = true
            f.returnKeyType = .done
        }
        login.backgroundColor = .lightGray
        
        // Content 🖋
        email.placeholder = "Email"
        password.placeholder = "Password"
        login.setTitle("Login", for: .normal)
    }

    // Style can be extracted and applied kind of like css \o/
    // but in pure Swift though!
    func commonFieldStyle(_ f:UITextField) {
        f.borderStyle = .roundedRect
        f.font = UIFont(name: "HelveticaNeue-Light", size: 26)
        f.returnKeyType = .next
    }
}
