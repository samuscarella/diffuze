
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

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol TableViewCellDelegate {

    func postDeleted(post: Post, action: String)
}
protocol ActivityTableViewCellDelegate {
    
    func postAction(action: String)
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
    let geofireRef = URL_BASE.child("user-locations")

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
    var postType: String!
    
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
    
    func configureCell(_ post: Post, currentLocation: Dictionary<String, AnyObject>?, image: UIImage?, postType: String) {
        
        self.post = post
        self.username.text = post.username
        self.postType = postType
        
        let score = post.likes - post.dislikes
        if score == 0 {
            self.postScoreLbl.textColor = GOLDEN_YELLOW
        } else if score > 0 {
            self.postScoreLbl.textColor = UIColor.green
        } else {
            self.postScoreLbl.textColor = AUBURN_RED
        }
        self.postScoreLbl.text = "\(score)"
        
        let date = NSDate()
        let millisecondsDateOfPost = post.timestamp
        let millisecondsDateOfNow = date.timeIntervalSince1970 * 1000
        let millis = millisecondsDateOfNow - Double(millisecondsDateOfPost)
        let timeService = TimeService()
        self.timestamp.text = timeService.getTimeStampFromMilliSeconds(millis: millis)
        
        let geoFire = GeoFire(firebaseRef: geofireRef)!
        
        geoFire.getLocationForKey(currentUserID, withCallback: { (location, error) in
            if (error != nil) {
                print("An error occurred getting the location for \"firebase-hq\": \(error?.localizedDescription)")
            } else if (location != nil) {
                print("Location for current user is [\(location?.coordinate.latitude), \(location?.coordinate.longitude)]")
                var locationDict: Dictionary<String,AnyObject> = [:]
                locationDict["latitude"] = location?.coordinate.latitude as AnyObject?
                locationDict["longitude"] = location?.coordinate.longitude as AnyObject?
                let location = Location()
                self.distanceAway.text = location.getDistanceBetweenUserAndPost(locationDict, post: post)
            } else {
                print("GeoFire does not contain a location for \"firebase-hq\"")
            }
        })
        
        undoQuoteDisplay()
        URL_BASE.child("users").child(self.post.user_id).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            let userDict = snapshot.value as? Dictionary<String, AnyObject> ?? [:]
            let key = userDict["user_ref"] as! String
            let user = User.init(userId: key, dictionary: userDict)
            
            if let userPhoto = user.userPhoto {
                let photoCheck = ActivityVC.imageCache.object(forKey: userPhoto as AnyObject) as? UIImage
                print(photoCheck)
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
        
        //This should be eventually done on post creation.
        trimmedMessage = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        //Constraints
        self.linkViewHeight.constant = 0
        self.audioViewHeight.constant = 0
        
        //Set Message Label
        let height = heightForView(self.message, text: trimmedMessage!)
        self.messageHeight.constant = height
        self.message.text = trimmedMessage
        self.message.font = UIFont(name: self.message.font.fontName, size: 12)
    }
    
    func setDynamicLinkCell(linkTitle: String?, message: String?, image: UIImage?) {
        
        if image != nil {
            self.postImg.image = image
        } else if let postImage = post.image as String? {
                
            getPostImageFromServer(urlString: postImage, postType: "image")
        }
        
        configureMediaViewUI()

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
            self.message.textColor = UIColor.black
            self.message.text = trimmedMessage
            self.message.font = UIFont(name: message.font.fontName, size: 14)
            let height = heightForView(message, text: trimmedMessage)
            self.messageHeight.constant = height
            
            self.postImg.isHidden = true
            openQuote?.isHidden = false
            closeQuote?.isHidden = false
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
    
    @IBAction func followersBtnPressed(_ sender: AnyObject) {
        
        let followingUsers = URL_BASE.child("users").child(currentUserID).child("following")
        let followingUser = URL_BASE.child("users").child(post.user_id).child("followers")
        
        let followingObj = [self.post.user_id: true]
        let followerObj = [currentUserID: true]

        if followerBtn.imageView?.image == notFollowingImage {
            
            followingUsers.updateChildValues(followingObj)
            followingUser.updateChildValues(followerObj)
            followerBtn.setImage(followingImage, for: .normal)
        } else if followerBtn.imageView?.image == followingImage {
            
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
        
        if self.postType != "myinfo" {
            
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
                
                let originalFrame = CGRect(x: 0, y: frame.origin.y,
                                           width: bounds.size.width, height: bounds.size.height)
                if deleteOnDragRelease {
                    
                    if delegate != nil || activityDelegate != nil && post != nil {
                        
                        if self.postType == "activity" {
                            activityDelegate!.postAction(action: "dislike")
                            self.neutralImageView.image = UIImage(named: "red-checkmark")
                        } else if self.postType == "radar" {
                            delegate!.postDeleted(post: post!, action: "dislike")
                        }
                    }
                }
                if likeOnDragRelease {
                    
                    if delegate != nil || activityDelegate != nil && post != nil {
                        
                        if self.postType == "activity" {
                            activityDelegate!.postAction(action: "like")
                            self.neutralImageView.image = UIImage(named: "green-checkmark")
                        } else if self.postType == "radar" {
                            delegate!.postDeleted(post: post!, action: "like")
                        }
                    }
                }
                if !deleteOnDragRelease && !likeOnDragRelease || self.postType == "activity" {
                    
                    UIView.animate(withDuration: 0.2, animations: {self.frame = originalFrame})
                }
            }
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
