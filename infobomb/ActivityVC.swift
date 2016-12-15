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

//private var latitude: Double = 0.0
//private var longitude: Double = 0.0

class ActivityVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, TableViewCellDelegate {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        self.view.backgroundColor = SMOKY_BLACK
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        followingImage = UIImage(named: "following-blue")
        notFollowingImage = UIImage(named: "follower-grey")
        
        postTypeFilterBtn.imageEdgeInsets = UIEdgeInsetsMake(30, 80, 30, 80)
        postTypeFilterBtn.setImage(UIImage(named: "funnel-black"), for: .highlighted)
        categoryFilterBtn.imageEdgeInsets = UIEdgeInsetsMake(30, 80, 30, 80)
        categoryFilterBtn.setImage(UIImage(named: "categories-icon"), for: .highlighted)
        
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
            
                let value = snapshot.value as? NSDictionary
                let latitude = value!["latitude"]
                let longitude = value!["longitude"]
                self.currentLocation["latitude"] = latitude as AnyObject?
                self.currentLocation["longitude"] = longitude as AnyObject?
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
        
        let currentUserID = UserDefaults.standard.object(forKey: KEY_UID) as! String
        
        URL_BASE.child("user-radar").child(currentUserID).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            if let radarPosts = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                self.posts = []
                for post in radarPosts {
                    if let postDict = post.value as? Dictionary<String, AnyObject> {
                        
                        let post = Post(postKey: post.key, dictionary: postDict)
                        self.posts.append(post)
                    }
                }
            }
            if self.posts.count > 0 {
                self.tableView.reloadData()
                self.tableView.isHidden = false
            }
        })

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
    }
    
    
    func postDeleted(post: Post, action: String) {
        
        let index = (posts as NSArray).index(of: post)
        if index == NSNotFound { return }
        
        posts.remove(at: index)
        
        tableView.beginUpdates()
        
        let indexPathForRow = NSIndexPath(row: index, section: 0)
        tableView.deleteRows(at: [indexPathForRow as IndexPath], with: .fade)
        
        tableView.endUpdates()
        
        showScoreView(action: action)
    }
    
    private func tableView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
        
        var post: Post!
        post = posts[(indexPath as NSIndexPath).row]
        performSegue(withIdentifier: "PostDetailVC", sender: post)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if posts.count > 0 {
            pulseImg.isHidden = true
            pulsator.stop()
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
                
                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "radar")
                
                return cell
            } else {
                return PostCell(coder: NSCoder())
            }
        }
        return PostCell(coder: NSCoder())
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
                return UITableViewAutomaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "PostDetailVC", sender: posts[indexPath.row])
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
    
    @IBAction func unwindToActivityPost(_ segue: UIStoryboardSegue) {
        
    }

    @IBAction func unwindToActivityVC(_ segue: UIStoryboardSegue) {
        
    }

}
