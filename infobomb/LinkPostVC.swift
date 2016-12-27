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

class LinkPostVC: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var websitePreview: MaterialImgView!
    @IBOutlet weak var websiteTitle: UILabel!
    @IBOutlet weak var websiteShortUrl: UILabel!
    @IBOutlet weak var websiteDescription: UILabel!
    @IBOutlet weak var chooseCategories: MaterialButton!
    @IBOutlet weak var noPreviewAvailable: MaterialUIView!
    @IBOutlet weak var messageField: MaterialTextView!
    
    let slp = SwiftLinkPreview()
    let PLACEHOLDER_TEXT = "Enter Text..."
    
    var request: Request?
    var webTitle: String?
    var webDescription: String?
    var webImgUrl: String?
    var webCanonicalUrl: String?
    var webFinalUrl: String?
    var linkObj: [String:AnyObject] = [:]
    var linkData: Bool = false
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("LinkPostVC")
        //Subclass navigation bar after app is finished and all other non DRY
//        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
//        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
//        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!,NSForegroundColorAttributeName: LIGHT_GREY]
        
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

//        NotificationCenter.default.addObserver(self, selector: #selector(LinkPostVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(LinkPostVC.getPreview), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LinkPostVC.dismissKeyboard))
        //let tap2: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LinkPostVC.getPreview))
        view.addGestureRecognizer(tap)
        //view.addGestureRecognizer(tap2)
        
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
        
        applyPlaceholderStyle(aTextview: messageField!, placeholderText: PLACEHOLDER_TEXT)
        
        imageView.center = (imageView.superview?.center)!
        
        self.navigationItem.titleView = customView
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        //button.addTarget(self, action: #selector(LinkPostVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {

        getPreview()
        view.endEditing(true)
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
    func keyboardWillHide(_ notification: Notification) {
        
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
    
    func getPreview() {
        
        if textField.text != "" {
            
            slp.cancel()
                        
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
                        
                        self.request = Alamofire.request(imageUrl).validate(contentType: ["image/png", "image/jpg", "image/jpeg", "image/gif"]).response {  response in

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
                if let message = messageField.text! as String?, messageField.text != "" {
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
