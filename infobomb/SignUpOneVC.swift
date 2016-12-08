//
//  SignUpOneVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/7/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class SignUpOneVC: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var continueBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        emailField.attributedPlaceholder = NSAttributedString(string: "Email", attributes:[NSForegroundColorAttributeName: UIColor.lightGray])
        
        continueBtn.layer.cornerRadius = 3
    }

    @IBAction func stopBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "GoToMainScreen", sender: self)
    }
    
    @IBAction func unwindToSignUpOne(_ segue: UIStoryboardSegue) {
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {

        if emailField.text != "" {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        
        let nav = segue.destination as! UINavigationController;
        let usernameView = nav.topViewController as! SignUpTwoVC
        usernameView.email = emailField.text!
        
    }
    
}
