//
//  MyInfoVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/10/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import GeoFire
import Alamofire

private var latitude: Double = 0.0
private var longitude: Double = 0.0

class MyInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource, TableViewCellDelegate, ActivityTableViewCellDelegate, SocialSharingDelegate {
    
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var personalFilterBtn: UIButton!
    @IBOutlet weak var postTypeFilterBtn: UIButton!
    @IBOutlet weak var categoryFilterBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var noPostsLbl: UILabel!
    @IBOutlet weak var noPostsImageView: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    
    let personalDataSource = ["My Posts","Liked","Disliked"]
    let postTypeDataSource = ["All","Text","Link","Image","Video","Audio","Quote"]
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let iD = UserService.ds.currentUserID
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var posts = [Post]()
    var personalFilterOption: String!
    var postTypeFilterOption: String!
    var categoryFilterOptions: [String]?
    var personalFilterActive = false
    var postTypeFilterActive = false
    var categoryFilterActive = false
    var myGroup = DispatchGroup()
    var previousPersonalFilterRow: Int!
    var previousPostTypeFilterRow: Int!
    var comingFromCategoryFilterVC = false
    var comingFromPersonalFilterVC = false
    var comingFromPostTypeFilterVC = false
    var userFollowersToPass: String!
    var mediaImageToPass: UIImage?
    var videoDataToPass: NSData?
    var followingImgToPass: UIImage!
    var postToPass: Post!
    var userPhotoToPass: UIImage?
    var activePostType: String!
    var activePersonalOption: String!
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    var notifications = [NotificationCustom]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        personalFilterBtn.setImage(UIImage(named: "star-black"), for: .highlighted)
        postTypeFilterBtn.setImage(UIImage(named: "funnel-black-small"), for: .highlighted)
        categoryFilterBtn.setImage(UIImage(named: "category-black-small"), for: .highlighted)
        
