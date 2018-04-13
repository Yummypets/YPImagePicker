//
//  LoginViewNative.swift
//  LoginStevia
//
//  Created by Sacha Durand Saint Omer on 01/10/15.
//  Copyright © 2015 Sacha Durand Saint Omer. All rights reserved.
//

import UIKit

class LoginViewNative: UIView {
    
    let email = UITextField()
    let password = UITextField()
    let login = UIButton()
    
    convenience init() {
        self.init(frame:CGRect.zero)
        render()
    }
    
    func render() {
        
        // View Hieararchy
        email.translatesAutoresizingMaskIntoConstraints = false
        password.translatesAutoresizingMaskIntoConstraints = false
        login.translatesAutoresizingMaskIntoConstraints = false
        addSubview(email)
        addSubview(password)
        addSubview(login)
        
        // Layout (using latest layoutAnchors)
        email.topAnchor.constraint(equalTo: topAnchor, constant: 100).isActive = true
        email.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
        email.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        email.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        password.topAnchor.constraint(equalTo: email.bottomAnchor, constant: 8).isActive = true
        password.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
        password.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        password.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        login.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        login.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        login.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        login.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        // Styling
        backgroundColor = .gray
        email.borderStyle = .roundedRect
        email.autocorrectionType = .no
        email.keyboardType = .emailAddress
        email.font = UIFont(name: "HelveticaNeue-Light", size: 26)
        email.returnKeyType = .next
        password.borderStyle = .roundedRect
        password.font = UIFont(name: "HelveticaNeue-Light", size: 26)
        password.isSecureTextEntry = true
        password.returnKeyType = .done
        login.backgroundColor = .lightGray
        
        // Content
        email.placeholder = "Email"
        password.placeholder = "Password"
        login.setTitle("Login", for: .normal)
    }
    
    func loginTapped() {
        //Do something
    }
}

