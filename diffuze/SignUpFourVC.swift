//
//  SignUpFourVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/24/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import SCLAlertView

class SignUpFourVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    static var imageCache = NSCache<AnyObject, AnyObject>()
    
    var email: String!
    var username: String!
    var password: String!
    var introMusic: AVAudioPlayer!
    var didJustLogIn = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        self.emailLbl.text = email!
        self.usernameLbl.text = username!
        self.passwordLbl.text = "******"
        
        imagePicker.delegate = self
    }
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString

        if mediaType.isEqual(to: "public.image") {

            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                photoImageView.layer.cornerRadius = photoImageView.frame.size.height / 2
                photoImageView.clipsToBounds = true
                photoImageView.contentMode = .scaleAspectFill
                photoImageView.image = pickedImage
                photoImageView.clipsToBounds = true
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
    
    @IBAction func pickPhotoBtnPressed(_ sender: AnyObject) {
        
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false

        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func finalizeBtnPressed(_ sender: AnyObject) {
     
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
            
            if error != nil {
                
                let alertView = SCLAlertView()
                
                alertView.showError("Error", subTitle: "\nCould not create account. Please try something else.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
                alertView.view.frame.origin.y -= 90
            } else {
                
                FIRAuth.auth()?.signIn(withEmail: self.email, password: self.password) { (user, error) in
                    
                    let user = FIRAuth.auth()?.currentUser
                    
                    let subscriptions = ["All":true]
                    
                    var userData = [
                        "email": self.email,
                        "username": self.username,
                        "provider": FIREBASE,
                        "user_id": user!.uid,
                        "subscriptions": subscriptions
                    ] as [String : Any]
                    
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
                    
                    if let userPhoto = self.photoImageView.image, self.photoImageView.image != nil {
                        
                        let uniqueString = NSUUID().uuidString
                        
                        let imageRef = storageRef.child("images/user_photo/image_\(uniqueString)")
                        
                        let img = UIImageJPEGRepresentation(userPhoto, 0.25) as AnyObject?
                        
                        let uploadTask = imageRef.put(img as! Data, metadata: nil) { metadata, error in
                            if (error != nil) {
                                
                                print("Failed to upload image to firebase")
                            } else {
                                
                                let downloadURL = metadata!.downloadURL()!.absoluteString
                                
                                userData["photo"] = downloadURL

                                UserService.ds.createFirebaseUser(user!.uid, user: userData)
                                
                                UserDefaults.standard.setValue(user!.uid, forKey: KEY_UID)
                                UserDefaults.standard.setValue(self.username, forKey: KEY_USERNAME)
                                                                
                                self.playIntroSound()
                                self.performSegue(withIdentifier:SEGUE_LOGGED_IN, sender: self.didJustLogIn)
                            }
                        }
                    } else {
                        
                        UserDefaults.standard.setValue(user!.uid, forKey: KEY_UID)
                        UserDefaults.standard.setValue(self.username, forKey: KEY_USERNAME)
                        
                        self.playIntroSound()
                        self.performSegue(withIdentifier:SEGUE_LOGGED_IN, sender: self.didJustLogIn)
                    }
                }
            }
        }
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "unwindToSignUpThree", sender: self)
    }
}
