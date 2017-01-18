//
//  ActivityVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import CoreLocation
import Pulsator
import Firebase
import AVFoundation
import GeoFire
import SCLAlertView
import Alamofire

private var latitude: Double = 0.0
private var longitude: Double = 0.0

class ActivityVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, TableViewCellDelegate, SocialSharingDelegate {
    
    @IBOutlet weak var notificationBtn: UIBarButtonItem!
    @IBOutlet weak var pulseImg: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var categoryFilterBtn: UIButton!
    @IBOutlet weak var postTypeFilterBtn: UIButton!
    
    static var imageCache = NSCache<AnyObject, AnyObject>()
    
    let pulsator = Pulsator()
    let userID = FIRAuth.auth()?.currentUser?.uid
    let iD = UserService.ds.currentUserID
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let postTypeDataSource = ["All","Text","Link","Image","Video","Audio","Quote"]

    var locationService: LocationService!
    var geoFire: GeoFire!
    var currentLocation: [String:AnyObject] = [:]
    var posts = [Post]()
    var currentUser: NSDictionary = [:]
    var audioPlayerItem: AVPlayerItem?
    var audioPlayer: AVPlayer?
    var followingImage: UIImage!
    var notFollowingImage: UIImage!
    var lineView: UIView!
    var comingFromCategoryFilterVC = false
    var comingFromPostTypeFilterVC = false
    var postTypeFilterActive = false
    var categoryFilterActive = false
    var postTypeFilterOption: String!
    var categoryFilterOptions: [String]?
    var previousPostTypeFilterRow: Int!
    var postToPass: Post!
    var userFollowersToPass: String!
    var mediaImageToPass: UIImage?
    var videoDataToPass: NSData?
    var followingImgToPass: UIImage!
    var myGroup = DispatchGroup()
    var userPhotoToPass: UIImage?
    var didJustLogIn: Bool?
    var timer: Timer?
    var comingFromBombVC = false
    var userPhoto: UIImage?
    var filterType = "PostType"
    var activePostType: String!
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    var notifications = [NotificationCustom]()

