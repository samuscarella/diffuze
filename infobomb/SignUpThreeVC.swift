//
//  SignUpThreeVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/7/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import FirebaseAuth
import AVFoundation
import SCLAlertView

class SignUpThreeVC: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var completeBtn: UIButton!
    @IBOutlet weak var signUpBtnBottomConstraint: NSLayoutConstraint!
    
    var email: String!
    var username: String!
    var introMusic: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        passwordField.attributedPlaceholder = NSAttributedString(string: "Password", attributes:[NSForegroundColorAttributeName: UIColor.lightGray])
        
        confirmPasswordField.attributedPlaceholder = NSAttributedString(string: "Password Confirmation", attributes:[NSForegroundColorAttributeName: UIColor.lightGray])
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpThreeVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        

        
        passwordField.autocorrectionType = .no
        confirmPasswordField.autocorrectionType = .no
        
        passwordField.becomeFirstResponder()

        completeBtn.layer.cornerRadius = 3
        //change back button from x to <-
    }
    
    override func viewWillAppear(_ animated: Bool) {
        signUpBtnBottomConstraint.constant = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    @IBAction func finalizeBtnPressed(_ sender: AnyObject) {
        
        if passwordField.text != "" {
            
            FIRAuth.auth()?.createUser(withEmail: email, password: passwordField.text!) { (user, error) in
                
                if error != nil {
                    
                    self.showErrorAlert("Could not create account", msg: "Problem creating account. Try something else")
                } else {
                    
                    FIRAuth.auth()?.signIn(withEmail: self.email, password: self.passwordField.text!) { (user, error) in
                        
                        let user = FIRAuth.auth()?.currentUser
                        if let user = user {
                            let changeRequest = user.profileChangeRequest()
                            
                            changeRequest.displayName = self.username
                            
                            changeRequest.commitChanges { error in
                                if error != nil {
                                    print("Could not update user display name.")
                                } else {
                                    print("User display name updated!")
                                }
                            }
                        }
                        
                        UserDefaults.standard.setValue(user!.uid, forKey: KEY_UID)
                        UserDefaults.standard.setValue(self.username, forKey: KEY_USERNAME)
                        
                        let userData = [
                            "email": self.email,
                            "username": self.username,
                            "provider": FIREBASE,
                            "user_ref": user!.uid
                        ]
                        UserService.ds.createFirebaseUser(user!.uid, user: userData as! Dictionary<String, String>)
                        self.playIntroSound()
                        self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                    }
                }
            }
        }
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                self.signUpBtnBottomConstraint.constant = keyboardSize.height
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
            else {
                
            }
        }
    }

    @IBAction func unwindToSignUpThree(_ segue: UIStoryboardSegue) {
        
    }
    
    func showErrorAlert(_ title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        let alertView = SCLAlertView()

        if passwordField.text != "" && confirmPasswordField.text != "" && passwordField.text == confirmPasswordField.text {
            return true
        } else if (passwordField.text?.characters.count)! == 0 {
            
            alertView.showError("Validation Error", subTitle: "\nPassword cannot be blank.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
            return false
        } else if (passwordField.text?.characters.count)! < 6 {
            
            alertView.showError("Validation Error", subTitle: "\nPassword must be at least 6 characters long.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
            return false
        } else if (passwordField.text?.characters.count)! > 20 {
            
            alertView.showError("Validation Error", subTitle: "\nPassword cannot be longer than 20 characters in length.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
            return false
        } else if (passwordField.text?.characters.count)! > 5 && passwordField.text != confirmPasswordField.text {
            
            alertView.showError("Validation Error", subTitle: "\nPassword Confirmation does not match.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            alertView.view.frame.origin.y -= 90
            return false
        } else if passwordField.text == confirmPasswordField.text {
            return true
        }
        alertView.showError("Validation Error", subTitle: "\nCould not create password. Please try something else.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
        alertView.view.frame.origin.y -= 90
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "SignUpFourVC" {
            let nav = segue.destination as! SignUpFourVC;
            nav.username = username
            nav.password = passwordField.text!
            nav.email = email
        }
        self.signUpBtnBottomConstraint.constant = 0
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "GoToSignUpTwo", sender: self)
    }

}
