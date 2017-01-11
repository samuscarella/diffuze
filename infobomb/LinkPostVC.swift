//
//  LinkPostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/2/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

//change preview call to after text changes start timer and then after x seconds call api

import UIKit
import SwiftLinkPreview
import Alamofire
import GeoFire
import FirebaseAuth

private var latitude = 0.0
private var longitude = 0.0

class LinkPostVC: UIViewController, UITextViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var websitePreview: MaterialImgView!
    @IBOutlet weak var websiteTitle: UILabel!
    @IBOutlet weak var websiteShortUrl: UILabel!
    @IBOutlet weak var websiteDescription: UILabel!
    @IBOutlet weak var chooseCategories: MaterialButton!
    @IBOutlet weak var noPreviewAvailable: MaterialUIView!
    @IBOutlet weak var messageField: MaterialTextView!
    
    var slp = SwiftLinkPreview()
    let PLACEHOLDER_TEXT = "Enter Text..."
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let iD = UserService.ds.currentUserID
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var request: Request?
    var webTitle: String?
    var webDescription: String?
    var webImgUrl: String?
    var webCanonicalUrl: String?
    var webFinalUrl: String?
    var linkObj: [String:AnyObject] = [:]
    var linkData: Bool = false
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    var notifications = [NotificationCustom]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("LinkPostVC")
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LinkPostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = FIRE_ORANGE
        let logo = UIImage(named: "link-1.png")
        let imageView = UIImageView(image:logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        messageField.delegate = self
        textField.delegate = self
        
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        notificationService = NotificationService()
        notificationService.getNotifications()
        notificationService.watchRadar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotifications), name: NSNotification.Name(rawValue: "newFollowersNotification"), object: nil)

        locationService = LocationService()
        locationService.startTracking()
        
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        applyPlaceholderStyle(aTextview: messageField!, placeholderText: PLACEHOLDER_TEXT)
        
        imageView.center = (imageView.superview?.center)!
        
        self.navigationItem.titleView = customView
        
        dot = UIView(frame: CGRect(x: 14, y: 16, width: 12, height: 12))
        dot.backgroundColor = UIColor.red
        dot.layer.cornerRadius = dot.frame.size.height / 2
        dot.isHidden = true
        dot.isUserInteractionEnabled = false
        dot.isExclusiveTouch = false
        dot.isHidden = true

        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(self.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        button.addSubview(dot)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func popoverDismissed() {
        
        notificationService.getNotifications()
    }
    
    func updateNotifications(notification: NSNotification) {
        
        self.notifications = []
        let incomingNotifications = notification.object as! [NotificationCustom]
        self.notifications = incomingNotifications
        var newNotifications = false
        for n in notifications {
            if n.read == false {
                newNotifications = true
                dot.isHidden = false
                break
            }
        }
        if !newNotifications {
            dot.isHidden = true
        }
        print("Updated Notifications From Followers: \(self.notifications)")
    }
    
    func notificationBtnPressed() {
        
        let notificationVC = self.storyboard?.instantiateViewController(withIdentifier: "NotificationVC") as! NotificationVC
        notificationVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        notificationVC.notifications = self.notifications
        present(notificationVC, animated: true, completion: nil)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        
        timer?.invalidate()
    }
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }

    func dismissKeyboard() {

        getPreview()
        view.endEditing(true)
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        timer?.invalidate()
        
        if(string == "\n") {
            textField.resignFirstResponder()
            return false
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.getPreview), userInfo: nil, repeats: false)

        return true
    }
    
    func applyPlaceholderStyle(aTextview: UITextView, placeholderText: String)
    {

        aTextview.textColor = UIColor.lightGray
        aTextview.text = placeholderText
        aTextview.textAlignment = .center
    }
    
    func applyNonPlaceholderStyle(aTextview: UITextView)
    {

        aTextview.textColor = UIColor.darkText
        aTextview.alpha = 1.0
        aTextview.textAlignment = .left
    }
    
    func textViewShouldBeginEditing(_ aTextView: UITextView) -> Bool {
        
        if aTextView == messageField && aTextView.text == PLACEHOLDER_TEXT
        {
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

    func verifyUrl (urlString: String?) -> Bool {
        //Check for nil
        if let urlString = urlString {
            // create NSURL instance
            if let url = NSURL(string: urlString) {
                // check if your application can open the NSURL instance
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    func validUrl(textField: String) -> Bool {
        
        if verifyUrl(urlString: textField) {
            return true
        }
        return false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            textView.resignFirstResponder()
            getPreview()
            return false
        }
        
        let newLength = textView.text.utf16.count + text.utf16.count - range.length
        if newLength > 0 {
            if textView == messageField && textView.text == PLACEHOLDER_TEXT {
                if text.utf16.count == 0 {
                    return false
                }
                applyNonPlaceholderStyle(aTextview: textView)
                messageField.text = ""
            }
            return true
        } else{
            applyPlaceholderStyle(aTextview: textView, placeholderText: PLACEHOLDER_TEXT)
            moveCursorToStart(aTextView: textView)
            return false
        }
    }
    
    func cancelPreviewRequest() {
        slp.cancel()
    }
    
    func getPreview() {
        
        if textField.text != "" {
            
            slp.cancel()

            timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.cancelPreviewRequest), userInfo: nil, repeats: false)

            slp.preview(
                textField.text,
                onSuccess: { result in
                    
                    print("Getting Preview...\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
                    print("\(result)")
                    
                    self.linkObj.removeAll()
                    self.websiteTitle.text = ""
                    self.websiteDescription.text = ""
                    self.websitePreview.image = nil
                    self.websiteShortUrl.text = ""

                    self.linkData = false
                    
                    if let url = result["url"] as? String, url != "" {
                        self.linkObj["url"] = url as AnyObject?
                    }
                    if let webFinalUrl = result["finalUrl"] as? String, webFinalUrl != "" {
                        self.linkObj["finalUrl"] = webFinalUrl as AnyObject?
                    }
                    if let webTitle = result["title"] as? String, webTitle != "" {
                        self.websiteTitle.text = webTitle
                        self.linkObj["title"] = webTitle as AnyObject?
                        self.linkData = true
                    }
                    if let webDescription = result["description"] as? String, webDescription != "" {
                        self.websiteDescription.text = webDescription
                        self.linkObj["description"] = webDescription as AnyObject?
                        self.linkData = true
                    }
                    if let webCanonicalUrl = result["canonicalUrl"] as? String, webCanonicalUrl != "" {
                        self.websiteShortUrl.text = webCanonicalUrl
                        self.linkObj["canonicalUrl"] = webCanonicalUrl as AnyObject?
                    }
                    if let imageUrl = result["image"] as? String, imageUrl != ""  {
                        
                        self.request = Alamofire.request(imageUrl).validate(contentType: ["image/png", "image/jpg", "image/jpeg", "image/gif", "image/svg"]).response {  response in

                            if response.error == nil {
                                if let imgData = response.data as Data? {
                                    
                                    if imgData.count == 0 {
                                        self.websitePreview.isHidden = false
                                        self.websitePreview.image = UIImage(named: "no-image")
                                    } else {
                                        let img = UIImage(data: imgData as Data)!
                                        self.websitePreview.isHidden = false
                                        self.websitePreview.image = img
                                        self.linkObj["image"] = imgData as AnyObject?
                                        self.linkData = true
                                    }
                                }
                            } else {
                                print("Image Preview Error: \(response.error)")
                                self.websitePreview.isHidden = false
                                self.websitePreview.image = UIImage(named: "no-image")
                            }
                            
                            print("\(self.linkObj["title"])\n\n\n\n")
                            print("\(self.linkObj["description"])\n\n\n\n")
                            print("\(self.linkObj["image"])\n\n\n\n")
                            print("\(self.linkObj["canonicalUrl"])\n\n\n\n")
                            print("\(self.linkObj["url"])\n\n\n\n")
                        }
                    } else {
                        if self.linkData {
                            print("\(self.linkObj["title"])\n\n\n\n")
                            print("\(self.linkObj["description"])\n\n\n\n")
                            print("\(self.linkObj["image"])\n\n\n\n")
                            print("\(self.linkObj["canonicalUrl"])\n\n\n\n")
                            print("\(self.linkObj["url"])\n\n\n\n")
                        }
                        self.websitePreview.isHidden = false
                        self.websitePreview.image = UIImage(named: "no-image")
                        self.websitePreview.isHidden = true
                    }
                    if self.linkData {
                        self.noPreviewAvailable.isHidden = true
                    } else {
                        self.noPreviewAvailable.isHidden = false
                    }
                    
                },
                onError: { error in
                    print("Could not get preview: \(error)")
                    self.linkObj.removeAll()
                    self.linkData = false
                    self.noPreviewAvailable.isHidden = false
                }
            )

        } else {
            self.noPreviewAvailable.isHidden = false
            print("There is no text entered.")
        }
        
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        dismissKeyboard()
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
         if identifier == LINK_POST_VC {
            if linkData == false {
                return false
            } else {
                return true
            }
         }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
         if (segue.identifier == LINK_POST_VC) {
         
            if self.linkData {
                let nav = segue.destination as! UINavigationController;
                let categoryView = nav.topViewController as! CategoryVC
                if let message = messageField.text! as String?, messageField.text != "" || messageField.text != "Enter Text..." {
                    linkObj["message"] = message as AnyObject?
                }
                categoryView.previousVC = LINK_POST_VC
                categoryView.linkObj = self.linkObj
                slp.cancel()
            }
         }
 
    }
    
    @IBAction func unwindToLinkPost(_ segue: UIStoryboardSegue) {
        
    }
 


}
