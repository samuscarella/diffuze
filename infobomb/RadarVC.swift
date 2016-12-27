//
//  RadarVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/4/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase

class RadarVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ActivityTableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var noPostsLbl: UILabel!
    @IBOutlet weak var noPostsImageView: UIImageView!
    
    let userID = FIRAuth.auth()?.currentUser?.uid
    let iD = UserService.ds.currentUserID

    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
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
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        locationService = LocationService()
        
        //locationService.startTracking()
        //locationService.addObserver(self, forKeyPath: "latitude", options: .New, context: &latitude)
        //locationService.addObserver(self, forKeyPath: "longitude", options: .New, context: &longitude)
        
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
    
    func postAction(action: String) {

        showScoreView(action: action)
    }
    
    func notificationBtnPressed() {
        
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
    
    func getAllFollowingUsers() {
        
        URL_BASE.child("users").child(currentUserID).child("following").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            let followingUsers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            if followingUsers.count > 0 {
                
                self.posts = []
                for user in followingUsers {
                    
                    self.myGroup.enter()
                    let userRecentPost = URL_BASE.child("posts").queryOrdered(byChild: "user_id").queryEqual(toValue: user.key).queryLimited(toLast: 1)
                    userRecentPost.observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
                        
                        let postObjects = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                        for post in postObjects {
                            let postDict = post.value as? Dictionary<String,AnyObject>
                            let post = Post(postKey: post.key, dictionary: postDict!)
                            self.posts.append(post)
                        }
                        self.myGroup.leave()
                    })
                }
                
                self.myGroup.notify(queue: DispatchQueue.main, execute: {
                    
                    if self.posts.count > 0 {
                       // self.posts.reverse()
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
