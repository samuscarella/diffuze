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
        NSUserDefaults.standardUserDefaults().setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("TextPostVC")
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.Stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Text"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!,NSForegroundColorAttributeName: LIGHT_GREY]
        
        textImgView.separatorColor = UIColor.clearColor()
        textHeader.separatorColor = UIColor.clearColor()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TextPostVC.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TextPostVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TextPostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }
    
    override func viewDidAppear(animated: Bool) {
        print("TextPostVC")
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    

    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            if view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
            else {
                
            }
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            if view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height
            }
            else {
                
            }
        }
    }
    
    
    @IBAction func backBtnPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindToNewPost", sender: self)
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        if identifier == TEXT_POST_VC {
            if textField.text.isEmpty {
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if (segue.identifier == TEXT_POST_VC) {
            
            if let message = textField.text where message != "" {
                let nav = segue.destinationViewController as! UINavigationController;
                let categoryView = nav.topViewController as! CategoryVC
                categoryView.previousVC = TEXT_POST_VC
                categoryView.message = message
            }
        }
    }
    
    @IBAction func unwindToTextPost(segue: UIStoryboardSegue) {
        
    }
    
    
}
