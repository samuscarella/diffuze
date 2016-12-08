//
//  SignUpTwoVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/7/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class SignUpTwoVC: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var continueBtn: UIButton!
    
    var email: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        usernameField.attributedPlaceholder = NSAttributedString(string: "Username", attributes:[NSForegroundColorAttributeName: UIColor.lightGray])
        
        continueBtn.layer.cornerRadius = 3

    }

    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "GoToSignUpOne", sender: self)
    }
    
    @IBAction func unwindToSignUpTwo(_ segue: UIStoryboardSegue) {
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if usernameField.text != "" {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        
        let nav = segue.destination as! UINavigationController;
        let usernameView = nav.topViewController as! SignUpThreeVC
        usernameView.username = usernameField.text!
        usernameView.email = email
        
    }

}
