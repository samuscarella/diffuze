//
//  LinkPostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/2/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import SwiftLinkPreview
import Alamofire

class LinkPostVC: UIViewController {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var linkHeaderView: MaterialView!
    @IBOutlet weak var linkHeader: MaterialView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var websitePreview: MaterialImgView!
    @IBOutlet weak var websiteTitle: UILabel!
    @IBOutlet weak var websiteShortUrl: UILabel!
    @IBOutlet weak var websiteDescription: UILabel!
    @IBOutlet weak var chooseCategories: MaterialButton!
    @IBOutlet weak var noPreviewAvailable: MaterialUIView!
    
    let slp = SwiftLinkPreview()
    
    var request: Request?
    var webTitle: String?
    var webDescription: String?
    var webImgUrl: String?
    var webCanonicalUrl: String?
    var webFinalUrl: String?
    var linkObj: [String:AnyObject] = [:]
    
    var linkData: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("LinkPostVC")
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.title = "Link"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!,NSForegroundColorAttributeName: LIGHT_GREY]
        
//        NotificationCenter.default.addObserver(self, selector: #selector(LinkPostVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LinkPostVC.getPreview), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        
        linkHeaderView.separatorColor = UIColor.clear
        linkHeader.separatorColor = UIColor.clear
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LinkPostVC.dismissKeyboard))
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
    
    func getPreview() {
        
        if textField.text != "" {
            
            slp.cancel()
            
            slp.preview(
                textField.text,
                onSuccess: { result in
                    
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
                        
                        self.request = Alamofire.request(imageUrl).validate(contentType: ["image/*"]).response {  response in
                            
                            if response.error == nil {
                                let img = UIImage(data: response.data!)!
                                self.websitePreview.isHidden = false
                                self.websitePreview.image = img
                                self.linkObj["image"] = response.data! as NSData?
                                self.linkData = true
                            } else {
                                print("Image Preview Error: \(response.error)")
                                //add stock no image photo
                                self.websitePreview.isHidden = true
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
                categoryView.previousVC = LINK_POST_VC
                categoryView.linkObj = self.linkObj
            }
         }
 
    }
    
    @IBAction func unwindToLinkPost(_ segue: UIStoryboardSegue) {
        
    }
 


}
