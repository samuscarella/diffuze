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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        print("Sign In View Did Appear...")
        if let user = FIRAuth.auth()?.currentUser {
            print("User is signed in: \(user)")
            NSUserDefaults.standardUserDefaults().setValue(user.uid, forKey: KEY_UID)
            NSUserDefaults.standardUserDefaults().setValue(user.displayName, forKey: KEY_USERNAME)
            self.playIntroSound()
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        } else {
            print("User is not signed in.")
        }

    }
    
    
    @IBAction func loginUserBtnPressed(sender: AnyObject) {
        
        if let email = emailField!.text where email != "", let username = usernameField!.text where username != "", let pwd = passwordField!.text where pwd != "" {
            
            FIRAuth.auth()?.signInWithEmail(email, password: pwd) { (user, error) in
                
                if error != nil {
                    
                        print(error)
                    
                    if error!.code == USER_NOT_FOUND {
                        
                        print("User not found. Attempting to create new user...")
                        
                        FIRAuth.auth()?.createUserWithEmail(email, password: pwd) { (user, error) in
                            
                            if error != nil {
                                
                                print(error)
                                self.showErrorAlert("Could not create account", msg: "Problem creating account. Try something else")
                            } else {
                                
                                FIRAuth.auth()?.signInWithEmail(email, password: pwd) { (user, error) in
                                    print("\(error)...here")
                                    NSUserDefaults.standardUserDefaults().setValue(user!.uid, forKey: KEY_UID)
                                    NSUserDefaults.standardUserDefaults().setValue(username, forKey: KEY_USERNAME)

                                    let userData = [
                                        "email": email,
                                        "username": username,
                                        "provider": FIREBASE,
                                        "user_ref": user!.uid
                                    ]
                                    UserService.ds.createFirebaseUser(user!.uid, user: userData)
                                    self.playIntroSound()
                                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                                }
                            }
                        }
                    } else if error!.code == PASSWORD_NOT_FOUND {
                        self.showErrorAlert("Could not login", msg: "Please check your username or password!")
                    }
                } else {
                    
                    NSUserDefaults.standardUserDefaults().setValue(user!.uid, forKey: KEY_UID)
                    NSUserDefaults.standardUserDefaults().setValue(username, forKey: KEY_USERNAME)
                    self.playIntroSound()
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
            }
        
        } else {
            showErrorAlert("Username or Password is Invalid!", msg: "Please check your credentials and try again.")
        }
        
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func playIntroSound() {
        
        let path = NSBundle.mainBundle().pathForResource("intro", ofType: "mp3")!
        
        do {
            introMusic = try AVAudioPlayer(contentsOfURL: NSURL(string: path)!)
            introMusic.prepareToPlay()
            introMusic.play()
            
        } catch let err as NSError {
            print(err.debugDescription)
        } catch {
            print("Error Could not play Sound!")
        }

    }
    

    
    

}

