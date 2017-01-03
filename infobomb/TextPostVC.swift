//
//  TextPostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/11/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import GeoFire
import FirebaseAuth

private var latitude: Double = 0.0
private var longitude: Double = 0.0

class TextPostVC: UIViewController, UITextViewDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var textField: MaterialTextView!
    @IBOutlet weak var chooseCategoriesBtn: MaterialButton!
    @IBOutlet weak var chooseCategoriesBtnBottomConstraint: NSLayoutConstraint!
    
    let PLACEHOLDER_TEXT = "Enter Text..."
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let iD = UserService.ds.currentUserID
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var message: String!
    var linkObj: [String:AnyObject] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = AUBURN_RED
        let logo = UIImage(named: "font.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!

        self.navigationItem.titleView = customView
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        textField.delegate = self

        applyPlaceholderStyle(aTextview: textField!, placeholderText: PLACEHOLDER_TEXT)
        NotificationCenter.default.addObserver(self, selector: #selector(TextPostVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TextPostVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TextPostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.chooseCategoriesBtnBottomConstraint.constant = 0
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &latitude {
            latitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["latitude"] = latitude as AnyObject?
        }
        if context == &longitude {
            longitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["longitude"] = longitude as AnyObject?
        }
    }
    
    func updateUserLocation() {
        
        if currentLocation["latitude"] != nil && currentLocation["longitude"] != nil {
            
            geoFire.setLocation(CLLocation(latitude: (currentLocation["latitude"] as? CLLocationDegrees)!, longitude: (currentLocation["longitude"] as? CLLocationDegrees)!), forKey: iD)
            
            if UserService.ds.REF_USER_CURRENT != nil {
                let longRef = UserService.ds.REF_USER_CURRENT?.child("longitude")
                let latRef = UserService.ds.REF_USER_CURRENT?.child("latitude")
                
                longRef?.setValue(currentLocation["longitude"])
                latRef?.setValue(currentLocation["latitude"])
            }
            print(currentLocation)
        }
    }
    
    func terminateAuthentication() {
        
        do {
            try FIRAuth.auth()!.signOut()
            self.performSegue(withIdentifier: "unwindToLoginVC", sender: self)
        } catch let err as NSError {
            print(err)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        timer?.invalidate()
    }
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
            return .lightContent
    }

    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func applyPlaceholderStyle(aTextview: UITextView, placeholderText: String)
    {
        // make it look (initially) like a placeholder
        aTextview.textColor = UIColor.lightGray
        aTextview.text = placeholderText
        aTextview.textAlignment = .center
    }
    
    func applyNonPlaceholderStyle(aTextview: UITextView)
    {
        // make it look like normal text instead of a placeholder
        aTextview.textColor = UIColor.darkText
        aTextview.alpha = 1.0
        aTextview.textAlignment = .left
    }
    
    
    func textViewShouldBeginEditing(_ aTextView: UITextView) -> Bool {
        if aTextView == textField && aTextView.text == PLACEHOLDER_TEXT
        {
            // move cursor to start
            moveCursorToStart(aTextView: aTextView)
        }
        return true
    }
    
    func moveCursorToStart(aTextView: UITextView)
    {
        DispatchQueue.main.async {
            aTextView.selectedRange = NSMakeRange(0, 0);
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        if(text == "\n") {
            textView.resignFirstResponder()
            self.chooseCategoriesBtnBottomConstraint.constant = 0
            return false
        }

        let newLength = textView.text.utf16.count + text.utf16.count - range.length
        if newLength > 0 {
            if textView == textField && textView.text == PLACEHOLDER_TEXT {
                if text.utf16.count == 0 {
                    return false
                }
                applyNonPlaceholderStyle(aTextview: textView)
                textField.text = ""
            }
            return true
        } else{
            applyPlaceholderStyle(aTextview: textView, placeholderText: PLACEHOLDER_TEXT)
            moveCursorToStart(aTextView: textView)
            return false
        }
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
               self.chooseCategoriesBtnBottomConstraint.constant = keyboardSize.height
                UIView.animate(withDuration: 0.9) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y != 0 {
                self.chooseCategoriesBtnBottomConstraint.constant = keyboardSize.height
                UIView.animate(withDuration: 0.9) {
                    self.view.layoutIfNeeded()
                }

            }
            else {
                
            }
        }
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        dismissKeyboard()
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == TEXT_POST_VC {
            if textField.text.isEmpty || textField.text == "Enter Text..." {
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if (segue.identifier == TEXT_POST_VC) {
            
            if let message = textField.text, message != "" {
                self.linkObj["message"] = message as AnyObject?
                self.chooseCategoriesBtnBottomConstraint.constant = 0
                self.chooseCategoriesBtn.updateConstraints()
                let nav = segue.destination as! UINavigationController
                let categoryView = nav.topViewController as! CategoryVC
                categoryView.previousVC = TEXT_POST_VC
                categoryView.linkObj = linkObj
            }
        }
    }
    
    @IBAction func unwindToTextPost(_ segue: UIStoryboardSegue) {
        
    }
    
    
}
