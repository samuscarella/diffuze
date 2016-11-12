
//
//  PostCell.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/18/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import CoreLocation
import AVFoundation
import AVKit

class PostCell: UITableViewCell {
    
    //Outlets
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var postTypeView: UIView!
    @IBOutlet weak var postTypeImg: UIImageView!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var distanceAway: UILabel!
    @IBOutlet weak var postImg: UIImageView!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var linkView: UIView!
    @IBOutlet weak var linkTitle: UILabel!
    @IBOutlet weak var linkURL: UILabel!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var audioControlView: UIView!
    @IBOutlet weak var playAudioBtn: UIButton!
    @IBOutlet weak var videoView: VideoContainerView!
    
    //Height Constraints
    @IBOutlet weak var messageHeight: NSLayoutConstraint!
    @IBOutlet weak var linkViewHeight: NSLayoutConstraint!
    @IBOutlet weak var postImgHeight: NSLayoutConstraint!
    @IBOutlet weak var linkShortUrlHeight: NSLayoutConstraint!
    @IBOutlet weak var linkTitleHeight: NSLayoutConstraint!
    @IBOutlet weak var audioViewHeight: NSLayoutConstraint!
    
    //Variables
    var post: Post!
    var request: Request?
    var videoLayer: AVPlayerLayer?
    var player: AVPlayer?
    var mediaPlayer: AVPlayerViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func draw(_ rect: CGRect) {
      //  profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
      //  profileImg.clipsToBounds = true
//        showcaseImg.clipsToBounds = true
    }
    
    func configureCell(_ post: Post, currentLocation: Dictionary<String, AnyObject>?, image: UIImage?) {

        self.post = post
        linkTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        self.audioView.layer.borderColor = UIColor.black.cgColor
        self.linkView.layer.borderColor = UIColor.lightGray.cgColor
        self.linkView.layer.cornerRadius = 2
        self.linkView.layer.borderWidth = 1
        self.postImg.layer.cornerRadius = 2
        self.postImg.clipsToBounds = true
        self.audioView.isHidden = true
        self.username.text = post.username
        
        if post.type == "text" {
            
            let img = UIImage(named: "font-large")
//            let score = post.likes + post.dislikes
            self.postTypeView.backgroundColor = AUBURN_RED
            self.postTypeImg.image = img
//            self.postTypeView.backgroundColor = AUBURN_RED
            let trimmedMessage = post.message?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let height = heightForView(message, text: trimmedMessage!)
            self.message.text = trimmedMessage
            self.messageHeight.constant = height
            
            linkView.isHidden = true
            linkViewHeight.constant = 0
            audioViewHeight.constant = 0

            
        } else if post.type == "link" {
            
            if image != nil {
                self.postImg.image = image
            } else if let postImage = post.image as String? {
                
                let url = URL(string: postImage)!
                request = Alamofire.request(url, method: .get).response { response in
                    if response.error == nil {
                        print("\(response.data)\n\n\n\n\n\n\n\nlkl;")
                        let img = UIImage(data: response.data!)
                        self.postImg.image = img
                        ActivityVC.imageCache.setObject(img!, forKey: post.image! as AnyObject)
                    } else {
                        print("\(response.error)\n\n\n\n\n\n\n\n\n")
                    }
                }
            }
            
            self.postTypeView.backgroundColor = FIRE_ORANGE
            let img = UIImage(named: "link-large")
            self.postTypeImg.image = img
            self.linkView.isHidden = false
            self.linkTitle.isHidden = false
            self.audioViewHeight.constant = 0
            self.postImg.isHidden = false
            
            let titleHeight = heightForView(linkTitle, text: post.title!)
            
            self.linkTitleHeight.constant = titleHeight
            
            if let shortUrl = post.shortUrl as String? {
                self.linkURL.text = shortUrl
                self.linkShortUrlHeight.constant = 20
            }
            
            let totalHeight: CGFloat = titleHeight + postImgHeight.constant + linkShortUrlHeight.constant + 6
            self.linkViewHeight.constant = totalHeight
            
            if let message = post.message as String? {
                let trimmedMessage = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let height = heightForView(self.message, text: trimmedMessage)
                self.message.text = trimmedMessage
                self.messageHeight.constant = height
            } else {
                self.messageHeight.constant = 0
            }
            
        //var totalHeight: CGFloat = 0
        //for subview in self.linkView.subviews {
        //     totalHeight += subview.frame.height
        //}
        //linkViewHeight.constant = totalHeight
        
        } else if post.type == "image" {
            
            //Retrieve image from storage
            if image != nil {
                self.postImg.image = image
            } else if let postImage = post.image as String? {
                let url = URL(string: postImage)!
                request = Alamofire.request(url, method: .get).response { response in
                    if response.error == nil {
                        print("\(response.data)\n\n\n\n\n\n\n\n\n")
                        let img = UIImage(data: response.data!)
                        self.postImg.image = img
                        ActivityVC.imageCache.setObject(img!, forKey: post.image! as AnyObject)
                    } else {
                        print("\(response.error)\n\n\n\n\n\n\n\n\n")
                    }
                }
            }

            //Set Post Header
            self.postTypeView.backgroundColor = GOLDEN_YELLOW
            let img = UIImage(named: "photo-camera")
            self.postTypeImg.image = img
            
            self.postImg.isHidden = false
            self.linkTitleHeight.constant = 0
            self.linkShortUrlHeight.constant = 0
            self.audioViewHeight.constant = 0
            self.linkViewHeight.constant = self.postImgHeight.constant
            
            if let imageMessage = post.message as String? {
                let trimmedMessage = imageMessage.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let height = heightForView(self.message, text: trimmedMessage)
                self.message.text = trimmedMessage
                self.messageHeight.constant = height
            } else {
                self.messageHeight.constant = 0
            }
            
        } else if post.type == "video" {
            
            if image != nil {
                self.postImg.image = image
            } else {
                let url = URL(string: post.thumbnail!)!
                request = Alamofire.request(url, method: .get).response { response in
                    if response.error == nil {
                        print("\(response.data)\n\n\n\n\n\n\n\n\n")
                        let img = UIImage(data: response.data!)
                        let rotatedImage = self.imageRotatedByDegrees(oldImage: img!, deg: 90)
                        self.postImg.image = rotatedImage
                        self.postImg.clipsToBounds = true
                        ActivityVC.imageCache.setObject(rotatedImage, forKey: post.thumbnail! as AnyObject)
                        
                        if let video = post.video! as String? {
                            
                            let url = URL(string: video)!
                            self.request = Alamofire.request(url, method: .get).response { response in
                                if response.error == nil {
                                    print("\(response.data)\n\n\n\n\n\n\n\n\n")
                                    let video = response.data
                                } else {
                                    print("\(response.error)\n\n\n\n\n\n\n\n\n")
                                }
                            }
                        }
                    } else {
                        print("\(response.error)\n\n\n\n\n\n\n\n\n")
                    }
                }
            }
            
            if let message = post.message as String? {
                let trimmedMessage = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let height = heightForView(self.message, text: trimmedMessage)
                self.message.text = trimmedMessage
                self.messageHeight.constant = height
            }

            //Set Post Header
            self.postTypeView.backgroundColor = DARK_GREEN
            let img = UIImage(named: "video-camera")
            self.postTypeImg.image = img
            
        } else if post.type == "audio" {
            
        } else if post.type == "premium" {
            
        }
    }
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat(M_PI / 180))
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat(M_PI / 180)))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func heightForView(_ label:UILabel, text: String) -> CGFloat {
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }

}
