
import UIKit
import SwiftLinkPreview
import Alamofire
import AVFoundation
import AVKit
import Firebase

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
    let font = UIFont(name: "Ubuntu", size: 12.0)
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        followingImage = UIImage(named: "following-blue")
        notFollowingImage = UIImage(named: "follower")
        
        self.userPhotoImageView.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        
        if userPhotoPostDetail != nil {
            self.userPhotoImageView.image = userPhotoPostDetail
            self.userPhotoImageView.layer.cornerRadius = self.userPhotoImageView.frame.size.height / 2
            self.userPhotoImageView.clipsToBounds = true
        }
        
        visitSiteBtn.layer.cornerRadius = 3
        visitSiteBtn.isHidden = true
        hideAudioControls()
        
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

        
        usernameLbl.text = post.username
        followersLbl.text = followers
        likesLbl.text = String(post.likes) + " Likes"
        dislikesLbl.text = String(post.dislikes) + " Dislikes"
        interactionsLbl.text = String(post.likes + post.dislikes) + " Interactions"
        distanceLbl.text = "\(post.distance) Miles Traveled"
        
        if followingStatus == followingImage || previousVC == "ActivityVC" {
            self.followBtn.setImage(followingImage, for: .normal)
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
            
            backgroundImageView.image = UIImage(named: "audio-bg")
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
        
        print(categoryImages)
        if categoryImages.count == 1 {
            self.categoryImageViewOne.isHidden = true
            self.categoryImageViewTwo.image = UIImage(named: categoryImages[0])
        } else {
            self.categoryImageViewOne.isHidden = false
            self.categoryImageViewTwo.isHidden = false
            self.categoryImageViewTwo.image = UIImage(named: categoryImages[0])
            self.categoryImageViewOne.image = UIImage(named: categoryImages[1])
        }
        
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
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(PostDetailVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
//        if (messageLbl != nil) && messageLbl.text! != "" {
//
//            let height = heightForView(messageLbl, text: messageLbl.text!, font: font!)
//            messageLbl.frame.size.height = height
//            NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
//        } else {
//            messageLbl.frame.size.height = 0.0
//            NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
//        }
        
    }
    
    func notificationBtnPressed() {
        
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
        
        print(1)

        let followingUsers = URL_BASE.child("users").child(currentUserID).child("following")
        let followingUser = URL_BASE.child("users").child(post.user_id).child("followers")
        
        let followingObj = [self.post.user_id: true]
        let followerObj = [currentUserID: true]
        
        if followBtn.imageView?.image == notFollowingImage {
            print(3)
            followingUsers.updateChildValues(followingObj)
            followingUser.updateChildValues(followerObj)
            followBtn.setImage(followingImage, for: .normal)
            
        } else if followBtn.imageView?.image == followingImage {
            print(4)
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
