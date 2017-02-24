//
//  SignUpTwoVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/7/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import SCLAlertView

class SignUpTwoVC: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var signUpBtnBottomConstraint: NSLayoutConstraint!
    
    var email: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        usernameField.attributedPlaceholder = NSAttributedString(string: "Username", attributes:[NSForegroundColorAttributeName: UIColor.lightGray])
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpTwoVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        usernameField.autocorrectionType = .no
        usernameField.becomeFirstResponder()
        
        continueBtn.layer.cornerRadius = 3
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.signUpBtnBottomConstraint.constant = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if view.frame.origin.y == 0 {
                
                self.signUpBtnBottomConstraint.constant = keyboardSize.height
                
                UIView.animate(withDuration: 0.3) {
                    
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToSignUpOneVC", sender: self)
    }
    
    @IBAction func unwindToSignUpTwo(_ segue: UIStoryboardSegue) {
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        let alertView = SCLAlertView()

        if usernameField.text == "" {
            
            alertView.showError("Validation Error", subTitle: "\nUsername cannot be blank.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
            return false
        } else if (usernameField.text?.characters.count)! < 6 {
            
            alertView.showError("Validation Error", subTitle: "\nUsername must be at least 6 characters.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
            return false
        } else if (usernameField.text?.characters.count)! > 20 {
            
            alertView.showError("Validation Error", subTitle: "\nUsername can be no longer than 20 characters.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "SignUpThreeVC" {
            let nav = segue.destination as! SignUpThreeVC;
            nav.username = usernameField.text!
            nav.email = email
        }
        self.signUpBtnBottomConstraint.constant = 0
    }

}