        noPostsLbl.isHidden = true
        noPostsImageView.isHidden = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "folder-black.png")
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
        button.addTarget(self, action: #selector(MyInfoVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.addSubview(dot)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        
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

        if !comingFromCategoryFilterVC || !comingFromPersonalFilterVC {
            categoryFilterOptions?.removeAll()
            personalFilterOption = "My Posts"
            postTypeFilterOption = "All"
            activePostType = postTypeFilterOption
            activePersonalOption = personalFilterOption
            refreshPostFeed()
        }
        
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
    
    func openSharePostVC(post: Post) {
        
        let sharingVC = self.storyboard?.instantiateViewController(withIdentifier: "SocialSharingVC") as! SocialSharingVC
        sharingVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        sharingVC.post = post
        present(sharingVC, animated: true, completion: nil)
    }
    
    func postManipulated(post: Post, action: String) {

        let  index = (posts as NSArray).index(of: post)
        if index == NSNotFound { return }
        
        posts.remove(at: index)
        
        tableView.beginUpdates()
        let indexPathForRow = NSIndexPath(row: index, section: 0)
        tableView.deleteRows(at: [indexPathForRow as IndexPath], with: .fade)
        
        tableView.endUpdates()
        
        showScoreView(action: action)
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if posts.count == 0 {
            noPostsLbl.isHidden = false
            noPostsImageView.isHidden = false
        } else {
            noPostsLbl.isHidden = true
            noPostsImageView.isHidden = true
        }
        
        if personalFilterOption == "My Posts" {
            
            if postTypeFilterOption == "All" && posts.count == 0 {
                noPostsLbl.text = "You have not created any posts"
                noPostsImageView.image = UIImage(named: "folder")
            } else {
                getNoPostTypeMessage()
            }
        } else if personalFilterOption == "Liked" && posts.count == 0 {
            
            if postTypeFilterOption == "All" {
                noPostsLbl.text = "You have not liked any posts"
                noPostsImageView.image = UIImage(named: "plus-white")
            } else {
                getNoPostTypeMessage()
            }
        } else if personalFilterOption == "Disliked" && posts.count == 0 {
                
            if postTypeFilterOption == "All" {
                noPostsLbl.text = "You have not disliked any posts"
                noPostsImageView.image = UIImage(named: "minus-white")
            } else {
                getNoPostTypeMessage()
            }
        }
        if categoryFilterOptions != nil && (categoryFilterOptions?.count)! > 0  && posts.count == 0 {
            
            noPostsLbl.text = "There are no posts from the selected categories matching your criteria"
            noPostsImageView.image = UIImage(named: "category")
        }
        return posts.count
    }
    
    func getNoPostTypeMessage() {
        
         if postTypeFilterOption == "Text" {
            noPostsLbl.text = "There are no text posts matching your criteria"
            noPostsImageView.image = UIImage(named: "text-white")
        } else if postTypeFilterOption == "Link" {
            noPostsLbl.text = "There are no link posts matching your criteria"
            noPostsImageView.image = UIImage(named: "link-white")
        } else if postTypeFilterOption == "Image" {
            noPostsLbl.text = "There are no image posts matching your criteria"
            noPostsImageView.image = UIImage(named: "camera-white")
        } else if postTypeFilterOption == "Video" {
            noPostsLbl.text = "There are no video posts matching your criteria"
            noPostsImageView.image = UIImage(named: "camcorder-white")
        } else if postTypeFilterOption == "Audio" {
            noPostsLbl.text = "There are no audio posts matching your criteria"
            noPostsImageView.image = UIImage(named: "mic-white")
        } else if postTypeFilterOption == "Quote" {
            noPostsLbl.text = "There are no quote posts matching your criteria"
            noPostsImageView.image = UIImage(named: "two-quotes-white")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow
        let currentCell = tableView.cellForRow(at: indexPath!) as! PostCell
        
        userFollowersToPass = currentCell.followersLbl.text!
        postToPass = currentCell.post
        mediaImageToPass = currentCell.postImg.image
        videoDataToPass = currentCell.videoData
        followingImgToPass = currentCell.neutralImageView.image
        userPhotoToPass = currentCell.profileImg.image
        
        performSegue(withIdentifier: "PostDetailVC", sender: self)
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if posts.count > 0 {
            
            let post = posts[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell {
                
                cell.request?.cancel()
                
//                let userLat = currentLocation["latitude"] as? Double
//                let userLong = currentLocation["longitude"] as? Double
                
                var img: UIImage?
                
                if let postImgUrl = post.image {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                } else if let postImgUrl = post.thumbnail {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                }
                
                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "myinfo", filterType: self.personalFilterOption)
                
                cell.delegate = self
                cell.activityDelegate = self
                cell.sharingDelegate = self
                
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
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.performSegue(withIdentifier: "PostDetailVC", sender: posts[indexPath.row])
//    }
    
    @IBAction func personalFilterBtnPressed(_ sender: AnyObject) {
        
    }
    
    @IBAction func postTypeFilterBtnPressed(_ sender: AnyObject) {
        
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
        tableView.reloadData()
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
        
        let currentUserID = UserService.ds.currentUserID
        
        self.posts = []
        
        if personalFilterOption == "My Posts" {
            
            URL_BASE.child("posts").queryOrdered(byChild: "user_id").queryEqual(toValue: currentUserID).observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in

                let userPosts = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                if userPosts.count == 0 {
                    
                    self.noPostsLbl.isHidden = false
                    self.noPostsImageView.isHidden = false
                    self.noPostsLbl.text = "You have not created any posts"
                    self.noPostsImageView.image = UIImage(named: "folder")
                }
                
                for post in userPosts {
                    
                    if let postDict = post.value as? Dictionary<String,AnyObject> {
                        let key = post.key
                        let post = Post(postKey: key, dictionary: postDict)
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
                }
                if self.posts.count > 0 {
                    
                    self.filterPostFeedType()
                    self.filterPostFeedCategories()
                    self.tableView.isHidden = false
                    self.posts = self.posts.sorted(by: { $0.timestamp > $1.timestamp })
                }
                self.tableView.reloadData()
            })
            
        } else if personalFilterOption == "Liked" {
            
            URL_BASE.child("users").child(currentUserID).child("likes").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                
                let likedKeys = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                if likedKeys.count == 0 {
                    
                    self.noPostsLbl.isHidden = false
                    self.noPostsImageView.isHidden = false
                    self.noPostsLbl.text = "You have not liked any posts"
                    self.noPostsImageView.image = UIImage(named: "plus-white")
                }

                for post in likedKeys {
                    
                    self.myGroup.enter()
                    URL_BASE.child("posts").child(post.key).observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                        
                        if let postDict = snapshot.value as? Dictionary<String,AnyObject> {
                            
                            let post = Post(postKey: post.key, dictionary: postDict)
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
                        self.filterPostFeedType()
                        self.filterPostFeedCategories()
                        self.posts = self.posts.sorted(by: { $0.timestamp > $1.timestamp })
                        self.tableView.isHidden = false
                    } else {
                        self.noPostsLbl.text = "You have not liked any posts"
                        self.noPostsImageView.image = UIImage(named: "plus-white")
                        self.tableView.isHidden = true
                    }
                    self.tableView.reloadData()
                })
            })

        } else if personalFilterOption == "Disliked" {
            
            URL_BASE.child("users").child(currentUserID).child("dislikes").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                
                let dislikedKeys = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                if dislikedKeys.count == 0 {
                    
                    self.noPostsLbl.isHidden = false
                    self.noPostsImageView.isHidden = false
                    self.noPostsLbl.text = "You have not disliked any posts."
                    self.noPostsImageView.image = UIImage(named: "minus-white")
                }
                
                for post in dislikedKeys {

                    self.myGroup.enter()
                    URL_BASE.child("posts").child(post.key).observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                        
                        if let postDict = snapshot.value as? Dictionary<String,AnyObject> {
                            
                            let post = Post(postKey: post.key, dictionary: postDict)
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
                        self.filterPostFeedType()
                        self.filterPostFeedCategories()
                        self.posts = self.posts.sorted(by: { $0.timestamp > $1.timestamp })
                        self.tableView.isHidden = false
                    } else {
                        self.noPostsLbl.text = "You have not disliked any posts."
                        self.noPostsImageView.image = UIImage(named: "minus-white")
                        self.tableView.isHidden = true
                    }
                    self.tableView.reloadData()
                })
            })
        }
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

    @IBAction func unwindToMyInfoVC(_ segue: UIStoryboardSegue) {
        
        if let sourceViewController = segue.source as? CategoryFilterVC {
            
            self.categoryFilterOptions = sourceViewController.checked
            self.comingFromCategoryFilterVC = sourceViewController.comingFromCategoryVC
            refreshPostFeed()
            
        } else if let sourceViewController = segue.source as? OptionFilterVC {
            
            postTypeFilterOption = sourceViewController.activePostType
            personalFilterOption = sourceViewController.activePersonalOption
            refreshPostFeed()
        }
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "CategoryFilterVC" {

            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! CategoryFilterVC
            if categoryFilterOptions != nil && (categoryFilterOptions?.count)! > 0 {
                vC.checked = categoryFilterOptions!
            }
            vC.previousVC = "MyInfoVC"
        } else if segue.identifier == "PostDetailVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! PostDetailVC
            vC.followers = userFollowersToPass
            vC.post = postToPass
            vC.mediaImage = mediaImageToPass
            vC.followingStatus = followingImgToPass
            vC.userPhotoPostDetail = userPhotoToPass
            vC.previousVC = "MyInfoVC"
        } else if segue.identifier == "PersonalFilterVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! OptionFilterVC
            vC.filterType = "Personal"
            vC.previousVC = "MyInfoVC"
            vC.activePostType = activePostType
            vC.activePersonalOption = activePersonalOption
        } else if segue.identifier == "PostTypeFilterVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! OptionFilterVC
            vC.filterType = "PostType"
            vC.previousVC = "MyInfoVC"
            vC.activePostType = activePostType
            vC.activePersonalOption = activePersonalOption
        }
    }
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }
}
