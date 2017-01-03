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

private var latitude = 0.0
private var longitude = 0.0

class ViralVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, ActivityTableViewCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var personalFilterBtn: UIButton!
    @IBOutlet weak var postTypeFilterBtn: UIButton!
    @IBOutlet weak var categoryFilterBtn: UIButton!
    @IBOutlet weak var noPostsLbl: UILabel!
    @IBOutlet weak var noPostsImageView: UIImageView!
    @IBOutlet weak var darkendViewBtn: UIButton!
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
    var userFollowersToPass: String!
    var mediaImageToPass: UIImage?
    var videoDataToPass: NSData?
    var followingImgToPass: UIImage!
    var postToPass: Post!
    var userPhotoToPass: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.delegate = self
        pickerView.dataSource = self

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
        let logo = UIImage(named: "viral-black.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
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
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        if !comingFromCategoryFilterVC {
            categoryFilterOptions?.removeAll()
            personalFilterOption = "Popularity"
            postTypeFilterOption = "All"
            previousPersonalFilterRow = 0
            previousPostTypeFilterRow = 0
            refreshPostFeed()
        }
        
        //Burger side menu
        if revealViewController() != nil {
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }

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

    func notificationBtnPressed() {
        
    }
    
    func postAction(action: String) {
        
        showScoreView(action: action)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if personalFilterActive {
            return personalDataSource.count
        } else if postTypeFilterActive {
            return postTypeDataSource.count
        }
        return personalDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if personalFilterActive {
            return personalDataSource[row]
        } else if postTypeFilterActive {
            return postTypeDataSource[row]
        }
        return personalDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if darkendViewBtn.isHidden {
            
            if personalFilterActive {
                self.pickerView.selectRow(previousPersonalFilterRow, inComponent: 0, animated: false)
            } else if postTypeFilterActive {
                self.pickerView.selectRow(previousPostTypeFilterRow, inComponent: 0, animated: false)
            }
            return
        }
        
        if personalFilterActive {
            self.personalFilterOption = personalDataSource[row]
            previousPersonalFilterRow = row
        } else if postTypeFilterActive {
            self.postTypeFilterOption = postTypeDataSource[row]
            previousPostTypeFilterRow = row
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
        
        if personalFilterOption == "Popularity" {
            
            if postTypeFilterOption != "All" {
                
                getNoPostTypeMessage()
            }
        } else if personalFilterOption == "Rating" && posts.count == 0 {
            
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
                
                //                let userLat = currentLocation["latitude"] as? Double
                //                let userLong = currentLocation["longitude"] as? Double
                
                var img: UIImage?
                
                if let postImgUrl = post.image {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                } else if let postImgUrl = post.thumbnail {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                }
                
                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "Viral", filterType: self.personalFilterOption)
                
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
    
    @IBAction func personalFilterBtnPressed(_ sender: AnyObject) {
        
        personalFilterActive = true
        postTypeFilterActive = false
        categoryFilterActive = false
        pickerView.isHidden = false
        darkendViewBtn.isHidden = false
        darkendViewBtn.isUserInteractionEnabled = true
        darkendViewBtn.alpha = 0.0
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.darkendViewBtn.alpha = 0.75
            }, completion: { finished in
                
        })
        pickerView.reloadAllComponents()
        self.pickerView.selectRow(previousPersonalFilterRow, inComponent: 0, animated: false)
    }
    
    @IBAction func postTypeFilterBtnPressed(_ sender: AnyObject) {
        
        personalFilterActive = false
        postTypeFilterActive = true
        categoryFilterActive = false
        pickerView.isHidden = false
        darkendViewBtn.isHidden = false
        darkendViewBtn.isUserInteractionEnabled = true
        darkendViewBtn.alpha = 0.0
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.darkendViewBtn.alpha = 0.75
            }, completion: { finished in
                
        })
        pickerView.reloadAllComponents()
        self.pickerView.selectRow(previousPostTypeFilterRow, inComponent: 0, animated: false)
    }
        
    @IBAction func darkendViewBtnPressed(_ sender: AnyObject) {
        
        pickerView.isHidden = true
        darkendViewBtn.isHidden = true
        darkendViewBtn.isUserInteractionEnabled = false
        darkendViewBtn.alpha = 0.0
        
        refreshPostFeed()
    }
    
    func filterPostFeedType() {
        
        if previousPostTypeFilterRow == 0 {
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
        
        if personalFilterOption == "Popularity" {
            
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
                    }
                }
                if self.posts.count > 0 {
                    
                    self.filterPostFeedType()
                    self.filterPostFeedCategories()
                    self.tableView.isHidden = false
                }
                self.posts.reverse()
                self.tableView.reloadData()
            })
            
        } else if personalFilterOption == "Rating" {
            
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
                    }
                }
                
                if self.posts.count > 0 {
                    self.filterPostFeedType()
                    self.filterPostFeedCategories()
                    self.tableView.isHidden = false
                } else {
                    self.noPostsLbl.text = "You have not liked any posts"
                    self.noPostsImageView.image = UIImage(named: "plus-white")
                    self.tableView.isHidden = true
                }
                self.posts.reverse()
                /*self.posts.sort {
                    (($0 as! Dictionary<String, AnyObject>)["interactions"] as? Int) < (($1 as! Dictionary<String, AnyObject>)["interactions"] as? Int)
                }*/
                self.tableView.reloadData()
            })
        }
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
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "CategoryFilterVC" {
            
            let vC = segue.destination as! CategoryFilterVC
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
        }
    }

}
