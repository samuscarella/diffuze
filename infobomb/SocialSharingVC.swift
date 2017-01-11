//
//  SocialSharingVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 1/9/17.
//  Copyright © 2017 samuscarella. All rights reserved.
//

import UIKit
import FacebookShare
import Alamofire

class SocialSharingVC: UIViewController {

    @IBOutlet weak var sharingView: UIView!
    
    var post: Post!
    var img: UIImage?
    var photo: Photo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharingView.layer.cornerRadius = 3.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ModalTransitionMediator.instance.sendPopoverDismissed(modelChanged: true)
    }
    
    @IBAction func shareOnFacebookBtnPressed(_ sender: AnyObject) {
        
        print(post.image)
        
        if post.type == "image" {
            
            img = ActivityVC.imageCache.object(forKey: post.image as AnyObject) as? UIImage
            
            if img != nil {
                
                photo = Photo(image: img!, userGenerated: true)
                
                let content = PhotoShareContent(photos: [photo!])
                
                let shareDialog = ShareDialog(content: content)
                shareDialog.mode = .native
                shareDialog.failsOnInvalidData = true
                shareDialog.completion = { result in
                    print(result)
                }
                
                do {
                    try ShareDialog.show(from: self, content: content)
                } catch let err as NSError {
                    print(err.debugDescription)
                }

            } else {
                
                Alamofire.request(post.image!, method: .get).response { response in
                    if response.error == nil {
                        
                        let img = UIImage(data: response.data!)
                        self.photo = Photo(image: img!, userGenerated: true)
                        
                        let content = PhotoShareContent(photos: [self.photo!])
                        
                        let shareDialog = ShareDialog(content: content)
                        shareDialog.mode = .native
                        shareDialog.failsOnInvalidData = true
                        shareDialog.completion = { result in
                            print(result)
                        }
                        
                        do {
                            try shareDialog.show()
                        } catch let err as NSError {
                            print(err.debugDescription)
                        }
                        
                    } else {
                        print("\(response.error)")
                    }
                }
            }
        }
    }
    
    @IBAction func shareOnTwitterBtnPressed(_ sender: AnyObject) {
        
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
     
        dismiss(animated: true, completion: nil)
    }
}
