//
//  SignUpOneVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/7/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import SCLAlertView

class SignUpOneVC: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var signUpBtnBottomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        emailField.attributedPlaceholder = NSAttributedString(string: "Email", attributes:[NSForegroundColorAttributeName: UIColor.lightGray])
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpOneVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        emailField.autocorrectionType = .no
        continueBtn.layer.cornerRadius = 3
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                self.signUpBtnBottomConstraint.constant = keyboardSize.height
                UIView.animate(withDuration: 0.9) {
                    self.view.layoutIfNeeded()
                }
            }
            else {
                
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.signUpBtnBottomConstraint.constant = 0
    }
    
    @IBAction func goBackBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "GoToMainScreen", sender: self)
    }

    @IBAction func unwindToSignUpOne(_ segue: UIStoryboardSegue) {
        
    }
    
    func isValidEmail(testStr: String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {

        if isValidEmail(testStr: emailField.text!) {
            return true
        }
        let alertView = SCLAlertView()
        alertView.showError("Validation Error", subTitle: "\nEmail is Invalid. Please make sure it is a valid email.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
        return false
    }
    
    /*z
     let appearance = SCLAlertView.SCLAppearance(
     kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
     kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
     kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
     showCloseButton: false
     )
     .showTitle(
    "Congratulations", // Title of view
    subTitle: "Operation successfully completed.", // String of view
    duration: 2.0, // Duration to show before closing automatically, default: 0.0
    completeText: "Done", // Optional button value, default: ""
    style: .Success, // Styles - see below.
    colorStyle: 0xA429FF,
    colorTextButton: 0xFFFFFF
    )*/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "SignUpTwoVC" {
            
            let nav = segue.destination as! SignUpTwoVC
            nav.email = emailField.text!
        }
        self.signUpBtnBottomConstraint.constant = 0
    }
    
}
