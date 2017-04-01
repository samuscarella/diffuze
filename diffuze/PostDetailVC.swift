
import UIKit
import SwiftLinkPreview
import Alamofire
import AVFoundation
import AVKit
import Firebase
import GeoFire

private var latitude = 0.0
private var longitude = 0.0

class PostDetailVC: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var followersLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var dislikesLbl: UILabel!
    @IBOutlet weak var interactionsLbl: UILabel!
    @IBOutlet weak var likesDotView: UIView!
    @IBOutlet weak var dislikesDotView: UIView!
    @IBOutlet weak var interactionDotView: UIView!
    @IBOutlet weak var linkTitleLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var audioSlider: UISlider!
    @IBOutlet weak var restartAudioBtn: UIButton!
    @IBOutlet weak var playAudioBtn: UIButton!
    @IBOutlet weak var audioTimeLbl: UILabel!
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var audioTitleLbl: UILabel!
    @IBOutlet weak var followBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var distanceDotView: UIView!
    @IBOutlet weak var categoryImageViewOne: UIImageView!
    @IBOutlet weak var categoryImageViewTwo: UIImageView!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mediaViewHeight: NSLayoutConstraint!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var visitSiteBtn: MaterialButton!
    @IBOutlet weak var playVideoBtn: UIButton!
    
    let currentUserID = UserDefaults.standard.object(forKey: KEY_UID) as! String
    let currentUserUsername = UserDefaults.standard.object(forKey: KEY_USERNAME) as! String
    let font = UIFont(name: "Ubuntu", size: 12.0)
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let iD = UserService.ds.currentUserID
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var avPlayerViewController = AVPlayerViewController()
    var avPlayer:AVPlayer? = nil
    var post: Post!
    var userPhotoPostDetail: UIImage?
    var mediaImage: UIImage?
    var followers: String!
    var linkUrlString: String?
    var videoData: NSData?
    var request: Request?
    var player: AVPlayer?
    var audioPlayer: AVAudioPlayer?
    var previousVC: String!
    var updater: CADisplayLink! = nil
    var followingImage: UIImage?
    var notFollowingImage: UIImage?
    var followingStatus: UIImage!
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    var notifications = [NotificationCustom]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        UIApplication.shared.statusBarStyle = .lightContent
        
        followingImage = UIImage(named: "following-blue")
        notFollowingImage = UIImage(named: "follower")
        
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
        
        self.userPhotoImageView.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        
        if userPhotoPostDetail != nil {
            self.userPhotoImageView.image = userPhotoPostDetail
            self.userPhotoImageView.layer.cornerRadius = self.userPhotoImageView.frame.size.height / 2
            self.userPhotoImageView.clipsToBounds = true
        }
        
        visitSiteBtn.layer.cornerRadius = 3
        visitSiteBtn.isHidden = true
        hideAudioControls()
        
        likesDotView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        likesDotView.layer.cornerRadius = likesDotView.frame.size.height / 2
        dislikesDotView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        dislikesDotView.layer.cornerRadius = dislikesDotView.frame.size.height / 2
        interactionDotView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        interactionDotView.layer.cornerRadius = interactionDotView.frame.size.height / 2
        distanceDotView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        distanceDotView.layer.cornerRadius = distanceDotView.frame.size.height / 2
        
        categoryImageViewOne.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        categoryImageViewTwo.frame = CGRect(x: 0, y: 0, width: 36, height: 36)

        categoryImageViewOne.layer.cornerRadius = categoryImageViewOne.frame.size.height / 2
        categoryImageViewOne.clipsToBounds = true
        
        categoryImageViewTwo.layer.cornerRadius = categoryImageViewTwo.frame.size.height / 2
        categoryImageViewTwo.clipsToBounds = true

        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.clear
        let logo = UIImage(named: "detail.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView

        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        NotificationCenter.default.addObserver(self, selector: #selector(PostDetailVC.updateViews), name: NSNotification.Name(rawValue: "messageHeightUpdated"), object: nil)
        
        dot = UIView(frame: CGRect(x: 14, y: 16, width: 12, height: 12))
        dot.backgroundColor = UIColor.red
        dot.layer.cornerRadius = dot.frame.size.height / 2
        dot.isHidden = true
        dot.isUserInteractionEnabled = false
        dot.isExclusiveTouch = false
        dot.isHidden = true
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(self.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        button.addSubview(dot)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        notificationService = NotificationService()
        notificationService.getNotifications()
        notificationService.watchRadar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotifications), name: NSNotification.Name(rawValue: "newFollowersNotification"), object: nil)
    }
    
    func popoverDismissed() {
        
        notificationService.getNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        URL_BASE.child("posts").child(post.postKey).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            
            if var post = currentData.value as? [String : AnyObject], let uid = FIRAuth.auth()?.currentUser?.uid {
                
                let viewObj = [
                    self.currentUserID: true
                ]
                
                var viewCount = post["viewCount"] as? Int ?? 0
                let viewsDict = post["views"] as? [String : Bool] ?? [:]
                
                if viewsDict[uid] == nil {
                    URL_BASE.child("posts").child(self.post.postKey).child("views").updateChildValues(viewObj)
                    viewCount += 1
                }
                
                post["viewCount"] = viewCount as AnyObject?
                post["views"] = viewsDict as AnyObject?
                
                currentData.value = post
                
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        let miles = Double(post.distance) * 0.000621371
        
        var finalDistance: Double
        
        if miles < 1 {
            finalDistance = 1
        } else {
            finalDistance = round(miles)
        }
        let intFinalDistance = Int(finalDistance)
        
        usernameLbl.text = post.username
        followersLbl.text = followers
        likesLbl.text = String(post.likes) + " Likes"
        dislikesLbl.text = String(post.dislikes) + " Dislikes"
        interactionsLbl.text = String(post.likes + post.dislikes) + " Interactions"
        distanceLbl.text = "\(intFinalDistance) Miles Traveled"
        
        if followingStatus == followingImage || previousVC == "ActivityVC" {
            self.followBtn.setImage(followingImage, for: .normal)
        } else if previousVC == "ViralVC" {
            
            URL_BASE.child("users").child(currentUserID).child("following").observeSingleEvent(of: FIRDataEventType.value, with: {
                snapshot in
                
                let followingUsers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                if followingUsers.count > 0 {
                    
                    var isFollowing = false
                    for user in followingUsers {
                        if user.key == self.post.user_id {
                            self.followBtn.setImage(self.followingImage, for: .normal)
                            isFollowing = true
                        }
                    }
                    if !isFollowing {
                        self.followBtn.setImage(self.notFollowingImage, for: .normal)
                    }
                } else {
                    self.followBtn.setImage(self.notFollowingImage, for: .normal)
                }
            })
        } else {
            self.followBtn.setImage(notFollowingImage, for: .normal)
        }
        
        if post.user_id == currentUserID {
            self.followBtn.setImage(UIImage(named: "neutral-white"), for: .normal)
            self.followBtn.isUserInteractionEnabled = false
        }
        
        if post.type != "link" {
            
            linkTitleLbl.isHidden = true
        }
        if post.type == "text" {
            
            backgroundImageView.image = UIImage(named: "text-bg")
            messageLbl.text = post.message
            mediaViewHeight.constant = 0
            mediaImageView.isHidden = true
            playVideoBtn.isHidden = true
        }
        if post.type == "link" {
            
            backgroundImageView.image = UIImage(named: "link-bg")
            visitSiteBtn.isHidden = false
            playVideoBtn.isHidden = true
            linkTitleLbl.text = post.title
            if mediaImage != nil {
                self.mediaImageView.image = mediaImage
                self.mediaImageView.clipsToBounds = true
            }
            if let msg = post.message {
                self.messageLbl.text = msg
            } else {
                self.messageLbl.text = ""
            }
            if let urlString = post.url {
                linkUrlString = urlString
            }
        }
        if post.type == "image" {
            
            backgroundImageView.image = UIImage(named: "image-bg")
            playVideoBtn.isHidden = true
            
            if mediaImage != nil {
                mediaImageView.image = mediaImage
                mediaImageView.clipsToBounds = true
            }
            if let message = post.message {
                messageLbl.text = message
            } else {
                messageLbl.text = ""
            }
        } else if post.type == "video" {
            
            backgroundImageView.image = UIImage(named: "video-bg")
            if mediaImage != nil {
                mediaImageView.image = mediaImage
                mediaImageView.clipsToBounds = true
            }
            
            if let message = post.message {
                messageLbl.text = message
            } else {
                messageLbl.text = ""
            }
            
            let url = URL(string: post.video!)!
            let player = AVPlayer(url: url)
            avPlayerViewController = AVPlayerViewController()
            avPlayerViewController.player = player
            
        } else if post.type == "audio" {
            
            backgroundImageView.image = UIImage(named: "audio-bg-2")
            mediaImageView.isHidden = true
            messageLbl.isHidden = true
            playVideoBtn.isHidden = true
            showAudioControls()
            
            audioTitleLbl.text = post.title
            audioSlider.minimumValue = 0
            audioSlider.maximumValue = 100
            
            if let linkUrl = NSURL(string: post.audio!) {
                URLSession.shared.dataTask(with: linkUrl as URL, completionHandler: { (data, response, error) -> Void in
                    
                    DispatchQueue.main.async {
                        
                        if let data = data {
                            
                            do {
                                try self.audioPlayer = AVAudioPlayer(data: data)
                                
                                self.audioPlayer?.prepareToPlay()
                                self.updateSliderWithAudio()
                                self.audioPlayer?.delegate = self
                                let dFormat = "%02d"
                                let min: Int = Int((Double((self.audioPlayer?.duration)!) - (self.audioPlayer?.currentTime)!) / 60)
                                let sec: Int = Int((Double((self.audioPlayer?.duration)!) - (self.audioPlayer?.currentTime)!).truncatingRemainder(dividingBy: 60.0))
                                let string = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
                                self.audioTimeLbl.text = string
                                
                            } catch let err as NSError {
                                print(err.debugDescription)
                            }
                            
                            // there is data. do this
                        } else if error != nil {
                            print(error)
                        }
                    }
                }).resume()
            }
            
            audioSlider.value = 1
            
        } else if post.type == "quote" {
            
            backgroundImageView.image = UIImage(named: "quote-bg")
            playVideoBtn.isHidden = true
            if post.quoteType == "image" {
                
                if mediaImage != nil {
                    mediaImageView.image = mediaImage
                    mediaImageView.clipsToBounds = true
                }
                self.messageLbl.text = ""
            } else if post.quoteType == "text" {
                
                mediaViewHeight.constant = 0
                mediaImageView.isHidden = true
                self.messageLbl.text = post.text
                self.messageLbl.font = UIFont(name: self.messageLbl.font.fontName, size: 16)
            }
        }
        
        var categoryImages = [String]()
        for name in post.categories {
            if name == "Do-It-Yourself" {
                categoryImages.append("do-it-yourself")
            } else if name == "Religion & Spirituality" {
                categoryImages.append("religion-spirituality")
            } else if name == "Social Media" {
                categoryImages.append("social-media")
            } else {
                categoryImages.append(name.lowercased())
            }
        }
        
        if categoryImages.count == 1 {
            self.categoryImageViewOne.isHidden = true
            self.categoryImageViewTwo.image = UIImage(named: categoryImages[0])
        } else {
            self.categoryImageViewOne.isHidden = false
            self.categoryImageViewTwo.isHidden = false
            self.categoryImageViewTwo.image = UIImage(named: categoryImages[0])
            self.categoryImageViewOne.image = UIImage(named: categoryImages[1])
        }
    }
    
    func updateNotifications(notification: NSNotification) {
        
        self.notifications = []
        let incomingNotifications = notification.object as! [NotificationCustom]
        self.notifications = incomingNotifications
        var newNotifications = false
        for n in notifications {
            if n.read == false {
                newNotifications = true
                dot.isHidden = false
                break
            }
        }
        if !newNotifications {
            dot.isHidden = true
        }
        print("Updated Notifications From Followers: \(self.notifications)")
    }
    
    func notificationBtnPressed() {
        
        let notificationVC = self.storyboard?.instantiateViewController(withIdentifier: "NotificationVC") as! NotificationVC
        notificationVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        notificationVC.notifications = self.notifications
        present(notificationVC, animated: true, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &latitude {
            latitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["latitude"] = latitude as AnyObject?
        }
        if context == &longitude {
            longitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["longitude"] = longitude as AnyObject?
        }
    }
    
    func updateUserLocation() {
        
        if currentLocation["latitude"] != nil && currentLocation["longitude"] != nil {
            
            geoFire.setLocation(CLLocation(latitude: (currentLocation["latitude"] as? CLLocationDegrees)!, longitude: (currentLocation["longitude"] as? CLLocationDegrees)!), forKey: iD)
            
            if UserService.ds.REF_USER_CURRENT != nil {
                let longRef = UserService.ds.REF_USER_CURRENT?.child("longitude")
                let latRef = UserService.ds.REF_USER_CURRENT?.child("latitude")
                
                longRef?.setValue(currentLocation["longitude"])
                latRef?.setValue(currentLocation["latitude"])
            }
            print(currentLocation)
        }
    }
    
    func terminateAuthentication() {
        
        do {
            try FIRAuth.auth()!.signOut()
            self.performSegue(withIdentifier: "unwindToLoginVC", sender: self)
        } catch let err as NSError {
            print(err)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        timer?.invalidate()
        timer = nil
    }

    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }

    func updateSliderWithAudio() {
        updater = CADisplayLink(target: self, selector: #selector(PostDetailVC.trackAudio))
        updater.frameInterval = 1
        updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        updateViews()
    }
    
    func updateViews()  {
        
        var totalHeight: CGFloat = 0
//
        for subView in contentView.subviews {
            totalHeight += subView.frame.size.height
        }
        contentViewHeight.constant = totalHeight
    }
    
    @IBAction func visitSiteBtnPressed(_ sender: AnyObject) {
        
        var urlString: String!
        if !(linkUrlString?.hasPrefix("http"))! {
            urlString = "http://" + linkUrlString!
        } else {
            urlString = linkUrlString!
        }
        if UIApplication.shared.openURL(URL(string: urlString)!) {
            print("Opened in browser...")
        } else {
            print("Url is invalid.")
        }
    }
    
    @IBAction func shareBtnPressed(_ sender: AnyObject) {
        
        let sharingVC = self.storyboard?.instantiateViewController(withIdentifier: "SocialSharingVC") as! SocialSharingVC
        sharingVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        sharingVC.post = post
        present(sharingVC, animated: true, completion: nil)
    }
    
    
    @IBAction func restartBtnPressed(_ sender: AnyObject) {
        
        audioPlayer?.stop()
        let playImage = UIImage(named: "play-button")
        playAudioBtn.setImage(playImage, for: .normal)
        updater.invalidate()
        audioSlider.value = 1
        audioPlayer?.currentTime = 0
        updateDuration()
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        
        if previousVC == "RadarVC" {
            
            self.performSegue(withIdentifier: "unwindToActivityVC", sender: self)
        } else if previousVC == "ActivityVC" {
            
            self.performSegue(withIdentifier: "unwindToRadarPost", sender: self)
        } else if previousVC == "MyInfoVC" {
            
            self.performSegue(withIdentifier: "unwindToMyInfoVC", sender: self)
        } else if previousVC == "ViralVC" {
            
            self.performSegue(withIdentifier: "unwindToViralVC", sender: self)
        }
    }
    
    @IBAction func followPosterBtnPressed(_ sender: AnyObject) {
        
        let followingUsers = URL_BASE.child("users").child(currentUserID).child("following")
        let followingUser = URL_BASE.child("users").child(post.user_id).child("followers")
        let notification = URL_BASE.child("notifications").child(post.user_id)
        
        let followingObj = [self.post.user_id: true]
        let followerObj = [currentUserID: true]

        let notificationObj = [
            "username": currentUserUsername,
            "read": false,
            "status": true,
            "type": "follower",
            "timestamp": FIRServerValue.timestamp()
            ] as [String : Any]

        if followBtn.imageView?.image == notFollowingImage {
            
            notification.child(currentUserID).updateChildValues(notificationObj)

            followingUsers.updateChildValues(followingObj)
            followingUser.updateChildValues(followerObj)
            followBtn.setImage(followingImage, for: .normal)
            
        } else if followBtn.imageView?.image == followingImage {

            notification.child(currentUserID).child("status").setValue(false)
            
            followingUsers.child(self.post.user_id).removeValue()
            followingUser.child(currentUserID).removeValue()
            
            followBtn.setImage(notFollowingImage, for: .normal)
        }
    }
    
    @IBAction func playAudioBtnPressed(_ sender: AnyObject) {
        
        if (audioPlayer?.isPlaying)! {
            audioPlayer?.pause()
            let playImage = UIImage(named: "play-button")
            playAudioBtn.setImage(playImage, for: .normal)
        } else if audioPlayer != nil && !(audioPlayer?.isPlaying)! {
            playAudio()
            updateSliderWithAudio()
            Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(PostDetailVC.updateDurationLbl(timer:)), userInfo: nil, repeats: true)
            
        }
    }
    
    func trackAudio() {
        if audioPlayer != nil {
            let normalizedTime = Float((audioPlayer?.currentTime)! * 100.0 / (audioPlayer?.duration)!)
            audioSlider.value = normalizedTime
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        let playImage = UIImage(named: "play-button")
        playAudioBtn.setImage(playImage, for: .normal)
        updater.invalidate()
        audioSlider.value = 1
        updateDuration()
        
    }
    
    func updateDurationLbl(timer: Timer) {
        if audioPlayer == nil {
            return
        }
        if (audioPlayer?.isPlaying)! {
            updateDuration()
        }
    }
    
    func updateDuration() {
        let dFormat = "%02d"
        let min: Int = Int((Double((audioPlayer?.duration)!) - (audioPlayer?.currentTime)!) / 60)
        let sec: Int = Int((Double((audioPlayer?.duration)!) - (audioPlayer?.currentTime)!).truncatingRemainder(dividingBy: 60.0))
        let string = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
        audioTimeLbl.text = string
    }
    
    func playAudio() {
        audioPlayer?.play()
        let pauseImage = UIImage(named: "pause-button")
        playAudioBtn.setImage(pauseImage, for: .normal)
    }

    @IBAction func playVideoBtnPressed(_ sender: AnyObject) {
        
        self.present(self.avPlayerViewController, animated: true) { () -> Void in
            self.avPlayerViewController.player?.play()
        }
    }
    
//    func getVideoDataFromServer() {
//        
//        if let video = post.video! as String? {
//            
//        }
//    }

    func hideAudioControls() {
        
        audioTitleLbl.isHidden = true
        audioSlider.isHidden = true
        audioTimeLbl.isHidden = true
        restartAudioBtn.isHidden = true
        playAudioBtn.isHidden = true
    }
    
    func showAudioControls() {
        
        audioTitleLbl.isHidden = false
        audioSlider.isHidden = false
        audioTimeLbl.isHidden = false
        restartAudioBtn.isHidden = false
        playAudioBtn.isHidden = false
    }
    
    func heightForView(_ label:UILabel, text: String, font:UIFont) -> CGFloat {
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    

}
