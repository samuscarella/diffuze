//
//  RadarVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/4/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase

class RadarVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    let userID = FIRAuth.auth()?.currentUser?.uid
    let iD = UserService.ds.currentUserID

    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var posts = [Post]()
    var currentUser: NSDictionary = [:]
    var followingImage: UIImage!
    var notFollowingImage: UIImage!


    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
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
        
        ////        locationService.startTracking()
        //        locationService.addObserver(self, forKeyPath: "latitude", options: .New, context: &latitude)
        //        locationService.addObserver(self, forKeyPath: "longitude", options: .New, context: &longitude)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        tableView.isHidden = true
        
        followingImage = UIImage(named: "following-blue")
        notFollowingImage = UIImage(named: "follower-grey")
        
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

        //Burger side menu
        if revealViewController() != nil {
            
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
//        if posts.count > 0 {
//            pulseImg.isHidden = true
//            pulsator.stop()
//        }
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
                
                if let url = post.image {
                    img = ActivityVC.imageCache.object(forKey: url as AnyObject) as? UIImage
                } else if let url = post.thumbnail {
                    img = ActivityVC.imageCache.object(forKey: url as AnyObject) as? UIImage
                }
                
                cell.configureCell(post, currentLocation: currentLocation, image: img)
                
                return cell
            } else {
                return PostCell()
            }
        }
        return PostCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if posts.count > 0 {
            let post = posts[(indexPath as NSIndexPath).row]
            
            if post.type == "text" {
                return UITableViewAutomaticDimension
            }
        }
        return UITableViewAutomaticDimension
        
    }

}
