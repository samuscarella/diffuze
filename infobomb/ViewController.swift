//
//  ViewController.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase

class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var emailField: TransparentEmailField?
    @IBOutlet weak var usernameField: TransparentUsernameField?
    @IBOutlet weak var passwordField: TransparentPasswordField?
    
    var introMusic: AVAudioPlayer!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
    print("Sign In View Did Load...")

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("Sign In View Did Appear...")
        
        if UserDefaults.standard.value(forKey: KEY_UID) != nil && UserDefaults.standard.value(forKey: KEY_USERNAME) != nil {
            if let user = FIRAuth.auth()?.currentUser {
                print("User is signed in: \(user.displayName!)")
                UserDefaults.standard.setValue(user.uid, forKey: KEY_UID)
                UserDefaults.standard.setValue(user.displayName, forKey: KEY_USERNAME)
                self.playIntroSound()
                self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
            } else {
                print("User is not signed in.")
            }
        } else {
            print("User is not signed in.")
        }

    }
    
    
    @IBAction func loginUserBtnPressed(_ sender: AnyObject) {
        
        if let email = emailField!.text , email != "", let username = usernameField!.text , username != "", let pwd = passwordField!.text , pwd != "" {
            
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd) { (user, error) in
                
                if error != nil {
                    
                        print(error)
                    
                    if error!._code == USER_NOT_FOUND {
                        
                        print("User not found. Attempting to create new user...")
                        
                        FIRAuth.auth()?.createUser(withEmail: email, password: pwd) { (user, error) in
                            
                            if error != nil {
                                
                                print(error)
                                self.showErrorAlert("Could not create account", msg: "Problem creating account. Try something else")
                            } else {
                                
                                FIRAuth.auth()?.signIn(withEmail: email, password: pwd) { (user, error) in
                                    
                                    let user = FIRAuth.auth()?.currentUser
                                    if let user = user {
                                        let changeRequest = user.profileChangeRequest()
                                        
                                        changeRequest.displayName = username
                                        
                                        changeRequest.commitChanges { error in
                                            if error != nil {
                                                print("Could not update user display name.")
                                            } else {
                                                print("User display name updated!")
                                            }
                                        }
                                    }

                                    UserDefaults.standard.setValue(user!.uid, forKey: KEY_UID)
                                    UserDefaults.standard.setValue(username, forKey: KEY_USERNAME)

                                    let userData = [
                                        "email": email,
                                        "username": username,
                                        "provider": FIREBASE,
                                        "user_ref": user!.uid
                                    ]
                                    UserService.ds.createFirebaseUser(user!.uid, user: userData)
                                    self.playIntroSound()
                                    self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                                }
                            }
                        }
                    } else if error?._code == PASSWORD_NOT_FOUND {
                        self.showErrorAlert("Could not login", msg: "Please check your username or password!")
                    }
                } else {
                    
                    UserDefaults.standard.setValue(user!.uid, forKey: KEY_UID)
                    UserDefaults.standard.setValue(username, forKey: KEY_USERNAME)
                    print("User is signed in: \(user!.displayName)")
                    self.playIntroSound()
                    self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                }
            }
        
        } else {
            showErrorAlert("Username or Password is Invalid!", msg: "Please check your credentials and try again.")
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
    

    
    

}

