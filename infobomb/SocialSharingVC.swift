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
import Social
import SCLAlertView
import TwitterKit

class SocialSharingVC: UIViewController {

    @IBOutlet weak var sharingView: UIView!
    
    var post: Post!
    var img: UIImage?
    var imgURL: URL?
    var message: String?
    var descrip: String?
    var url: URL?
    var linkTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharingView.layer.cornerRadius = 3.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ModalTransitionMediator.instance.sendPopoverDismissed(modelChanged: true)
    }
    
    func shareImageToFacebook(img: UIImage) {
        
        let photo = Photo(image: img, userGenerated: true)
        let content = PhotoShareContent(photos: [photo])
        
        let shareDialog = ShareDialog(content: content)
        shareDialog.mode = .native
        shareDialog.failsOnInvalidData = true
        
        shareDialog.completion = { result in
            
            print("\n\nFacebook Video Share Result: \n\n\(result)")
        }
        
        do {
            try shareDialog.show()
        } catch let err as NSError {
            print("Video Share Error: \(err.debugDescription)")
        }
    }
    
    func shareLinkToFacebook(description: String?, imageURL: URL?, url: URL, title: String?, quote: String?) {
        
        
        let content = LinkShareContent(url: url, title: title, description: description, quote: quote, imageURL: imageURL)
        
        do {
            try ShareDialog.show(from: self, content: content)
        } catch let err as NSError {
            
            if err.code == 0 {
                
                let alertView = SCLAlertView()
                
                alertView.showError("Error", subTitle: "Unable to share link to facebook", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            }
            print("Link Share Error: \(err.debugDescription)")
        }
    }
    
    func tweetOnTwitter(message: String?, image: UIImage?, url: URL?) {
        
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) {
            
            let tweeter: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            
            if message != nil {
                tweeter.setInitialText(message)
            }
            
            if image != nil {
                tweeter.add(image)
            }
            
            if url != nil {
                tweeter.add(url)
            }
            
            self.present(tweeter, animated: true, completion: nil)
            
        } else {
            
            let alertView = SCLAlertView()
            
            alertView.showError("Accounts", subTitle: "Please login to a Twitter account to tweet.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
        }
    }
    
    func shareWithProvider(provider: String) {
        
        if post.type == "image" {
            
            if let msg = post.message {
                self.message = msg
            }
            
            img = ActivityVC.imageCache.object(forKey: post.image as AnyObject) as? UIImage
            
            if img != nil {
                
                if provider == FACEBOOK {
                    shareImageToFacebook(img: img!)
                } else if provider == TWITTER {
                    tweetOnTwitter(message: message, image: img, url: nil)
                }
                
            } else {
                
                Alamofire.request(post.image!, method: .get).response { response in
                    if response.error == nil {
                        
                        let img = UIImage(data: response.data!)
                        
                        if provider == FACEBOOK {
                            self.shareImageToFacebook(img: img!)
                        } else if provider == TWITTER {
                            self.tweetOnTwitter(message: self.message, image: img, url: nil)
                        }
                    } else {
                        print("\(response.error)")
                    }
                }
            }
        } else if post.type == "text" {
            
            self.message = post.message
            
            if provider == FACEBOOK {

                let alertView = SCLAlertView()
                
                alertView.showError("Error", subTitle: "Text sharing not supported.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            } else if provider == TWITTER {
                tweetOnTwitter(message: message, image: nil, url: nil)
            }
        } else if post.type == "link" {
            
            if let msg = post.message {
                self.message = msg
            }
            
            if let urlString = post.url {
                let url = URL(string: urlString)
                self.url = url
            }
            
            if let title = post.title {
                self.linkTitle = title
            }
            
            if let description = post.descrip {
                self.descrip = description
            }
            
            if let image = post.image {
                let url = URL(string: image)
                self.imgURL = url
            }
            
            if provider == FACEBOOK {
                self.shareLinkToFacebook(description: descrip, imageURL: imgURL, url: url!, title: linkTitle, quote: nil)
            } else if provider == TWITTER {
                
                if post.image == nil {
                    self.tweetOnTwitter(message: message, image: nil, url: self.url)
                } else  {
                    
                    img = ActivityVC.imageCache.object(forKey: post.image as AnyObject) as? UIImage
                    
                    if img != nil {
                        tweetOnTwitter(message: message, image: img, url: self.url)
                    } else {
                        
                        Alamofire.request(post.image!, method: .get).response { response in
                            
                            if response.error == nil {
                                
                                let img = UIImage(data: response.data!)

                                self.tweetOnTwitter(message: self.message, image: img, url: self.url)
                                
                            } else {
                                print("\(response.error)")
                            }
                        }
                    }
                }
            }
        } else if post.type == "quote" {
            
            if post.quoteType == "text" {
                
                if let msg = post.text {
                    
                    self.message = msg
                    
                    if provider == FACEBOOK {

                        let alertView = SCLAlertView()
                        
                        alertView.showError("Error", subTitle: "Text sharing not supported.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
                    
                    } else if provider == TWITTER {
                        tweetOnTwitter(message: message, image: nil, url: nil)
                    }
                }
            } else if post.quoteType == "image" {
                
                img = ActivityVC.imageCache.object(forKey: post.image as AnyObject) as? UIImage
                
                if img != nil {
                    
                    if provider == FACEBOOK {
                        shareImageToFacebook(img: img!)
                    } else if provider == TWITTER {
                        tweetOnTwitter(message: nil, image: img, url: nil)
                    }
                } else {
                    
                    Alamofire.request(post.image!, method: .get).response { response in
                        
                        if response.error == nil {
                            
                            let img = UIImage(data: response.data!)
                            
                            if provider == FACEBOOK {
                                self.shareImageToFacebook(img: img!)
                            } else if provider == TWITTER {
                                self.tweetOnTwitter(message: nil, image: img, url: nil)
                            }
                        } else {
                            print("\(response.error)")
                        }
                    }
                }
            }
        } else if post.type == "video" {
            
            if provider == FACEBOOK {
            
                let url = URL(string: post.video!)
                let video = Video(url: url!)
                let content = VideoShareContent(video: video)

                do {
                    try ShareDialog.show(from: self, content: content)
                } catch let err as NSError {
                    if err.code == 0 {
                        
                        let alertView = SCLAlertView()
                        
                        alertView.showError("Error", subTitle: "Video failed to share.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
                    }
                    print("Video Share Error: \(err.debugDescription)")
                }
            } else if provider == TWITTER {
                
                let alertView = SCLAlertView()
                
                alertView.showError("Error", subTitle: "Video sharing with Twitter is not yet supported.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
            }
        } else if post.type == "audio" {
            
            let alertView = SCLAlertView()
            
            alertView.showError("Error", subTitle: "Audio cannot be shared on any 3rd party platforms yet.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xff0000, colorTextButton: 0xffffff, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
        }
    }
    
    @IBAction func shareOnFacebookBtnPressed(_ sender: AnyObject) {
        
        shareWithProvider(provider: FACEBOOK)
    }
    
    @IBAction func shareOnTwitterBtnPressed(_ sender: AnyObject) {
        
        shareWithProvider(provider: TWITTER)
    }
    
    //    func shareVideoOnTwitter(params: Dictionary<String,AnyObject>) {
    //
    //        var text: String = params["text"] as! String
    //        var dataVideo: Data? = params["video"] as! Data?
    ////        var lengthVideo: String = "\(CInt(params["length"]))"
    //        var url: String = "https://upload.twitter.com/1.1/media/upload.json"
    //        var mediaID: String
    //
    //        do {
    //            if Twitter.sharedInstance().sessionStore {
    //
    //                var client: TWTRAPIClient? = Twitter.sharedInstance().apiClient()
    //                var error: Error?
    //                // First call with command INIT
    //                var message: Dictionary<String,AnyObject> = ["status": text, "command": "INIT", "media_type": "video/mp4"]
    //                var preparedRequest: URLRequest? = try client?.urlRequest(withMethod: "POST", url: url, parameters: message)
    //                client?.sendTwitterRequest(preparedRequest, completion: {(_ urlResponse: URLResponse, _ responseData: Data, _ error: Error) -> Void in
    //                    do {
    //                        if error == nil {
    //                            var jsonError: Error?
    //                            var json: [AnyHashable: Any]? = try JSONSerialization.jsonObject(withData: responseData, options: [])
    //                            mediaID = (json?["media_id_string"] as? String)
    //                            client = Twitter.sharedInstance().apiClient()
    //                            var error: Error?
    //                            var videoString = dataVideo?.base64EncodedString(withOptions: 0)
    //                            // Second call with command APPEND
    //                            message = ["command": "APPEND", "media_id": mediaID, "segment_index": "0", "media": videoString]
    //                            var preparedRequest: URLRequest? = try client?.urlRequest(withMethod: "POST", url: url, parameters: message)
    //                            client?.sendTwitterRequest(preparedRequest, completion: {(_ urlResponse: URLResponse, _ responseData: Data, _ error: Error) -> Void in
    //                                do {
    //                                    if error == nil {
    //                                        client = Twitter.sharedInstance().apiClient()
    //                                        var error: Error?
    //                                        // Third call with command FINALIZE
    //                                        message = ["command": "FINALIZE", "media_id": mediaID]
    //                                        var preparedRequest: URLRequest? = try client?.urlRequest(withMethod: "POST", url: url, parameters: message)
    //                                        client?.sendTwitterRequest(preparedRequest, completion: {(_ urlResponse: URLResponse, _ responseData: Data, _ error: Error) -> Void in
    //                                            do {
    //                                                if error == nil {
    //                                                    client = Twitter.sharedInstance().apiClient()
    //                                                    var error: Error?
    //                                                    // publish video with status
    //                                                    var url: String = "https://api.twitter.com/1.1/statuses/update.json"
    //                                                    var message: [AnyHashable: Any] = [
    //                                                        "status" : text,
    //                                                        "wrap_links" : "true",
    //                                                        "media_ids" : mediaID
    //                                                    ]
    //
    //                                                    var preparedRequest: URLRequest? = try client?.urlRequest(withMethod: "POST", url: url, parameters: message)
    //                                                    client?.sendTwitterRequest(preparedRequest, completion: {(_ urlResponse: URLResponse, _ responseData: Data, _ error: Error) -> Void in
    //                                                        do {
    //                                                            if error == nil {
    //                                                                var jsonError: Error?
    //                                                                var json: [AnyHashable: Any]? = try JSONSerialization.jsonObject(withData: responseData, options: [])
    //                                                                print("\(json)")
    //                                                            }
    //                                                            else {
    //                                                                print("Error: \(error)")
    //                                                            }
    //                                                        }
    //                                                        catch {
    //                                                        }
    //                                                    })
    //                                                }
    //                                                else {
    //                                                    print("Error command FINALIZE: \(error)")
    //                                                }
    //                                            }
    //                                            catch {
    //                                            }
    //                                        })
    //                                    }
    //                                    else {
    //                                        print("Error command APPEND: \(error)")
    //                                    }
    //                                }
    //                                catch {
    //                                }
    //                            })
    //                        }
    //                        else {
    //                            print("Error command INIT: \(error)")
    //                        }
    //                    }
    //                    catch {
    //                    }
    //                })
    //            }
    //        }
    //        catch {
    //        }
    //    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
     
        dismiss(animated: true, completion: nil)
    }
}
