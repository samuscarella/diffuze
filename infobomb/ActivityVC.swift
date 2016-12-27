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

//private var latitude: Double = 0.0
//private var longitude: Double = 0.0

//ADD GREY IMAGE TO FOLLOWERSVC WHEN USER HAS NO FOLLOWERS
//UPDATE TRIM WHITESPACE METHOD IN BOMBVC NOT POSTCELL

class ActivityVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, TableViewCellDelegate {
    
    @IBOutlet weak var notificationBtn: UIBarButtonItem!
    @IBOutlet weak var pulseImg: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var categoryFilterBtn: UIButton!
    @IBOutlet weak var postTypeFilterBtn: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var darkendViewBtn: UIButton!
    
    static var imageCache = NSCache<AnyObject, AnyObject>()
    
    let pulsator = Pulsator()
    let userID = FIRAuth.auth()?.currentUser?.uid
    let iD = UserService.ds.currentUserID
    let postTypeDataSource = ["All","Text","Link","Image","Video","Audio","Quote"]

    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var posts = [Post]()
    var currentUser: NSDictionary = [:]
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var audioPlayerItem: AVPlayerItem?
    var audioPlayer: AVPlayer?
    var followingImage: UIImage!
    var notFollowingImage: UIImage!
    var lineView: UIView!
    var comingFromCategoryFilterVC = false
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
    var didJustLogIn = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
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
                
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        locationService = LocationService()
        
//        locationService.startTracking()
//        locationService.addObserver(self, forKeyPath: "latitude", options: .New, context: &latitude)
//        locationService.addObserver(self, forKeyPath: "longitude", options: .New, context: &longitude)
        
        UserService.ds.REF_USER_CURRENT.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
              //  let value = snapshot.value as? NSDictionary
              //  let latitude = value!["latitude"]
              //  let longitude = value!["longitude"]
              //  self.currentLocation["latitude"] = latitude as AnyObject?
              //  self.currentLocation["longitude"] = longitude as AnyObject?
//              self.tableView.reloadData()
        })

//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ActivityVC.refreshTableView), name: "userUpdatedLocation", object: nil)
        NotificationCenter.default.addObserver(locationService, selector: #selector(locationService.stopUpdatingLocation), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
        
        pulsator.radius = 300.0
        pulsator.backgroundColor = UIColor(red: 255.0, green: 0, blue: 0, alpha: 1).cgColor
        pulsator.animationDuration = 4
        pulsator.numPulse = 6
        pulsator.pulseInterval = 2
        pulseImg.layer.superlayer?.insertSublayer(pulsator, below: pulseImg.layer)
        pulsator.start()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        tableView.isHidden = true
        
        if !comingFromCategoryFilterVC {
            categoryFilterOptions?.removeAll()
            postTypeFilterOption = "All"
            previousPostTypeFilterRow = 0
            refreshPostFeed()
        }
        
        let currentUserID = UserDefaults.standard.object(forKey: KEY_UID) as! String
        
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
    
//    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//        
//        if context == &latitude {
//            latitude = Double(change![NSKeyValueChangeNewKey]! as! NSNumber)
////            print("LatitudeOfUser: \(latitude)")
//            currentLocation["latitude"] = latitude
//            tableView.reloadData()
//        }
//        if context == &longitude {
//            longitude = Double(change![NSKeyValueChangeNewKey]! as! NSNumber)
////            print("LongitudeOfUser: \(longitude)")
//            currentLocation["longitude"] = longitude
//            tableView.reloadData()
//        }
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if didJustLogIn {
            
            let alertView = SCLAlertView()
            alertView.showInfo("Tip", subTitle: "\nWelcome to Diffuze! When posts reach your location, they will show up here in the radar feed.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xFACE00, colorTextButton: 0x000000, circleIconImage: UIImage(named: "error-white"), animationStyle: .topToBottom)
        }
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
        NotificationCenter.default.removeObserver(self)
        didJustLogIn = false
    }
    
    @IBAction func postTypeFilterBtnPressed(_ sender: AnyObject) {
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
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
         if postTypeFilterActive {
            return postTypeDataSource.count
        }
        return postTypeDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if postTypeFilterActive {
            return postTypeDataSource[row]
        }
        return postTypeDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if darkendViewBtn.isHidden {
            
            if postTypeFilterActive {
                self.pickerView.selectRow(previousPostTypeFilterRow, inComponent: 0, animated: false)
            }
            return
        }
        
       if postTypeFilterActive {
            self.postTypeFilterOption = postTypeDataSource[row]
            previousPostTypeFilterRow = row
        }
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
                
                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "radar", filterType: nil)
                
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
    
    func notificationBtnPressed() {
        
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
                            print(radarPost)
                            let post = Post(postKey: postKey, dictionary: radarPost)
                            if post.active {
                                self.posts.append(post)
                            }
                        }
                        self.myGroup.leave()
                    })
                }
                
                self.myGroup.notify(queue: DispatchQueue.main, execute: {
                    
                    if self.posts.count > 0 {
                        self.refreshPostFeed()
                        self.posts.reverse()
                        self.tableView.isHidden = false
                    }
                    self.tableView.reloadData()
                })
                
            }
        })
    }
    
    @IBAction func darkenedViewBtnPressed(_ sender: AnyObject) {
        
        pickerView.isHidden = true
        darkendViewBtn.isHidden = true
        darkendViewBtn.isUserInteractionEnabled = false
        darkendViewBtn.alpha = 0.0
        
        print(previousPostTypeFilterRow)
        
        getRadarPosts()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "CategoryFilterVC" {
            
            let vC = segue.destination as! CategoryFilterVC
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
        }
    }
    
    @IBAction func unwindToActivityPost(_ segue: UIStoryboardSegue) {
        
    }

    @IBAction func unwindToActivityVC(_ segue: UIStoryboardSegue) {
        
        if let sourceViewController = segue.source as? CategoryFilterVC {
            self.categoryFilterOptions = sourceViewController.checked
            self.comingFromCategoryFilterVC = sourceViewController.comingFromCategoryVC
            getRadarPosts()
        }
    }

}
