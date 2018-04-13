//: Playground - noun: a place where people can play
import UIKit
import PlaygroundSupport
import Stevia

// Open the Workspace and
// play around with the constraints! 

class SteviaView:UIView {
    
    let email = UITextField()
    let password = UITextField()
    let login = UIButton()
    let forgot = UILabel()
    
    convenience init() {
        self.init(frame:CGRect.zero)
    
        sv(
            email.placeholder("Email").style(fieldStyle),
            password.placeholder("Password").style(fieldStyle).style(passwordFieldStyle),
            login.text("Login").style(buttonSytle).tap(loginTapped),
            forgot.text("Forgot ?")
        )
        
        layout(
            100,
            |-email-| ~ 80,
            8,
            |-password-forgot-| ~ 80,
            >=20,
            |login| ~ 80,
            0
        )
        
        backgroundColor = .white
        password.setContentHuggingPriority(0, for: .horizontal)
        forgot.backgroundColor = .red
    }
    
    func fieldStyle(f:UITextField) {
        f.borderStyle = .roundedRect
        f.font = UIFont(name: "HelveticaNeue-Light", size: 26)
        f.returnKeyType = .next
    }
    
    func passwordFieldStyle(f:UITextField) {
        f.isSecureTextEntry = true
        f.returnKeyType = .done
    }
    
    func buttonSytle(b:UIButton) {
        b.backgroundColor = .lightGray
    }
    
    func loginTapped() {
        //Do something
    }
}




// Contingency code to live reload the Playground.
let v = SteviaView()
v.frame = CGRect(x: 0.0, y: 0.0, width: 375.0, height: 667.0)
PlaygroundPage.current.liveView = v
