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
    
    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var loginBtn: UIButton!
    
    var introMusic: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signUpBtn.layer.cornerRadius = 3
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("Sign In View Did Appear...")
        
        if UserDefaults.standard.value(forKey: KEY_UID) != nil {
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
    
    @IBAction func unwindToMainScreen(_ segue: UIStoryboardSegue) {
        
    }


    

}

