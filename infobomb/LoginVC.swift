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

class LoginVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    
    var introMusic: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        emailField.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 40, height: 30)
        passwordField.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 40, height: 30)
        loginBtn.layer.cornerRadius = 3

        makeTextFieldBottomBorderOnly(textField: emailField)
        makeTextFieldBottomBorderOnly(textField: passwordField)
        
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password", attributes:[NSForegroundColorAttributeName: UIColor.white])
        
        
    }
    
    @IBAction func loginBtnPressed(_ sender: AnyObject) {
        
        if let email = emailField!.text , email != "", let pwd = passwordField!.text , pwd != "" {
            
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd) { (user, error) in
                
                if error != nil {
                    
                    print(error)
                    
                    if error!._code == USER_NOT_FOUND {
                        
                        print("User not found. Attempting to create new user...")
                        
                    } else if error?._code == PASSWORD_NOT_FOUND {
                        self.showErrorAlert("Could not login", msg: "Please check your username or password!")
                    }
                } else {
                    
                    UserDefaults.standard.setValue(user!.uid, forKey: KEY_UID)
                    print("User is signed in: \(user!.displayName)")
                    self.playIntroSound()
                    self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                }
            }
            
        } else {
            showErrorAlert("Username or Password is Invalid!", msg: "Please check your credentials and try again.")
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
