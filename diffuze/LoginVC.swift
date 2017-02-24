//
//  LoginVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/6/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import FirebaseAuth
import AVFoundation
import SCLAlertView

class LoginVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var placeholderView: UIView!
    
    var difference: CGFloat?
    var reset: CGFloat?
    var introMusic: AVAudioPlayer!
    var noLocationAccess: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.removeObject(forKey: KEY_UID)
        UIApplication.shared.statusBarStyle = .lightContent

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        emailField.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 40, height: 30)
        passwordField.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 40, height: 30)
        loginBtn.layer.cornerRadius = 3
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginVC.dismissKeyboard))
        view.addGestureRecognizer(tap)

        makeTextFieldBottomBorderOnly(textField: emailField)
        makeTextFieldBottomBorderOnly(textField: passwordField)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        emailField.autocorrectionType = .no
        passwordField.autocorrectionType = .no
        
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password", attributes:[NSForegroundColorAttributeName: UIColor.white])
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func dismissKeyboard() {
        
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if noLocationAccess != nil && noLocationAccess == true {
            
            let alertView = SCLAlertView()
            alertView.addButton("Settings", backgroundColor: UIColor.red, textColor: UIColor.white, showDurationStatus: true, target: self, selector: #selector(LoginVC.goToSettings))
            alertView.showError("Location Failure", subTitle: "\nDue to the nature of the application, you must have location tracking enabled. Please give permission in the settings.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
        }
    }
    
    func goToSettings() {
        
        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
        if let url = settingsUrl {
 
            UIApplication.shared.openURL(url as URL)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if(string == "\n") {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    @IBAction func loginBtnPressed(_ sender: AnyObject) {
        
        if let email = emailField!.text , email != "", let pwd = passwordField!.text , pwd != "" {
            
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd) { (user, error) in
                
                if error != nil {
                    
                    let alertView = SCLAlertView()
                    alertView.showError("Authentication Failure", subTitle: "\nInvalid Email and Password.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
                    
                } else {
                    
                    UserDefaults.standard.setValue(user!.uid, forKey: KEY_UID)
                    UserDefaults.standard.setValue(user!.displayName, forKey: KEY_USERNAME)
                    print("User is signed in: \(user!.displayName)")
                    self.playIntroSound()
                    self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                }
            }
            
        } else {

            let alertView = SCLAlertView()
            alertView.showError("Authentication Failure", subTitle: "\nInvalid Email and Password.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
        }

    }
    
    @IBAction func cancelLoginBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "GoToMainScreen", sender: self)
    }
    
    func showErrorAlert(_ title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    func makeTextFieldBottomBorderOnly(textField: UITextField) {
        
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: textField.frame.height - 1, width: textField.frame.size.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.white.cgColor
        textField.borderStyle = UITextBorderStyle.none
        textField.layer.addSublayer(bottomLine)
        textField.attributedPlaceholder = NSAttributedString(string: "Email", attributes:[NSForegroundColorAttributeName: UIColor.white])
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                
                UIView.animate(withDuration: 0.9) {
                    
                    if keyboardSize.size.height > self.placeholderView.frame.size.height {
                        
                        self.difference = keyboardSize.size.height - self.placeholderView.frame.size.height
                        self.view.frame.origin.y -= self.difference!
                        self.view.layoutIfNeeded()
                    }
                }
            }
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y != 0 {

                UIView.animate(withDuration: 0.9) {
                    
                    self.view.frame.origin.y += self.difference!
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    @IBAction func unwindToLoginVC(_ segue: UIStoryboardSegue) {
        
    }
    
    func playIntroSound() {
        
        let path = Bundle.main.path(forResource: "intro", ofType: "mp3")!
        
        do {
            introMusic = try AVAudioPlayer(contentsOf: URL(string: path)!)
            introMusic.prepareToPlay()
            introMusic.play()
        } catch let err as NSError {
            print(err.debugDescription)
        } catch {
            print("Error Could not play Sound!")
        }
    }

}