    override func viewDidLoad() {
        super.viewDidLoad()
                
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        self.view.backgroundColor = SMOKY_BLACK
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        followingImage = UIImage(named: "following-blue")
        notFollowingImage = UIImage(named: "follower-grey")
        
        postTypeFilterBtn.setImage(UIImage(named: "funnel-black-small"), for: .highlighted)
        categoryFilterBtn.setImage(UIImage(named: "category-black-small"), for: .highlighted)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "radar-black.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView
        
        dot = UIView(frame: CGRect(x: 14, y: 16, width: 12, height: 12))
        dot.backgroundColor = UIColor.red
        dot.layer.cornerRadius = dot.frame.size.height / 2
        dot.isHidden = true
        dot.isUserInteractionEnabled = false
        dot.isExclusiveTouch = false
        dot.isHidden = true

        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        button.addSubview(dot)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        locationService = LocationService()
        
        locationService.startTracking()
        
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        notificationService = NotificationService()
        notificationService.getNotifications()
        notificationService.watchRadar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotifications), name: NSNotification.Name(rawValue: "newFollowersNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        tableView.isHidden = true
        
        self.pulsator.radius = 300.0
        self.pulsator.backgroundColor = UIColor(red: 255.0, green: 0, blue: 0, alpha: 1).cgColor
        self.pulsator.animationDuration = 4
        self.pulsator.numPulse = 6
        self.pulsator.pulseInterval = 2
        self.pulseImg.layer.superlayer?.insertSublayer(self.pulsator, below: self.pulseImg.layer)
        self.pulsator.start()
        
        if !comingFromCategoryFilterVC {
            categoryFilterOptions?.removeAll()
            postTypeFilterOption = "All"
            refreshPostFeed()
        }
        
        if !comingFromPostTypeFilterVC {
            postTypeFilterOption = "All"
            activePostType = postTypeFilterOption
            refreshPostFeed()
        }
        
        let currentUserID = UserDefaults.standard.object(forKey: KEY_UID) as! String
        
        URL_BASE.child("users").child(currentUserID).child("photo").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
            
            let userPhotoString = snapshot.value as? String ?? ""
            
            if userPhotoString != "" {
                
                self.userPhoto = ActivityVC.imageCache.object(forKey: userPhotoString as AnyObject) as? UIImage

                if self.userPhoto != nil {
                    self.pulseImg.image = self.userPhoto
                } else {
                    
                    let url = URL(string: userPhotoString)!
                    Alamofire.request(url, method: .get).response { response in
                        if response.error == nil {
                            
                            let img = UIImage(data: response.data!)
                            self.pulseImg.image = img
                            ActivityVC.imageCache.setObject(img!, forKey: userPhotoString as AnyObject)
                            
                        } else {
                            print("\(response.error)")
                        }
                    }
                    self.pulseImg.layer.cornerRadius = self.pulseImg.frame.size.height / 2
                    self.pulseImg.clipsToBounds = true
                }
            } else {
                print("User does not have a profile photo set!")
                self.pulseImg.image = UIImage(named: "user")
            }
        })
        
        getRadarPosts()
        
        URL_BASE.child("users").child(currentUserID).child("following").observe(FIRDataEventType.value, with: { (snapshot) in
            
            let followingUsers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            let cells = self.tableView.visibleCells as? [PostCell] ?? []
            
            if followingUsers.count > 0 {
                var index = 0
                for cell in cells {
                    for user in followingUsers {
                        if cell.post.user_id == user.key {
                            cell.followerBtn.setImage(self.followingImage, for: .normal)
                            break
                        } else {
                            cell.followerBtn.setImage(self.notFollowingImage, for: .normal)
                        }
                    }
                    index += 1
                }
            } else {
                for cell in cells {
                    cell.followerBtn.setImage(self.notFollowingImage, for: .normal)
                }
            }
    
        })
        
        if revealViewController() != nil {
            
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }
    }
    
    func popoverDismissed() {
        
        notificationService.getNotifications()
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
    
    func openSharePostVC(post: Post) {
        
        let sharingVC = self.storyboard?.instantiateViewController(withIdentifier: "SocialSharingVC") as! SocialSharingVC
        sharingVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        sharingVC.post = post
        present(sharingVC, animated: true, completion: nil)
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
    
    override func viewDidAppear(_ animated: Bool) {
    
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pulseImg.layer.layoutIfNeeded()
        pulseImg.layer.cornerRadius = pulseImg.frame.size.width / 2
        pulseImg.clipsToBounds = true
        pulsator.position = pulseImg.layer.position
        shake()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
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
    
    @IBAction func postTypeFilterBtnPressed(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "OptionFilterVC", sender: self)
    }
        
    func postManipulated(post: Post, action: String) {
        
        let index = (posts as NSArray).index(of: post)
        if index == NSNotFound { return }
        
        posts.remove(at: index)
        
        tableView.beginUpdates()
        
        let indexPathForRow = NSIndexPath(row: index, section: 0)
        tableView.deleteRows(at: [indexPathForRow as IndexPath], with: .fade)
        
        tableView.endUpdates()
        
        showScoreView(action: action)
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if posts.count > 0 {
            pulseImg.isHidden = true
            pulsator.stop()
        } else {
            pulseImg.isHidden = false
            if !pulsator.isPulsating {
                pulsator.start()
            }
        }
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if posts.count > 0 {
            
            let post = posts[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell {
                
                cell.request?.cancel()
                
                let userLat = currentLocation["latitude"] as? Double
                let userLong = currentLocation["longitude"] as? Double
                
                var img: UIImage?
                
                if let postImgUrl = post.image {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                } else if let postImgUrl = post.thumbnail {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                }
                
                cell.delegate = self
                cell.sharingDelegate = self

                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "radar", filterType: nil)
                
                return cell
            }
        }
        return PostCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
                return UITableViewAutomaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow
        let currentCell = tableView.cellForRow(at: indexPath!) as! PostCell
        
        userFollowersToPass = currentCell.followersLbl.text!
        postToPass = currentCell.post
        mediaImageToPass = currentCell.postImg.image
        videoDataToPass = currentCell.videoData
        followingImgToPass = currentCell.followerBtn.imageView?.image
        userPhotoToPass = currentCell.profileImg.image
        
        performSegue(withIdentifier: "PostDetailVC", sender: self)
    }
    
    func shake() {
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: pulseImg.center.x - 3, y: pulseImg.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: pulseImg.center.x + 3, y: pulseImg.center.y))
        pulseImg.layer.add(animation, forKey: "position")
    }
    
    func heightForView(_ label:UILabel, text: String, font:UIFont) -> CGFloat {
        
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    func filterPostFeedType() {
        
        if postTypeFilterOption == "All" {
            return
        } else {
            var i = 0
            
            while(posts.count > 0 && i < posts.count) {
                
                var shouldRemoveFromPosts = true
                
                if posts[i].type == postTypeFilterOption.lowercased() {
                    shouldRemoveFromPosts = false
                }
                if shouldRemoveFromPosts {
                    self.posts.remove(at: i)
                } else {
                    i += 1
                }
            }
        }
    }
    
    func filterPostFeedCategories() {
        
        if categoryFilterOptions?.count == 0 || categoryFilterOptions == nil {
            return
        }
        var i = 0
        while(posts.count > 0 && i < posts.count) {
            var shouldRemoveFromPosts = true
            for cat in posts[i].categories {
                for fo in categoryFilterOptions! {
                    if fo == cat {
                        shouldRemoveFromPosts = false
                    }
                }
            }
            if shouldRemoveFromPosts {
                self.posts.remove(at: i)
            } else {
                i += 1
            }
        }
        tableView.reloadData()
    }
    
    func refreshPostFeed() {
        
        self.filterPostFeedType()
        self.filterPostFeedCategories()
    }
    
    func showScoreView(action: String) {
        
        self.scoreView.isHidden = false
        self.scoreView.alpha = 1

        if action == "dislike" {
            self.scoreLbl.textColor = UIColor.red
            self.scoreLbl.text = "-1"
        } else if action == "like" {
            self.scoreLbl.textColor = UIColor.green
            self.scoreLbl.text = "+1"
        }
        UIView.animate(withDuration: 1, animations: {
            self.scoreView.alpha = 0
        }, completion: { finished in
            if !finished {
                return
            }
            self.scoreView.isHidden = true
        })
    }
    
    func getPostImageFromServerAndCache(urlString: String, postType: String) {
        
        let url = URL(string: urlString)!
        Alamofire.request(url, method: .get).response { response in
            if response.error == nil {
                
                let img = UIImage(data: response.data!)
                
                if postType == "image" || postType == "quote" {
                    ActivityVC.imageCache.setObject(img!, forKey: urlString as AnyObject)
                } else if postType == "video" {
                    let imageStruct = ImageStruct()
                    let rotatedImage = imageStruct.imageRotatedByDegrees(oldImage: img!, deg: 90)
                    ActivityVC.imageCache.setObject(rotatedImage, forKey: urlString as AnyObject)
                }
            } else {
                print("\(response.error)")
            }
        }
    }
    
    func getRadarPosts() {
        
        URL_BASE.child("users").child(iD).child("radar").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            self.posts = []
            if let radarPostKeys = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for postKey in radarPostKeys {
                    
                    let key = postKey.key
                    
                    self.myGroup.enter()
                    URL_BASE.child("posts").child(key).observeSingleEvent(of: FIRDataEventType.value, with: { (snap) in
                        
                        if let radarPost = snap.value as? Dictionary<String,AnyObject> {
                            let postKey = radarPost["post_ref"] as! String
                            let post = Post(postKey: postKey, dictionary: radarPost)
                            if post.active {
                                self.posts.append(post)
                            }
                            if post.type == "image" || post.type == "quote" {
                                // will still format quote posts same as image
                                if post.image != nil {
                                    self.getPostImageFromServerAndCache(urlString: post.image!, postType: "image")
                                }
                            } else if post.type == "video" {
                                self.getPostImageFromServerAndCache(urlString: post.thumbnail!, postType: "video")
                            }
                            self.getPosterUserPhotoAndCache(post: post)
                        }
                        self.myGroup.leave()
                    })
                }
                
                self.myGroup.notify(queue: DispatchQueue.main, execute: {
                    
                    if self.posts.count > 0 {
                        self.refreshPostFeed()
                        self.posts = self.posts.sorted(by: { $0.timestamp > $1.timestamp })
                        self.tableView.isHidden = false
                    }
                    let watchObj = [
                        "type": "radar",
                        "read": true,
                        "timestamp": FIRServerValue.timestamp()
                        ] as [String: Any]

                    URL_BASE.child("notifications").child(self.iD).child("watch").updateChildValues(watchObj)
                    self.tableView.reloadData()
                })
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "CategoryFilterVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! CategoryFilterVC
            if categoryFilterOptions != nil && (categoryFilterOptions?.count)! > 0 {
                vC.checked = categoryFilterOptions!
            }
            vC.previousVC = "RadarVC"
        } else if segue.identifier == "PostDetailVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! PostDetailVC
            vC.followers = userFollowersToPass
            vC.post = postToPass
            vC.mediaImage = mediaImageToPass
            vC.followingStatus = followingImgToPass
            vC.userPhotoPostDetail = userPhotoToPass
            vC.previousVC = "RadarVC"
        } else if segue.identifier == "unwindToLoginVC" {
        
            let vC = segue.destination as! LoginVC
            vC.noLocationAccess = true
        } else if segue.identifier == "OptionFilterVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! OptionFilterVC
            vC.filterType = "PostType"
            vC.previousVC = "RadarVC"
            vC.activePostType = self.activePostType
        }
    }
    
    @IBAction func unwindToActivityPost(_ segue: UIStoryboardSegue) {
        
    }

    @IBAction func unwindToActivityVC(_ segue: UIStoryboardSegue) {
        
        if let sourceViewController = segue.source as? CategoryFilterVC {
            self.categoryFilterOptions = sourceViewController.checked
            self.comingFromCategoryFilterVC = sourceViewController.comingFromCategoryVC
            getRadarPosts()
        } else if let sourceViewController = segue.source as? OptionFilterVC {
            self.postTypeFilterOption = sourceViewController.activePostType
            getRadarPosts()
        }
    }
    
    func getPosterUserPhotoAndCache(post: Post) {
        
        URL_BASE.child("users").child(post.user_id).child("photo").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
            
            let userPhotoString = snapshot.value as? String ?? ""
            
            if userPhotoString != "" {
                
                let posterPhoto = ActivityVC.imageCache.object(forKey: post.user_id as AnyObject) as? UIImage
                
                if posterPhoto == nil {
                    
                    let url = URL(string: userPhotoString)!
                    Alamofire.request(url, method: .get).response { response in
                        if response.error == nil {
                            
                            let img = UIImage(data: response.data!)
                            ActivityVC.imageCache.setObject(img!, forKey: post.user_id as AnyObject)
                            
                        } else {
                            print("\(response.error)")
                        }
                    }
                }
            } else {
                print("User does not have a photo set.")
            }
        })
    }
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }

}
