//
//  RadarVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/4/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import GeoFire
import Alamofire

private var latitude = 0.0
private var longitude = 0.0
//ADD DELEGATE THAT UPDATES POST IN ARRAY THA WAS LIKED OR DISLIKED SO THAT WHEN IT SHOWS AGAIN IT IS CORRECT
//add setter for likes,dislikes in post model and set new likes and dislikes on object used after delegate in postcell passes which post what changed and then will update post in array accordingly

class RadarVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ActivityTableViewCellDelegate, SocialSharingDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var noPostsLbl: UILabel!
    @IBOutlet weak var noPostsImageView: UIImageView!
    
    let userID = FIRAuth.auth()?.currentUser?.uid
    let iD = UserService.ds.currentUserID
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var linkObj: [String:AnyObject] = [:]
    var posts = [Post]()
    var currentUser: NSDictionary = [:]
    var followingImage: UIImage!
    var notFollowingImage: UIImage!
    var myGroup = DispatchGroup()
    var currentUserID: String!
    var postToPass: Post!
    var userFollowersToPass: String!
    var mediaImageToPass: UIImage?
    var videoDataToPass: NSData?
    var userPhotoToPass: UIImage?
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
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "pulse-black.png")
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
        button.addTarget(self, action: #selector(self.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        button.addSubview(dot)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton

        geoFire = GeoFire(firebaseRef: geofireRef)
        
        notificationService = NotificationService()
        notificationService.getNotifications()
        notificationService.watchRadar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotifications), name: NSNotification.Name(rawValue: "newFollowersNotification"), object: nil)
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        noPostsLbl.isHidden = true
        noPostsImageView.isHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        tableView.isHidden = true
        
        followingImage = UIImage(named: "following-blue")
        notFollowingImage = UIImage(named: "follower-grey")
        
        currentUserID = UserDefaults.standard.object(forKey: KEY_UID) as! String
        
        getAllFollowingUsers()
        
        URL_BASE.child("users").child(currentUserID).child("following").observe(FIRDataEventType.value, with: { (snapshot) in
            
            let followingUsers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            if followingUsers.count > 0 && self.posts.count > 0 {
                
                var isUserFollowing = false
                for i in 0...self.posts.count - 1 {
                    isUserFollowing = false
                    for user in followingUsers {
                        if user.key == self.posts[i].user_id {
                            isUserFollowing = true
                            break
                        }
                    }
                    if !isUserFollowing {
                        self.posts.remove(at: i)
                        break
                    }
                }
            }
            if followingUsers.count == 0 {
                self.posts = []
                self.noPostsLbl.isHidden = false
                self.noPostsImageView.isHidden = false
            }
            self.tableView.reloadData()
        })
        
        //Burger side menu
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
    
    func openSharePostVC(post: Post) {
        
        let sharingVC = self.storyboard?.instantiateViewController(withIdentifier: "SocialSharingVC") as! SocialSharingVC
        sharingVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        sharingVC.post = post
        present(sharingVC, animated: true, completion: nil)
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
    }
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }

    func postAction(action: String) {

        showScoreView(action: action)
    }
    
    func updatePostInArray(post: Post) {
        
        for p in posts {
            if p.user_id == post.user_id {
                p.dislikes = post.dislikes
                p.likes = post.likes
            }
        }
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow
        let currentCell = tableView.cellForRow(at: indexPath!) as! PostCell
        
        userFollowersToPass = currentCell.followersLbl.text!
        postToPass = currentCell.post
        mediaImageToPass = currentCell.postImg.image
        videoDataToPass = currentCell.videoData
        userPhotoToPass = currentCell.profileImg.image
        
        performSegue(withIdentifier: "PostDetailVC", sender: self)
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if posts.count > 0 {
            let post = posts[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell {
                
                cell.request?.cancel()
                
                let userLat = currentLocation["latitude"] as? Double
                let userLong = currentLocation["longitude"] as? Double
                
                var img: UIImage?
                
                if let url = post.image {
                    img = ActivityVC.imageCache.object(forKey: url as AnyObject) as? UIImage
                } else if let url = post.thumbnail {
                    img = ActivityVC.imageCache.object(forKey: url as AnyObject) as? UIImage
                }
                
                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "activity", filterType: nil)
                
                cell.sharingDelegate = self
                cell.activityDelegate = self
                
                return cell
            } else {
                return PostCell()
            }
        }
        return PostCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
    
    func getAllFollowingUsers() {
        
        URL_BASE.child("users").child(currentUserID).child("following").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            let followingUsers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            if followingUsers.count > 0 {
                
                self.posts = []
                for user in followingUsers {
                    
                    self.myGroup.enter()
                    let userRecentPost = URL_BASE.child("posts").queryOrdered(byChild: "user_id").queryEqual(toValue: user.key).queryLimited(toLast: 3)
                    userRecentPost.observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                        
                        let postObjects = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                        for post in postObjects {
                            let postDict = post.value as? Dictionary<String,AnyObject>
                            let post = Post(postKey: post.key, dictionary: postDict!)
                            self.posts.append(post)
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
                        self.posts = self.posts.sorted(by: { $0.timestamp > $1.timestamp })
                        self.tableView.reloadData()
                        self.tableView.isHidden = false
                    } else {
                        self.noPostsLbl.isHidden = false
                        self.noPostsImageView.isHidden = false
                    }
                })
                
            } else {
                self.posts = []
                self.noPostsLbl.isHidden = false
                self.noPostsImageView.isHidden = false
                self.tableView.reloadData()
            }
            
        })
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
    
    @IBAction func unwindToRadarPost(_ segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "PostDetailVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! PostDetailVC
            vC.followers = userFollowersToPass
            vC.post = postToPass
            vC.mediaImage = mediaImageToPass
            vC.userPhotoPostDetail = userPhotoToPass
            vC.previousVC = "ActivityVC"
        }
    }

}
