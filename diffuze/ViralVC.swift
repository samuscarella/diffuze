//
//  ViralVC.swift
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

//Store score on post creation and then use that to filter rating by actual number and not

class ViralVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ActivityTableViewCellDelegate, ModalTransitionListener, SocialSharingDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var personalFilterBtn: UIButton!
    @IBOutlet weak var postTypeFilterBtn: UIButton!
    @IBOutlet weak var categoryFilterBtn: UIButton!
    @IBOutlet weak var noPostsLbl: UILabel!
    @IBOutlet weak var noPostsImageView: UIImageView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var scoreLbl: UILabel!

    let personalDataSource = ["Popularity","Rating"]
    let postTypeDataSource = ["All","Text","Link","Image","Video","Audio","Quote"]
    let iD = UserService.ds.currentUserID
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var posts = [Post]()
    var notifications = [NotificationCustom]()
    var postTypeFilterOption: String!
    var viralFilterOption: String!
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
    var activeViralOption: String!
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        ModalTransitionMediator.instance.setListener(listener: self)
        
        personalFilterBtn.setImage(UIImage(named: "star-black"), for: .highlighted)
        postTypeFilterBtn.setImage(UIImage(named: "funnel-black-small"), for: .highlighted)
        categoryFilterBtn.setImage(UIImage(named: "category-black-small"), for: .highlighted)
        
        noPostsLbl.isHidden = true
        noPostsImageView.isHidden = true

        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "viral-black.png")
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
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
        
        notificationService = NotificationService()
        notificationService.getNotifications()
        notificationService.watchRadar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotifications), name: NSNotification.Name(rawValue: "newFollowersNotification"), object: nil)

        if !comingFromCategoryFilterVC || !comingFromPersonalFilterVC || !comingFromPostTypeFilterVC {
            categoryFilterOptions?.removeAll()
            viralFilterOption = "Popularity"
            postTypeFilterOption = "All"
            activePostType = postTypeFilterOption
            activeViralOption = viralFilterOption
            refreshPostFeed()
        }
        
        //Burger side menus
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
        timer = nil
    }

    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }
    
    func postAction(action: String) {
        
        showScoreView(action: action)
    }
    
    func openSharePostVC(post: Post) {
        
        let sharingVC = self.storyboard?.instantiateViewController(withIdentifier: "SocialSharingVC") as! SocialSharingVC
        sharingVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        sharingVC.post = post
        present(sharingVC, animated: true, completion: nil)
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
        
        if posts.count == 0 {
            noPostsLbl.isHidden = false
            noPostsImageView.isHidden = false
            noPostsLbl.text = "There are no posts yet"
            noPostsImageView.image = UIImage(named: "add-new-file")
        } else {
            noPostsLbl.isHidden = true
            noPostsImageView.isHidden = true
        }
        
        if viralFilterOption == "Popularity" {
            
            if postTypeFilterOption != "All" {
                
                getNoPostTypeMessage()
            }
        } else if viralFilterOption == "Rating" && posts.count == 0 {
            
            if postTypeFilterOption != "All" {
                
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
            noPostsLbl.text = "There are no viral text posts matching your criteria"
            noPostsImageView.image = UIImage(named: "text-white")
        } else if postTypeFilterOption == "Link" {
            noPostsLbl.text = "There are no viral link posts matching your criteria"
            noPostsImageView.image = UIImage(named: "link-white")
        } else if postTypeFilterOption == "Image" {
            noPostsLbl.text = "There are no viral image posts matching your criteria"
            noPostsImageView.image = UIImage(named: "camera-white")
        } else if postTypeFilterOption == "Video" {
            noPostsLbl.text = "There are no viral video posts matching your criteria"
            noPostsImageView.image = UIImage(named: "camcorder-white")
        } else if postTypeFilterOption == "Audio" {
            noPostsLbl.text = "There are no viral audio posts matching your criteria"
            noPostsImageView.image = UIImage(named: "mic-white")
        } else if postTypeFilterOption == "Quote" {
            noPostsLbl.text = "There are no viral quote posts matching your criteria"
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
                
                //COULD POSSIBLY USE THIS TO SUBTRACT ONE REQUEST IN POST CELL
                //let userLat = currentLocation["latitude"] as? Double
                //let userLong = currentLocation["longitude"] as? Double
                
                var img: UIImage?
                
                if let postImgUrl = post.image {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                } else if let postImgUrl = post.thumbnail {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                }
                
                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "Viral", filterType: viralFilterOption)
                
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
                    print("removing")
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
            print(posts.count)
            for cat in posts[i].categories {
                for fo in categoryFilterOptions! {
                    if fo == cat {
                        shouldRemoveFromPosts = false
                    }
                }
            }
            if shouldRemoveFromPosts {
                print("Removing")
                self.posts.remove(at: i)
            } else {
                i += 1
            }
        }
        tableView.reloadData()
    }
    
    func refreshPostFeed() {
        
        self.posts = []
        
        if viralFilterOption == "Popularity" {
            
            URL_BASE.child("posts").queryOrdered(byChild: "viewCount").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                
                let userPosts = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                if userPosts.count == 0 {
                    
                    self.noPostsLbl.isHidden = false
                    self.noPostsImageView.isHidden = false
                    self.noPostsLbl.text = "You have not created any posts"
                    self.noPostsImageView.image = UIImage(named: "folder")
                }
                
                for post in userPosts {
                    
                    if let postDict = post.value as? Dictionary<String,AnyObject> {

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
                }
                if self.posts.count > 0 {
                    
                    self.filterPostFeedType()
                    self.filterPostFeedCategories()
                    self.tableView.isHidden = false
                    self.posts = self.posts.sorted(by: { $0.timestamp > $1.timestamp })
                }
                self.tableView.reloadData()
            })
            
        } else if viralFilterOption == "Rating" {
            
            URL_BASE.child("posts").queryOrdered(byChild: "rating").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                
                let userPosts = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                
                if userPosts.count == 0 {
                    
                    self.noPostsLbl.isHidden = false
                    self.noPostsImageView.isHidden = false
                    self.noPostsLbl.text = "You have not liked any posts"
                    self.noPostsImageView.image = UIImage(named: "plus-white")
                }
                
                for post in userPosts {
                    
                    if let postDict = post.value as? Dictionary<String,AnyObject> {
                        
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
                }
                
                if self.posts.count > 0 {
                    self.filterPostFeedType()
                    self.filterPostFeedCategories()
                    self.tableView.isHidden = false
                    self.posts = self.posts.sorted(by: { $0.timestamp > $1.timestamp })
                } else {
                    self.noPostsLbl.text = "You have not liked any posts"
                    self.noPostsImageView.image = UIImage(named: "plus-white")
                    self.tableView.isHidden = true
                }
                self.tableView.reloadData()
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

    @IBAction func unwindToViralVC(_ segue: UIStoryboardSegue) {
        
        if let sourceViewController = segue.source as? CategoryFilterVC {
            
            self.categoryFilterOptions = sourceViewController.checked
            self.comingFromCategoryFilterVC = sourceViewController.comingFromCategoryVC
            refreshPostFeed()
            
        } else if let sourceViewController = segue.source as? OptionFilterVC {
            
            postTypeFilterOption = sourceViewController.activePostType
            viralFilterOption = sourceViewController.activeViralOption
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
            vC.previousVC = "ViralVC"
        } else if segue.identifier == "PostDetailVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! PostDetailVC
            vC.followers = userFollowersToPass
            vC.post = postToPass
            vC.mediaImage = mediaImageToPass
            vC.followingStatus = followingImgToPass
            vC.userPhotoPostDetail = userPhotoToPass
            vC.previousVC = "ViralVC"
        } else if segue.identifier == "PersonalFilterVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! OptionFilterVC
            vC.filterType = "Viral"
            vC.previousVC = "ViralVC"
            vC.activePostType = activePostType
            vC.activeViralOption = activeViralOption
        } else if segue.identifier == "PostTypeFilterVC" {
            
            let nav = segue.destination as! UINavigationController
            let vC = nav.topViewController as! OptionFilterVC
            vC.filterType = "PostType"
            vC.previousVC = "ViralVC"
            vC.activePostType = activePostType
            vC.activeViralOption = activeViralOption
        }
    }
}
