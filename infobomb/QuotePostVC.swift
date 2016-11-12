//
//  QuotePostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/15/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

//disable image picker when typing on keyboard and re enable it when keyboard is dismissed

//REFACTOR TO PROMPT USER TO MAKE TEXT QUOTE OR IMAGE QUOTE SIMILAR TO VIDEO UPLOAD
class QuotePostVC: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var noImageView: UIView!
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var authorField: UITextField!
    
    let PLACEHOLDER_TEXT = "Enter Text Without Quotations..."
    let imagePicker = UIImagePickerController()
    
    var linkObj: [String:AnyObject] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("QuotePostVC")
        
        imagePicker.delegate = self
        textField.delegate = self
        authorField.delegate = self
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = PURPLE
        let logo = UIImage(named: "two-quotes.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        
        self.navigationItem.titleView = customView
        
        imagePicker.mediaTypes = ["public.image"]

        applyPlaceholderStyle(aTextview: textField!, placeholderText: PLACEHOLDER_TEXT)

        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        //        button.addTarget(self, action: #selector(AudioPostVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImagePostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)

        
    }
    
    @IBAction func pickImageBtnPressed(_ sender: AnyObject) {
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: "public.image") {
            
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                imagePreview.contentMode = .scaleAspectFill
                imagePreview.image = pickedImage
                textField.text = ""
                authorField.text = ""
                applyPlaceholderStyle(aTextview: textField!, placeholderText: PLACEHOLDER_TEXT)
                imagePreview.clipsToBounds = true
                imagePreview.layer.borderWidth = 1
                imagePreview.layer.borderColor = ANTI_FLASH_WHITE.cgColor
                noImageView.isHidden = true
                linkObj["image"] = UIImageJPEGRepresentation(pickedImage, 0.25) as AnyObject?
                linkObj["text"] = nil
                linkObj["author"] = nil
            }
            
        }
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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func moveCursorToStart(aTextView: UITextView)
    {
        DispatchQueue.main.async {
            aTextView.selectedRange = NSMakeRange(0, 0);
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField.text != "" {
            imagePreview.image = nil
            linkObj["image"] = nil
            noImageView.isHidden = false
            return true
        }
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if textView.text != "" {
            imagePreview.image = nil
            noImageView.isHidden = false
        }
        
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }

        let newLength = textView.text.utf16.count + text.utf16.count - range.length
        if newLength > 0 // have text, so don't show the placeholder
        {
            // check if the only text is the placeholder and remove it if needed
            // unless they've hit the delete button with the placeholder displayed
            if textView == textField && textView.text == PLACEHOLDER_TEXT
            {
                if text.utf16.count == 0 // they hit the back button
                {
                    return false // ignore it
                }
                applyNonPlaceholderStyle(aTextview: textView)
                textField.text = ""
            }
            return true
        }
        else  // no text, so show the placeholder
        {
            applyPlaceholderStyle(aTextview: textView, placeholderText: PLACEHOLDER_TEXT)
            moveCursorToStart(aTextView: textView)
            return false
        }
    }
    
    func dismissKeyboard() {
        
        view.endEditing(true)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
            if imagePreview.image == nil && (textField.text == "Enter Text Without Quotations..." || textField.text == "") {
                return false
            } else {
                return true
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if (segue.identifier == QUOTE_POST_VC) {
            
            let nav = segue.destination as! UINavigationController
            let categoryView = nav.topViewController as! CategoryVC
            
            if textField.text != "Enter Text Without Quotations..." {
                linkObj["text"] = textField.text! as NSString?
                
                if let author = authorField.text, authorField.text != "" {
                    linkObj["author"] = author as AnyObject?
                }
            }
            categoryView.previousVC = QUOTE_POST_VC
            categoryView.linkObj = self.linkObj

        }
 
    }
    
    @IBAction func unwindToQuotePost(_ segue: UIStoryboardSegue) {
        
    }

    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }
}
