
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
    @IBOutlet weak var videoView: VideoContainerView!
    @IBOutlet weak var audioTitleLbl: UILabel!
    @IBOutlet weak var audioTimeLbl: UILabel!
    @IBOutlet weak var waveFormImg: UIImageView!
    @IBOutlet weak var commentsLbl: UILabel!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var followerBtn: UIButton!
    
    //Height Constraints
    @IBOutlet weak var messageHeight: NSLayoutConstraint!
    @IBOutlet weak var linkViewHeight: NSLayoutConstraint!
    @IBOutlet weak var postImgHeight: NSLayoutConstraint!
    @IBOutlet weak var linkShortUrlHeight: NSLayoutConstraint!
    @IBOutlet weak var linkTitleHeight: NSLayoutConstraint!
    @IBOutlet weak var audioViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageTrailing: NSLayoutConstraint!
    @IBOutlet weak var messageLeading: NSLayoutConstraint!
    @IBOutlet weak var messageTop: NSLayoutConstraint!
    
    //Variables
    var post: Post!
    var request: Request?
    var videoLayer: AVPlayerLayer?
    var player: AVPlayer?
    var mediaPlayer: AVPlayerViewController?
    var postTypeImage: UIImage!
    var trimmedMessage: String?
    var titleHeight: CGFloat?
    var totalHeight: CGFloat?
    var videoData: NSData?
    var openQuote: UIImageView?
    var closeQuote: UIImageView?
    var openQuoteHeight: NSLayoutConstraint?
    var closeQuoteHeight: NSLayoutConstraint?
    var authorTop: NSLayoutConstraint?
    var authorBottom: NSLayoutConstraint?
    var authorHeight: NSLayoutConstraint?
    var commentsLblTop: NSLayoutConstraint?
    var authorLbl: UILabel?
    var commentsLblBottom: NSLayoutConstraint?

    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(_ post: Post, currentLocation: Dictionary<String, AnyObject>?, image: UIImage?) {

        self.post = post
        self.username.text = post.username
        self.audioView.isHidden = true
        undoQuoteDisplay()
        
        if post.type == "text" {
            
            self.postTypeView.backgroundColor = AUBURN_RED
            postTypeImage = UIImage(named: "font-large")
            self.postTypeImg.image = postTypeImage
            
            setDynamicTextCell(message: post.message!)

        } else if post.type == "link" {
            
            self.postTypeView.backgroundColor = FIRE_ORANGE
            postTypeImage = UIImage(named: "link-large")
            self.postTypeImg.image = postTypeImage
            
            setDynamicLinkCell(linkTitle: post.title, message: post.message, image: image)

        } else if post.type == "image" {
            
            //Set Post Header
            self.postTypeView.backgroundColor = GOLDEN_YELLOW
            let img = UIImage(named: "photo-camera")
            self.postTypeImg.image = img
            
            setDynamicImageAndVideoCell(message: post.message, image: image, postType: post.type)

        } else if post.type == "video" {
            
            //Set Post Header
            self.postTypeView.backgroundColor = DARK_GREEN
            let img = UIImage(named: "video-camera")
            self.postTypeImg.image = img

            setDynamicImageAndVideoCell(message: post.message, image: image, postType: post.type)

        } else if post.type == "audio" {
            
            //Set Post Header
            self.postTypeView.backgroundColor = OCEAN_BLUE
            let img = UIImage(named: "microphone")
            self.postTypeImg.image = img
            
            setDynamicAudioCell(message: post.message, audioTitle: post.title)

        } else if post.type == "quote" {

            //Set Post Header
            self.postTypeView.backgroundColor = PURPLE
            let img = UIImage(named: "two-quotes")
            self.postTypeImg.image = img

            setDynamicQuoteCell(quoteText: post.text, quoteAuthor: post.author, quoteImage: image, quoteType: post.quoteType!)
            
        }

    }
    
    func playButtonTapped(sender: AnyObject) {
        
    }
    
    func setDynamicTextCell(message: String) {
        
        //Displays
        self.postImg.isHidden = true
        self.linkTitle.isHidden = true
        self.linkURL.isHidden = true
        
        //This should be eventually done on post creation.
        trimmedMessage = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        //Set Message Label
        let height = heightForView(self.message, text: trimmedMessage!)
        self.message.text = trimmedMessage
        self.message.font = UIFont(name: self.message.font.fontName, size: 12)
        
        //Constraints
        self.messageHeight.constant = height
        self.linkViewHeight.constant = 0
        self.audioViewHeight.constant = 0

    }
    
    func setDynamicLinkCell(linkTitle: String?, message: String?, image: UIImage?) {
        
        if image != nil {
            self.postImg.image = image
        } else if let postImage = post.image as String? {
                
            getPostImageFromServer(urlString: postImage, postType: "image")

        }
        
        configureMediaViewUI()

        //Displays
        self.postImg.isHidden = false
        self.linkTitle.isHidden = false
        self.linkURL.isHidden = false
        openQuoteHeight?.constant = 0
        closeQuoteHeight?.constant = 0
        
        totalHeight = POST_IMAGE_HEIGHT + 6
        
        if let title = linkTitle as String? {
            titleHeight = heightForView(self.linkTitle, text: title)
            self.linkTitleHeight.constant = titleHeight!
            totalHeight = totalHeight! + titleHeight!
        }
        
        if let shortUrl = post.shortUrl as String? {
            self.linkShortUrlHeight.constant = POST_LINK_URL_HEIGHT
            self.linkURL.text = shortUrl
            totalHeight = totalHeight! + POST_LINK_URL_HEIGHT
        }
        
        //Constraints
        self.linkViewHeight.constant = totalHeight!
        self.audioViewHeight.constant = 0
        
        if let msg = message as String? {

            trimmedMessage = msg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let height = heightForView(self.message, text: trimmedMessage!)
            self.message.text = trimmedMessage
            self.message.font = UIFont(name: self.message.font.fontName, size: 12)
            self.messageHeight.constant = height
        } else {
            self.messageHeight.constant = 0
        }
    
    }
    
    func setDynamicImageAndVideoCell(message: String?, image: UIImage?, postType: String) {
        
        if image != nil {
            self.postImg.image = image
        } else if let postImage = post.image as String? {
            
            getPostImageFromServer(urlString: postImage, postType: post.type)
            
        } else if let videoThumb = post.thumbnail as String? {
            
            getPostImageFromServer(urlString: videoThumb, postType: post.type)
            
        }
        
//        if postType == "video" {
//            getVideoDataFromServer(urlString: post.video!)
//        }

        configureMediaViewUI()
        
        //Displays
        self.postImg.isHidden = false
        
        //Constraints
        self.linkViewHeight.constant = POST_IMAGE_HEIGHT
        self.audioViewHeight.constant = 0
        self.linkTitleHeight.constant = 0
        self.linkShortUrlHeight.constant = 0
        
        if let msg = message as String? {
            
            trimmedMessage = msg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let height = heightForView(self.message, text: trimmedMessage!)
            self.message.text = trimmedMessage
            self.message.font = UIFont(name: self.message.font.fontName, size: 12)
            self.messageHeight.constant = height
        } else {
            self.messageHeight.constant = 0
        }
        
        
    }
    
    func setDynamicAudioCell(message: String?, audioTitle: String?) {
        
            let path = Bundle.main.path(forResource: "wave", ofType: "mov")!
            let videoUrl = NSURL(fileURLWithPath: path)
        
            let asset = AVURLAsset(url: videoUrl as URL, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
        
            do {
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage, scale: CGFloat(1.0), orientation: .up)
                self.waveFormImg.image = uiImage
                self.waveFormImg.clipsToBounds = true
            } catch let err as NSError {
                print(err.debugDescription)
            }
        
            if audioTitle != nil {
                self.audioTitleLbl.text = audioTitle
            }
        
            //Displays
            self.postImg.isHidden = true
            self.linkTitle.isHidden = true
            self.linkURL.isHidden = true
            self.audioView.isHidden = false

            //Contstraints
            self.audioViewHeight.constant = 50
            self.linkViewHeight.constant = 0
            self.messageHeight.constant = 0
        
        
        
    }
    
    func setDynamicQuoteCell(quoteText: String?, quoteAuthor: String?, quoteImage: UIImage?, quoteType: String) {
        
        self.audioViewHeight.constant = 0
        self.linkTitleHeight.constant = 0
        self.linkShortUrlHeight.constant = 0
        self.linkViewHeight.constant = 0
        self.audioView.isHidden = true
        
        if quoteType == "image" {
            
            if quoteImage != nil {
                self.postImg.image = quoteImage
            } else {
                getPostImageFromServer(urlString: post.image!, postType: post.type)
            }
            
            configureMediaViewUI()
            
            //Displays
            self.linkView.isHidden = false
            self.postImg.isHidden = false
            self.linkTitle.isHidden = true
            self.linkURL.isHidden = true
            
            //Constraints
            self.linkViewHeight.constant = POST_IMAGE_HEIGHT
            self.messageHeight.constant = 0
            
        } else if quoteType == "text" {
            
            let trimmedMessage = quoteText!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            self.message.textAlignment = .center
            self.message.text = trimmedMessage
            self.message.font = UIFont(name: message.font.fontName, size: 14)
            let height = heightForView(message, text: trimmedMessage)
            self.messageHeight.constant = height
            self.message.textColor = UIColor.black
            
//            let closeQuoteImage = UIImage(named: "close-quote")
//            closeQuote = UIImageView(image: closeQuoteImage!)
//            closeQuote?.translatesAutoresizingMaskIntoConstraints = true
//            self.addSubview(closeQuote!)
//            
//            let openQuoteImage = UIImage(named: "quotes")
//            openQuote = UIImageView(image: openQuoteImage!)
//            openQuote?.translatesAutoresizingMaskIntoConstraints = false
//            self.addSubview(openQuote!)
            

            
            self.postImg.isHidden = true
            openQuote?.isHidden = false
            closeQuote?.isHidden = false
            
            
//                            openQuoteHeight = NSLayoutConstraint(
//                                item: openQuote!,
//                                attribute: NSLayoutAttribute.height,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: nil,
//                                attribute: NSLayoutAttribute.notAnAttribute,
//                                multiplier: 1,
//                                constant: 18)
//
//                            let openQuoteWidth = NSLayoutConstraint(
//                                item: openQuote!,
//                                attribute: NSLayoutAttribute.width,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: nil,
//                                attribute: NSLayoutAttribute.notAnAttribute,
//                                multiplier: 1,
//                                constant: 18)
//            
//                            let openQuoteTop = NSLayoutConstraint(
//                                item: openQuote!,
//                                attribute: NSLayoutAttribute.top,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: self.linkView,
//                                attribute: NSLayoutAttribute.bottom,
//                                multiplier: 1,
//                                constant: 12)
//            
//            
//                            let openQuoteBottom = NSLayoutConstraint(
//                                item: openQuote!,
//                                attribute: NSLayoutAttribute.bottom,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: self.message,
//                                attribute: NSLayoutAttribute.top,
//                                multiplier: 1,
//                                constant: 0)
//            
//            
//                            let openQuoteTrailing = NSLayoutConstraint(
//                                item: openQuote!,
//                                attribute: NSLayoutAttribute.trailing,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: self.message,
//                                attribute: NSLayoutAttribute.leading,
//                                multiplier: 1,
//                                constant: 0)
//            
//            
//                            let openQuoteLeading = NSLayoutConstraint(
//                                item: openQuote!,
//                                attribute: NSLayoutAttribute.leading,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: self,
//                                attribute: NSLayoutAttribute.leading,
//                                multiplier: 1,
//                                constant: 10)
//            
//                            closeQuoteHeight = NSLayoutConstraint(
//                                item: closeQuote!,
//                                attribute: NSLayoutAttribute.height,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: nil,
//                                attribute: NSLayoutAttribute.notAnAttribute,
//                                multiplier: 1,
//                                constant: 18)
//
//                            let closeQuoteWidth = NSLayoutConstraint(
//                                item: closeQuote!,
//                                attribute: NSLayoutAttribute.width,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: nil,
//                                attribute: NSLayoutAttribute.notAnAttribute,
//                                multiplier: 1,
//                                constant: 18)
//            
//                            let closeQuoteTop = NSLayoutConstraint(
//                                item: closeQuote!,
//                                attribute: NSLayoutAttribute.top,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: self.message,
//                                attribute: NSLayoutAttribute.bottom,
//                                multiplier: 1,
//                                constant: 0)
//            
//                            let closeQuoteLeading = NSLayoutConstraint(
//                                item: closeQuote!,
//                                attribute: NSLayoutAttribute.leading,
//                                relatedBy: NSLayoutRelation.equal,
//                                toItem: self.message,
//                                attribute: NSLayoutAttribute.trailing,
//                                multiplier: 1,
//                                constant: 0)

//            self.addConstraints([openQuoteWidth, openQuoteHeight!, openQuoteTop, openQuoteTrailing, openQuoteBottom, openQuoteLeading])
            
//            if let quoteAuthor = post.author as String? {
//                
//                authorLbl = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width - 20, height: 20))
//                authorLbl?.text = "- \(quoteAuthor)"
//                authorLbl?.font = UIFont(name: (authorLbl?.font.fontName)!, size: 14)
//                authorLbl?.textAlignment = .center
//                authorLbl?.translatesAutoresizingMaskIntoConstraints = false
//                authorLbl?.isHidden = false
//                self.addSubview(authorLbl!)
//                
//                let authorWidth = NSLayoutConstraint(
//                    item: authorLbl!,
//                    attribute: NSLayoutAttribute.width,
//                    relatedBy: NSLayoutRelation.equal,
//                    toItem: nil,
//                    attribute: NSLayoutAttribute.notAnAttribute,
//                    multiplier: 1,
//                    constant: self.bounds.size.width - 20)
//                
//                authorHeight = NSLayoutConstraint(
//                    item: authorLbl!,
//                    attribute: NSLayoutAttribute.height,
//                    relatedBy: NSLayoutRelation.equal,
//                    toItem: nil,
//                    attribute: NSLayoutAttribute.notAnAttribute,
//                    multiplier: 1,
//                    constant: 20)
//                
//                let authorCenterX = NSLayoutConstraint(
//                    item: authorLbl!,
//                    attribute: NSLayoutAttribute.centerX,
//                    relatedBy: NSLayoutRelation.equal,
//                    toItem: self,
//                    attribute: NSLayoutAttribute.centerX,
//                    multiplier: 1,
//                    constant: 0)
//                
//                authorTop = NSLayoutConstraint(
//                    item: authorLbl!,
//                    attribute: NSLayoutAttribute.top,
//                    relatedBy: NSLayoutRelation.equal,
//                    toItem: closeQuote!,
//                    attribute: NSLayoutAttribute.bottom,
//                    multiplier: 1,
//                    constant: 12)
//                
//                authorBottom = NSLayoutConstraint(
//                    item: authorLbl!,
//                    attribute: NSLayoutAttribute.bottom,
//                    relatedBy: NSLayoutRelation.equal,
//                    toItem: self.commentsLbl,
//                    attribute: NSLayoutAttribute.top,
//                    multiplier: 1,
//                    constant: 0)
//                
//                self.addConstraints([authorWidth,authorHeight!, authorCenterX, authorTop!, authorBottom!])
//                
//            }
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
    
    func configureMediaViewUI() {
        self.linkView.layer.borderColor = UIColor.lightGray.cgColor
        self.linkView.layer.cornerRadius = 2
        self.linkView.layer.borderWidth = 1
        self.postImg.layer.cornerRadius = 2
        self.postImg.clipsToBounds = true
    }
    
    func getPostImageFromServer(urlString: String, postType: String) {
        
        let url = URL(string: urlString)!
        request = Alamofire.request(url, method: .get).response { response in
            if response.error == nil {
                
                let img = UIImage(data: response.data!)
                
                if postType == "image" {
                    self.postImg.image = img
                    ActivityVC.imageCache.setObject(img!, forKey: urlString as AnyObject)
                } else if postType == "video" {
                    let rotatedImage = self.imageRotatedByDegrees(oldImage: img!, deg: 90)
                    self.postImg.image = rotatedImage
                    ActivityVC.imageCache.setObject(rotatedImage, forKey: urlString as AnyObject)
                } else if postType == "quote" {
                    self.postImg.image = img
                    ActivityVC.imageCache.setObject(img!, forKey: urlString as AnyObject)
                }

            } else {
                print("\(response.error)")
            }
        }
        self.postImg.clipsToBounds = true

    }
    
    func getVideoDataFromServer(urlString: String) {
        
        if let video = post.video! as String? {
            
            let url = URL(string: video)!
            self.request = Alamofire.request(url, method: .get).response { response in
                if response.error == nil {
                    print("\(response.data)")
                    self.videoData = response.data as NSData?
                } else {
                    print("\(response.error)")
                }
            }
        }
    }
    
    func undoQuoteDisplay() {
        
        openQuoteHeight?.constant = 0
        closeQuoteHeight?.constant = 0
        openQuote?.isHidden = true
        closeQuote?.isHidden = true
        self.message.textAlignment = .left
        self.message.font = UIFont(name: message.font.fontName, size: 12)
        self.message.textColor = UIColor.darkGray
        self.messageTop.constant = CGFloat(POST_MESSAGE_TOP_MARGIN)
        self.messageLeading.constant = CGFloat(POST_MESSAGE_HORIZONTAL_MARGINS)
        self.messageTrailing.constant = CGFloat(POST_MESSAGE_HORIZONTAL_MARGINS)
        authorLbl?.isHidden = true
        authorLbl?.removeConstraints([authorHeight!, closeQuoteHeight!, openQuoteHeight!])
    }
    
    func heightForView(_ label:UILabel, text: String) -> CGFloat {
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }

}
