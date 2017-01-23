
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
import GeoFire
import QuartzCore

protocol TableViewCellDelegate {
    
    func postManipulated(post: Post, action: String)
}
protocol ActivityTableViewCellDelegate {
    
    func postAction(action: String)
    func updatePostInArray(post: Post)
}
protocol SocialSharingDelegate {
    
    func openSharePostVC(post: Post)
}

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
    @IBOutlet weak var postScoreLbl: UILabel!
    @IBOutlet weak var sharePostBtn: UIButton!
    @IBOutlet weak var flagPostBtn: UIButton!
    @IBOutlet weak var followersLbl: UILabel!
    @IBOutlet weak var neutralImageView: UIImageView!
    
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
    @IBOutlet weak var postCellView: MaterialUIView!
    
    let currentUserID = UserDefaults.standard.object(forKey: KEY_UID) as! String
    let currentUserUsername = UserDefaults.standard.object(forKey: KEY_USERNAME) as! String
    let geofireRef = URL_BASE.child("user-locations")
    let timeService = TimeService()

    //Variables
    var post: Post!
    var request: Request?
    var followingUsers: FIRDatabaseReference!
    var followingUser: FIRDatabaseReference!
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
    var followingImage: UIImage!
    var notFollowingImage: UIImage!
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false
    var likeOnDragRelease = false
    var delegate: TableViewCellDelegate?
    var activityDelegate: ActivityTableViewCellDelegate?
    var sharingDelegate: SocialSharingDelegate?
    var postType: String!
    var filterType: String?
    var postObjRef: [String:Bool]!
    var currentInteractions: Int!
    var participationRate: Double!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(recognizer:)))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(recognizer:)))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        followingImage = UIImage(named: "following-blue")
        notFollowingImage = UIImage(named: "follower-grey")
    }
    
    func configureCell(_ post: Post, currentLocation: Dictionary<String, AnyObject>?, image: UIImage?, postType: String, filterType: String?) {
        
        self.post = post
        self.username.text = post.username
        self.postType = postType
        self.postObjRef = [post.postKey:true]

        var userPhotoAvailable = false
        
        if let posterPhoto = ActivityVC.imageCache.object(forKey: post.user_id as AnyObject) as? UIImage {
            
            self.layoutIfNeeded()
            self.profileImg.layer.cornerRadius = self.profileImg.frame.size.height / 2
            self.profileImg.clipsToBounds = true
            self.profileImg.image = posterPhoto
            userPhotoAvailable = true
        }
        
        URL_BASE.child("users").child(self.post.user_id).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            let userDict = snapshot.value as? Dictionary<String, AnyObject> ?? [:]
            
            if let key = userDict["user_id"] as? String {
                
                let user = User.init(userId: key, dictionary: userDict)
                
                if let userPhoto = user.userPhoto {
                    
                    if !userPhotoAvailable {
                        
                        let url = URL(string: userPhoto)!
                        self.request = Alamofire.request(url, method: .get).response { response in
                            
                            if response.error == nil {
                                
                                let img = UIImage(data: response.data!)
                                self.layoutIfNeeded()
                                self.profileImg.layer.cornerRadius = self.profileImg.frame.size.height / 2
                                self.profileImg.clipsToBounds = true
                                self.profileImg.image = img
                                ActivityVC.imageCache.setObject(img!, forKey: post.user_id as AnyObject)
                            } else {
                                print("\(response.error)")
                            }
                        }
                    }
                } else {
                    self.profileImg.image = UIImage(named: "user")
                }
                
                var numberOfFollowers = 0
                if let userFollowers = user.followers {
                    
                    numberOfFollowers = userFollowers.count
                    
                    var isFollowingPoster = false
                    for follower in userFollowers {
                        if follower == self.currentUserID {
                            isFollowingPoster = true
                            break
                        }
                    }
                    if self.followerBtn != nil {
                        if isFollowingPoster {
                            self.followerBtn.setImage(UIImage(named: "following-blue"), for: .normal)
                        } else {
                            self.followerBtn.setImage(UIImage(named: "follower-grey"), for: .normal)
                        }
                    }
                } else {
                    if self.followerBtn != nil {
                        self.followerBtn.setImage(UIImage(named: "follower-grey"), for: .normal)
                    }
                }
                
                if numberOfFollowers == 1 {
                    self.followersLbl.text = "\(numberOfFollowers) Follower"
                } else {
                    self.followersLbl.text = "\(numberOfFollowers) Followers"
                }
            }
        })

        self.audioTitleLbl.isHidden = true
        self.audioTimeLbl.isHidden = true

        undoQuoteDisplay()
        
        if postType == "activity" {
            
            URL_BASE.child("users").child(currentUserID).child("dislikes").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                
                let dislikedKeys = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                for post in dislikedKeys {
                    if self.post.postKey == post.key {
                        self.neutralImageView.image = UIImage(named: "checkmark-red")
                    }
                }
            })
            URL_BASE.child("users").child(currentUserID).child("likes").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                
                let likedKeys = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                for post in likedKeys {
                    if self.post.postKey == post.key {
                        self.neutralImageView.image = UIImage(named: "checkmark-green")
                    }
                }
            })
        }
        
        if filterType != nil {
            self.filterType = filterType
            
            if filterType != "My Posts" {
                
                if filterType == "Liked" {
                    self.neutralImageView.image = UIImage(named: "checkmark-green")
                } else if filterType == "Disliked" {
                    self.neutralImageView.image = UIImage(named: "checkmark-red")
                }
            } else {
                self.neutralImageView.image = UIImage(named: "neutral")
            }
        }
        let score = post.likes - post.dislikes
        if score == 0 {
            self.postScoreLbl.textColor = NEUTRAL_YELLOW
        } else if score > 0 {
            self.postScoreLbl.textColor = LIKE_GREEN
        } else {
            self.postScoreLbl.textColor = DISLIKE_RED
        }
        self.postScoreLbl.text = "\(abs(score))"
        
        self.timestamp.text = timeService.getTimeStampFromMilliSeconds(millis: post.timestamp)
        
        let geoFire = GeoFire(firebaseRef: geofireRef)!
        
        geoFire.getLocationForKey(currentUserID, withCallback: { (location, error) in
            if (error != nil) {
                print("An error occurred getting the location for \"firebase-hq\": \(error?.localizedDescription)")
            } else if (location != nil) {

                var locationDict: Dictionary<String,AnyObject> = [:]
                locationDict["latitude"] = location?.coordinate.latitude as AnyObject?
                locationDict["longitude"] = location?.coordinate.longitude as AnyObject?
                let location = Location()
                self.distanceAway.text = location.getDistanceBetweenUserAndPost(locationDict, post: post)
            } else {
                print("GeoFire does not contain a location for \"firebase-hq\"")
            }
        })
        
        
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
        self.audioView.isHidden = true
        self.linkView.isHidden = true
        
        //This should be eventually done on post creation.
        trimmedMessage = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        //Constraints
        self.linkViewHeight.constant = 0
        self.audioViewHeight.constant = 0
        
        //Set Message Label
        let height = heightForView(self.message, text: trimmedMessage!)
        self.messageHeight.constant = height
        self.message.text = trimmedMessage
        self.message.font = UIFont(name: "Ubuntu", size: 12)
    }
    
    func setDynamicLinkCell(linkTitle: String?, message: String?, image: UIImage?) {
        
        if image != nil {
            self.postImg.image = image
        } else if let postImage = post.image as String? {
            getPostImageFromServer(urlString: postImage, postType: "image")
        } else {
            self.postImg.image = UIImage(named: "no-image")
        }
        
        configureMediaViewUI()

        self.postImg.isHidden = false
        self.linkTitle.isHidden = false
        self.linkURL.isHidden = false
        self.linkView.isHidden = false
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
        self.audioView.isHidden = true
        
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
        
        configureMediaViewUI()
        
        //Displays
        self.postImg.isHidden = false
        self.linkView.isHidden = false
        
        //Constraints
        self.audioView.isHidden = true
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
            self.linkView.isHidden = true
            self.linkTitle.isHidden = true
            self.linkURL.isHidden = true
            self.audioView.isHidden = false
            self.audioTitleLbl.isHidden = false
            self.audioTimeLbl.isHidden = false

            //Contstraints
            self.audioView.layer.cornerRadius = 2
            self.waveFormImg.layer.cornerRadius = 2
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
        self.postImg.isHidden = true
        
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
            
            trimmedMessage = quoteText!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            self.message.textColor = UIColor.black
            self.message.text = trimmedMessage
            self.message.font = UIFont(name: "Ubuntu-Bold", size: 14)
            let height = heightToFit(label: self.message)
            self.messageHeight.constant = height
            self.message.textAlignment = .center
        }
    }
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat(M_PI / 180))
        
        rotatedViewBox.transform = t
        
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        bitmap.rotate(by: (degrees * CGFloat(M_PI / 180)))
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
                
                self.postImg.clipsToBounds = true

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
    }
    
    
    func undoQuoteDisplay() {
        
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
    
    func heightToFit(label: UILabel) -> CGFloat {
        
        let maxHeight : CGFloat = 10000
        let labelSize = CGSize(width: self.frame.size.width, height: maxHeight)
        let rect = label.attributedText?.boundingRect(with: labelSize, options: .usesLineFragmentOrigin, context: nil)
        
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        return rect!.size.height
    }
    
    @IBAction func sharePostBtnPressed(_ sender: AnyObject) {
     
        self.sharingDelegate!.openSharePostVC(post: post)
    }
    
    @IBAction func followersBtnPressed(_ sender: AnyObject) {
        
        let followingUsers = URL_BASE.child("users").child(currentUserID).child("following")
        let followingUser = URL_BASE.child("users").child(post.user_id).child("followers")
        let notification = URL_BASE.child("notifications").child(self.post.user_id)
        
        let followingObj = [self.post.user_id: true]
        let followerObj = [currentUserID: true]
        
        let notificationObj = [
            "username": currentUserUsername,
            "read": false,
            "status": true,
            "type": "follower",
            "timestamp": FIRServerValue.timestamp()
        ] as [String : Any]
        
        if followerBtn.imageView?.image == notFollowingImage {
            
            notification.child(currentUserID).updateChildValues(notificationObj)
            
            followingUsers.updateChildValues(followingObj)
            followingUser.updateChildValues(followerObj)
            
            followerBtn.setImage(followingImage, for: .normal)
        } else if followerBtn.imageView?.image == followingImage {
            
            notification.child(currentUserID).child("status").setValue(false)
            
            followingUsers.child(self.post.user_id).removeValue()
            followingUser.child(currentUserID).removeValue()
            
            followerBtn.setImage(notFollowingImage, for: .normal)
        }
    }
    
    
    func showUnfollowUserPostView() {
        //observe user object and save suppressed posts in key and have tableview update and refresh each time a post is suppressed. By adding a key to the postDict that will notify post cell to change view to suppressed view
        
        for view in postCellView.subviews {
            view.isHidden = true
            view.frame.size.height = 0
        }
        postCellView.frame.size.height = 0
        contentView.frame.size.height = 0
        postTypeImg.isHidden = true
        self.frame.size.height = 100
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        
        if self.filterType != "My Posts" {
            
            // 1
            if recognizer.state == .began {
                // when the gesture begins, record the current center location
                originalCenter = center
            }
            // 2
            if recognizer.state == .changed {
                let translation = recognizer.translation(in: self)
                center = CGPoint(x: originalCenter.x + translation.x,y: originalCenter.y)
                
                likeOnDragRelease = false
                deleteOnDragRelease = false
                
                if frame.origin.x > frame.size.width / 2.0 {
                    likeOnDragRelease = true
                } else if frame.origin.x < -frame.size.width / 2.0 {
                    deleteOnDragRelease = true
                }
            }
            // 3
            if recognizer.state == .ended {
                
                let originalFrame = CGRect(x: 0, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
                
                let radarPost = URL_BASE.child("users").child(currentUserID).child("radar").child(post.postKey)
                
                if deleteOnDragRelease {

                    if delegate != nil || activityDelegate != nil && post != nil {
                        
                        if self.postType == "activity" || self.postType == "Viral" {
                            
                            dislikePost()
                            activityDelegate!.postAction(action: "dislike")
                            self.neutralImageView.image = UIImage(named: "checkmark-red")
                            
                        } else if self.postType == "radar" {
                            
                            dislikePost()
                            radarPost.removeValue()
                            delegate!.postManipulated(post: post!, action: "dislike")
                            
                        } else if self.postType == "myinfo" {

                            dislikePost()
                            if self.filterType == "Liked" {
                                delegate!.postManipulated(post: post!, action: "dislike")
                            } else if self.filterType == "Disliked" {
                                activityDelegate!.postAction(action: "dislike")
                            }
                        }
                    }
                }
                if likeOnDragRelease {

                    if delegate != nil || activityDelegate != nil && post != nil {
                        
                        if self.postType == "activity" || self.postType == "Viral" {
                            
                            likePost()
                            activityDelegate!.postAction(action: "like")
                            self.neutralImageView.image = UIImage(named: "checkmark-green")
                            
                        } else if self.postType == "radar" {
                            
                            likePost()
                            radarPost.removeValue()
                            delegate!.postManipulated(post: post!, action: "like")
                            
                        } else if self.postType == "myinfo" {

                            likePost()
                            if self.filterType == "Liked" {
                                activityDelegate!.postAction(action: "like")
                            } else if self.filterType == "Disliked" {
                                delegate!.postManipulated(post: post!, action: "like")
                            }
                        }
                    }
                }
                if !deleteOnDragRelease && !likeOnDragRelease || self.postType == "activity" || self.postType == "myinfo" || self.postType == "Viral" {
                    
                    UIView.animate(withDuration: 0.2, animations: {self.frame = originalFrame})
                }
            }
        }
    }
    
    func likePost() {
        
        let postRef = URL_BASE.child("posts").child(post.postKey)
        
        postRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            
            if var post = currentData.value as? [String : AnyObject], let uid = FIRAuth.auth()?.currentUser?.uid {
                
                var likesDict: Dictionary<String,Bool>
                var dislikesDict: Dictionary<String,Bool>

                likesDict = post["user-likes"] as? [String : Bool] ?? [:]
                dislikesDict = post["user-dislikes"] as? [String : Bool] ?? [:]
                
                var likeCount = post["likes"] as? Int ?? 0
                var dislikeCount = post["dislikes"] as? Int ?? 0
                
                if likesDict[uid] == nil {
                    URL_BASE.child("users").child(self.currentUserID).child("likes").updateChildValues(self.postObjRef)
                    likeCount += 1
                    likesDict[uid] = true
                }
                
                if dislikesDict[uid] != nil {
                    URL_BASE.child("users").child(self.currentUserID).child("dislikes").child(self.post.postKey).removeValue()
                    dislikeCount -= 1
                    dislikesDict.removeValue(forKey: uid)
                }
                
                let interactions = likeCount + dislikeCount
                let rating = Double(likeCount) / Double(interactions)
                let score = abs(likeCount - dislikeCount)
                
                post["likes"] = likeCount as AnyObject?
                post["user-likes"] = likesDict as AnyObject?
                post["dislikes"] = dislikeCount as AnyObject?
                post["user-dislikes"] = dislikesDict as AnyObject?
                post["rating"] = rating as AnyObject?
                post["score"] = score as AnyObject?
                post["last_interaction"] = FIRServerValue.timestamp() as AnyObject?
                
                currentData.value = post
                
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {

                let postDict = snapshot?.value as! Dictionary<String,AnyObject>
                let key = postDict["post_ref"] as! String
                let post = Post(postKey: key, dictionary: postDict)
                let score = post.likes - post.dislikes
                
                self.postInteractionCheck(post: postDict)
                self.activityDelegate?.updatePostInArray(post: post)

                if score == 0 {
                    self.postScoreLbl.textColor = NEUTRAL_YELLOW
                } else if score > 0 {
                    self.postScoreLbl.textColor = LIKE_GREEN
                } else {
                    self.postScoreLbl.textColor = DISLIKE_RED
                }
                self.postScoreLbl.text = "\(abs(score))"
            }
        }
    }
    
    func dislikePost() {
        
        let postRef = URL_BASE.child("posts").child(post.postKey)

        postRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            
            if var post = currentData.value as? [String : AnyObject], let uid = FIRAuth.auth()?.currentUser?.uid {
                
                var likesDict: Dictionary<String,Bool>
                var dislikesDict: Dictionary<String,Bool>
                
                likesDict = post["user-likes"] as? [String:Bool] ?? [:]
                dislikesDict = post["user-dislikes"] as? [String:Bool] ?? [:]
                
                var likeCount = post["likes"] as? Int ?? 0
                var dislikeCount = post["dislikes"] as? Int ?? 0
                
                if likesDict[uid] != nil {
                    URL_BASE.child("users").child(self.currentUserID).child("likes").child(self.post.postKey).removeValue()
                    likeCount -= 1
                    likesDict.removeValue(forKey: uid)
                }
                
                if dislikesDict[uid] == nil {
                    URL_BASE.child("users").child(self.currentUserID).child("dislikes").updateChildValues(self.postObjRef)
                    dislikeCount += 1
                    dislikesDict[uid] = true
                }
                
                let interactions = likeCount + dislikeCount
                let rating = Double(likeCount) / Double(interactions)
                let score = abs(likeCount - dislikeCount)
                
                post["likes"] = likeCount as AnyObject?
                post["dislikes"] = dislikeCount as AnyObject?
                post["user-likes"] = likesDict as AnyObject?
                post["user-dislikes"] = dislikesDict as AnyObject?
                post["rating"] = rating as AnyObject?
                post["score"] = score as AnyObject?
                post["last_interaction"] = FIRServerValue.timestamp() as AnyObject?
                
                currentData.value = post
                
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            
            if let error = error {
                print(error.localizedDescription)
            } else {
                
                let postDict = snapshot?.value as! Dictionary<String,AnyObject>
                let key = postDict["post_ref"] as! String
                let post = Post(postKey: key, dictionary: postDict)
                let score = post.likes - post.dislikes
                
                self.postInteractionCheck(post: postDict)
                self.activityDelegate?.updatePostInArray(post: post)

                if score == 0 {
                    self.postScoreLbl.textColor = NEUTRAL_YELLOW
                } else if score > 0 {
                    self.postScoreLbl.textColor = LIKE_GREEN
                } else {
                    self.postScoreLbl.textColor = DISLIKE_RED
                }
                self.postScoreLbl.text = "\(abs(score))"
            }
        }
    }
    
    func postInteractionCheck(post: Dictionary<String,AnyObject>) {
        
        if self.post.active {
            
            let initial = self.post.initial
            let likes = self.post.likes
            let dislikes = self.post.dislikes
            let interactions = likes + dislikes
            let totalReceivers = self.post.receivers
            let newReceivers = self.post.newReceivers
            let rating = self.post.rating
            let recentInteractions = self.post.recentInteractions
//            let timeOfLastDetonation = timeService.getSecondsBetweenNowAndPast(millis: self.post.detonated_at)
            let timeOfLastInteraction = timeService.getSecondsBetweenNowAndPast(millis: self.post.lastInteraction)
            
            if !initial {
                currentInteractions = interactions - recentInteractions
            } else {
                currentInteractions = interactions
            }
            
            participationRate = Double(currentInteractions) / Double(newReceivers)
            
            if interactions > 100 && rating < 0.5 && participationRate > 0.5 {
                
                print("Post is Dead. :(")
                
            } else if interactions > 100 && rating > 0.5 && participationRate > 0.5 {
                
                explode(post: post)
                
            } else if interactions > 100 && participationRate < 0.5 && timeOfLastInteraction > SECONDS_IN_DAY {
                
                explode(post: post)
                
            } else if interactions < 100 && timeOfLastInteraction > SECONDS_IN_DAY {
                
                explode(post: post)
                
            } else if interactions < 100 && rating > 0.5 && participationRate > 0.5 {
                
                explode(post: post)
                
            } else if totalReceivers.count < 100 {
                
                explode(post: post)

            } else {
                print("No Updates At This Time :|")
            }
        }
    }
    
    func explode(post: Dictionary<String,AnyObject>) {
        
        let url = "http://localhost:9000/explode"
        Alamofire.request(url, method: .post, parameters: post, encoding: JSONEncoding.default).responseJSON { response in
            
            print(response.result.value)
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: superview!)
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
            return false
        }
        return false
    }

}
