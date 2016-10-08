//
//  TextPostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/11/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class TextPostVC: UIViewController, UITextViewDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var textImgView: MaterialView!
    @IBOutlet weak var textField: MaterialTextView!
    @IBOutlet weak var textHeader: MaterialView!
    @IBOutlet weak var chooseCategoriesBtn: MaterialButton!
    
    var message: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("TextPostVC")
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.title = "Text"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!,NSForegroundColorAttributeName: LIGHT_GREY]
        
        textImgView.separatorColor = UIColor.clear
        textHeader.separatorColor = UIColor.clear
        
//        NotificationCenter.default.addObserver(self, selector: #selector(TextPostVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(TextPostVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TextPostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    

//    func keyboardWillShow(_ notification: Notification) {
//        
//        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
//            if view.frame.origin.y == 0 {
//                self.view.frame.origin.y -= keyboardSize.height
//            }
//            else {
//                
//            }
//        }
//        
//    }
//    
//    func keyboardWillHide(_ notification: Notification) {
//        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
//            if view.frame.origin.y != 0 {
//                self.view.frame.origin.y += keyboardSize.height
//            }
//            else {
//                
//            }
//        }
//    }
    
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == TEXT_POST_VC {
            if textField.text.isEmpty {
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if (segue.identifier == TEXT_POST_VC) {
            
            if let message = textField.text , message != "" {
                let nav = segue.destination as! UINavigationController;
                let categoryView = nav.topViewController as! CategoryVC
                categoryView.previousVC = TEXT_POST_VC
                categoryView.message = message
            }
        }
    }
    
    @IBAction func unwindToTextPost(_ segue: UIStoryboardSegue) {
        
    }
    
    
}
