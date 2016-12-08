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

class SignUpThreeVC: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var completeBtn: UIButton!
    
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

        completeBtn.layer.cornerRadius = 3
        //change back button from x to <-
    }
    
    @IBAction func finalizeBtnPressed(_ sender: AnyObject) {
        
        if passwordField.text != "" {
            
            FIRAuth.auth()?.createUser(withEmail: email, password: passwordField.text!) { (user, error) in
                
                if error != nil {
                    
                    print(error)
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
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "GoToSignUpTwo", sender: self)
    }

}
