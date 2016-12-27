//
//  ImagePostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/8/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import AVFoundation

class ImagePostVC: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UIImagePickerControllerDelegate {
    
    
    @IBOutlet weak var noMediaImg: UIImageView!
    @IBOutlet weak var chooseMediaIcon: UIImageView!
    @IBOutlet weak var videoView: VideoContainerView!
    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: MaterialTextView!
    @IBOutlet weak var noImageView: MaterialUIView!
    @IBOutlet weak var pickImgBtn: UIButton!
    @IBOutlet weak var chooseCategoriesBtn: MaterialButton!
    @IBOutlet weak var uploadText: UILabel!
    @IBOutlet weak var chooseImgIcon: UIImageView!
    
    let PLACEHOLDER_TEXT = "Enter Text..."
    let imagePicker = UIImagePickerController()
    
    var videoLayer: AVPlayerLayer?
    var player: AVPlayer?
    var linkObj: [String:AnyObject] = [:]
    var videoPath: NSURL? = NSURL(string: "")!
    var previousVC: String!
    var fileExtension: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("ImagePostVC")
        //Subclass navigation bar after app is finished and all other non DRY
//        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!,NSForegroundColorAttributeName: LIGHT_GREY]
        
        imagePicker.delegate = self
        textField.delegate = self
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        chooseImgIcon.isHidden = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        
        let logo: UIImage!

        if previousVC == NEW_IMAGE_POST {
            customView.backgroundColor = GOLDEN_YELLOW
            logo = UIImage(named: "photo-camera.png")
//            imageIconView.backgroundColor = GOLDEN_YELLOW
            chooseCategoriesBtn.backgroundColor = GOLDEN_YELLOW
            uploadText.text = "Upload Image"
            noMediaImg.image = UIImage(named: "no-photo-grey")
        } else {
            customView.backgroundColor = DARK_GREEN
            logo = UIImage(named: "video-camera.png")
//            imageIconView.backgroundColor = DARK_GREEN
            chooseCategoriesBtn.backgroundColor = DARK_GREEN
            uploadText.text = "Upload Video"
            noMediaImg.image = UIImage(named: "no-video")
        }
        
        let imageView = UIImageView(image: logo)
        if previousVC == NEW_IMAGE_POST {
            imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        } else {
            imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        }
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        
        self.navigationItem.titleView = customView

        
        applyPlaceholderStyle(aTextview: textField!, placeholderText: PLACEHOLDER_TEXT)
        
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton

        
        //NotificationCenter.default.addObserver(self, selector: #selector(LinkPostVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImagePostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    @IBAction func pickImgBtnPressed(_ sender: AnyObject) {
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        
        if previousVC == NEW_IMAGE_POST {
            imagePicker.mediaTypes = ["public.image"]
        } else if previousVC == NEW_VIDEO_POST {
            imagePicker.mediaTypes = ["public.movie"]
        }
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: "public.image") {
            
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                imageView.contentMode = .scaleAspectFill
                imageView.image = pickedImage
                imageView.clipsToBounds = true
                chooseImgIcon.isHidden = false
                noImageView.isHidden = true
                videoView.isHidden = false
                linkObj["image"] = UIImageJPEGRepresentation(pickedImage, 0.25) as AnyObject?
            }
            
        } else if mediaType.isEqual(to: "public.movie") {
            
            if let videoURL = info["UIImagePickerControllerMediaURL"] as? NSURL {
             
                let asset = AVURLAsset(url: videoURL as URL, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                
                if let fileExt = videoURL.pathExtension {
                    self.fileExtension = fileExt
                }
                
                var imgPreview: NSData?
                
                do {
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                    let uiImage = UIImage(cgImage: cgImage, scale: CGFloat(1.0), orientation: .right)
                    self.imageView.image = uiImage
                    self.imageView.clipsToBounds = true
                    imgPreview = UIImagePNGRepresentation(uiImage) as NSData?
                    self.linkObj["thumbnail"] = imgPreview
                } catch let err as NSError {
                    print(err.debugDescription)
                }
                
                player = AVPlayer(url: videoURL as URL)
                self.videoLayer = AVPlayerLayer(player: player)
                self.videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.videoLayer?.frame = videoView.bounds
                self.videoView.layer.addSublayer(videoLayer!)
                self.videoView.playerLayer = videoLayer
                self.videoView.bringSubview(toFront: self.chooseMediaIcon)
                self.videoView.isHidden = false
                self.imageView.isHidden = true
                player!.play()
                if let videoData = NSData(contentsOf: videoURL as URL) {
                    self.linkObj["video"] = videoData
                }
            }
        }
    }
    
//    if let videoURL = videoURL{
//        
//        let player = AVPlayer(URL: videoURL)
//        
//        let playerViewController = AVPlayerViewController()
//        playerViewController.player = player
//        
//        presentViewController(playerViewController, animated: true){
//            playerViewController.player!.play()
//        }
//    }
    
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        // remove the placeholder text when they start typing
        // first, see if the field is empty
        // if it's not empty, then the text should be black and not italic
        // BUT, we also need to remove the placeholder text if that's the only text
        // if it is empty, then the text should be the placeholder
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
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        dismissKeyboard()
        if previousVC == NEW_IMAGE_POST {
            self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
        } else if previousVC == NEW_VIDEO_POST {
            self.performSegue(withIdentifier: "unwindToVideoUploadOption", sender: self)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if previousVC == NEW_IMAGE_POST {
            if imageView.image == nil || linkObj["image"] == nil {
                return false
            } else {
                return true
            }
        } else if previousVC == NEW_VIDEO_POST {
            if linkObj["video"] == nil {
                print("Video is nil")
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if (segue.identifier == IMAGE_POST_VC) {
            
            if previousVC == NEW_IMAGE_POST {
            
                    let nav = segue.destination as! UINavigationController;
                    let categoryView = nav.topViewController as! CategoryVC
                    if textField.text != "" && textField.text != "Enter Text..." {
                        linkObj["text"] = textField.text! as AnyObject?
                    }
                    categoryView.previousVC = IMAGE_POST_VC
                    categoryView.linkObj = self.linkObj
                
            } else if previousVC == NEW_VIDEO_POST {
                
                let nav = segue.destination as! UINavigationController;
                let categoryView = nav.topViewController as! CategoryVC
                if textField.text != "" && textField.text != "Enter Text..." {
                    linkObj["text"] = textField.text! as AnyObject?
                }
                categoryView.previousVC = VIDEO_POST_VC
                categoryView.linkObj = self.linkObj
                
                if self.fileExtension != nil {
                    categoryView.fileExtension = self.fileExtension
                }
                
            }
        }
        
    }
    
    @IBAction func unwindToImagePost(_ segue: UIStoryboardSegue) {
        
    }

}
