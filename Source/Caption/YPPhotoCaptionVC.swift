//
//  YPPhotoCaptionVC.swift
//  YPImagePicker
//
//  Created by Umut Genlik on 10/26/18.
//

import UIKit


open class YPPhotoCaptionVC: UIViewController, IsMediaFilterVC {
    
    required public init(inputPhoto: YPMediaPhoto, isFromSelectionVC: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.inputPhoto = inputPhoto
        self.isFromSelectionVC = isFromSelectionVC
    }
    
    var activeField: UITextView?
    var dismissKeyboardButton:UIBarButtonItem?
    
    
    public var inputPhoto: YPMediaPhoto!
    public var isFromSelectionVC = false
    
    public var didSave: ((YPMediaItem) -> Void)?
    public var didCancel: (() -> Void)?
    
    fileprivate var v = YPCaptionView()
    
    // scrollView is needed to move the textview when keyboard is shown
    fileprivate var scrollView = UIScrollView()
    
    override open var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    
    
    fileprivate func addScrollView()
    {
        // set scroll view's frame as full view
        scrollView.frame = view.frame
        
        // add YPCaptionView as a subview of scrollview
        v.frame = scrollView.frame
        scrollView.addSubview(v)
        
        scrollView.backgroundColor = UIColor(r: 247, g: 247, b: 247)
        // make sure scrolling is disabled until user touches textview
        scrollView.isScrollEnabled = false
        
        view.addSubview(scrollView)
    }
    
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    
    // MARK: - Life Cycle ♻️
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Don't use override loadView  method, somehow subviews are not in correct place, so just adding v to scrollview manually
        addScrollView()
        
        // listen keyboard notifications to move the scroll view up and down
        registerForKeyboardNotifications()
        
        // delegate for v's textview so we can scroll the scrollview when keyboard is up
        v.textView.delegate = self
        
        // Setup of main image
        v.imageView.image = inputPhoto.image
        
        // Check and set the v's textview with photo's caption
        if let caption = self.inputPhoto.caption
        {
            v.textView.text = caption
        }
        
        // dismiss keyboard button
        dismissKeyboardButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dissmissKeyboard))
        
        // Setup of Navigation Bar
        title = YPConfig.wordings.caption.title
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
        }
        setupRightBarButton()
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
        
    }
    
    // MARK: Setup - ⚙️
    
    fileprivate func setupRightBarButton() {
        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.done : YPConfig.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
    }
    
    
    // MARK: - Actions 🥂
    
    @objc
    func cancel() {
        self.deregisterFromKeyboardNotifications()
        didCancel?()
    }
    
    @objc
    func save() {
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
        
        DispatchQueue.global().async {
            self.inputPhoto.modifiedImage = nil
            self.deregisterFromKeyboardNotifications()
            DispatchQueue.main.async {
                didSave(YPMediaItem.photo(p: self.inputPhoto))
                self.setupRightBarButton()
            }
        }
    }
}


extension YPPhotoCaptionVC:UITextViewDelegate
{
    
    func registerForKeyboardNotifications(){
        // Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        // Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShown(notification: NSNotification){
        DispatchQueue.main.async {
            // Need to calculate keyboard exact size due to Apple suggestions
            self.activeField = self.v.textView
            
            // Change the functionality of Done button to dismiss keyboard
            self.navigationItem.rightBarButtonItem = self.dismissKeyboardButton
            
            
            // Make sure scroll is enabled
            self.scrollView.isScrollEnabled = true
            
            // Get the keyboard height and  contentInset
            var info = notification.userInfo!
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
            let contentInsets : UIEdgeInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: keyboardSize!.height, right: 0.0)
            
            // Make the scrollview height longer so we can scroll
            self.scrollView.contentSize = CGSize(width: self.scrollView.frame.width, height: self.scrollView.frame.height + keyboardSize!.height)
            
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            
            var aRect : CGRect = self.view.frame
            aRect.size.height -= keyboardSize!.height
            
            if let activeField = self.activeField {
                var point = activeField.frame.origin; point.y += activeField.frame.size.height
                if (!aRect.contains(point)){
                    // Scroll to desired position
                    self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
                }
            }
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification){
        
        DispatchQueue.main.async {
            // Change scrollview content height to original value
            self.scrollView.contentSize = CGSize(width: self.scrollView.frame.width, height: self.scrollView.frame.height)
            
            // Once keyboard disappears, restore original positions
            var info = notification.userInfo!
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
            let contentInsets : UIEdgeInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: -keyboardSize!.height, right: 0.0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            self.view.endEditing(true)
            self.scrollView.isScrollEnabled = false
        }
    }
    

    @objc func dissmissKeyboard()
    {
        // if textview has some text pass it to photo item
        if let text = v.textView.text
        {
            inputPhoto.caption = text
        }
        
        // Reset the activefield variable
        activeField = nil
        
        // Remove the dismisskeyboard bar button item
        self.navigationItem.rightBarButtonItem = nil
        
        // Resign textview responder
        v.textView.resignFirstResponder()
        
        // Set right bar button to original "Done" button
        setupRightBarButton()
    }
}


