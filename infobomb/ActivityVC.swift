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
//
//private var latitude: Double = 0.0
//private var longitude: Double = 0.0

class ActivityVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var burgerBtn: UIBarButtonItem!
    @IBOutlet weak var notificationBtn: UIBarButtonItem!
    @IBOutlet weak var pulseImg: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    let pulsator = Pulsator()
    
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var posts = [Post]()
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSUserDefaults.standardUserDefaults().setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.Stretch)
        self.navigationController!.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Activity"
        self.navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size:36)!, NSForegroundColorAttributeName: LIGHT_GREY]

        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "notification.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 27, 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.Custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), forState: UIControlState.Normal)
        menuButton.frame = CGRectMake(0, 0, 60, 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        locationService = LocationService()
////        locationService.startTracking()
//        locationService.addObserver(self, forKeyPath: "latitude", options: .New, context: &latitude)
//        locationService.addObserver(self, forKeyPath: "longitude", options: .New, context: &longitude)
        
        UserService.ds.REF_USER_CURRENT.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let latitude = value!["latitude"]
                let longitude = value!["longitude"]
                self.currentLocation["latitude"] = latitude
                self.currentLocation["longitude"] = longitude
                self.tableView.reloadData()
        })

//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ActivityVC.refreshTableView), name: "userUpdatedLocation", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(locationService, selector: #selector(locationService.stopUpdatingLocation), name: "userSignedOut", object: nil)
        pulsator.radius = 300.0
        pulsator.backgroundColor = UIColor(red: 255.0, green: 0, blue: 0, alpha: 1).CGColor
        pulsator.animationDuration = 0.9
        pulsator.pulseInterval = 0.1
        pulseImg.layer.superlayer?.insertSublayer(pulsator, below: pulseImg.layer)
        pulsator.start()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 300
        

        let userID = FIRAuth.auth()?.currentUser?.uid
        var currentUser: NSDictionary = [:]
        let iD = UserService.ds.currentUserID
        UserService.ds.REF_USERS.child(iD).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            // Get user value
            
            currentUser = (snapshot.value as? NSDictionary)!
            
            PostService.ds.REF_ACTIVE_POSTS.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { snapshot in
                print("Got snapshot...")
                if let activePosts = snapshot.children.allObjects as? [FIRDataSnapshot] {
                    
                    self.posts = []
                    for post in activePosts {
                        
                        if let postDict = post.value as?  Dictionary<String, AnyObject> {
                            let key = post.key
                            //print(currentUser)
                            if let userSubscriptions = currentUser["subscriptions"] as? NSDictionary {
                                
                                let postCategories = postDict["categories"] as! NSDictionary
                                var isUserSubscribed = false
                                for(postCategory, _) in postCategories {
                                    for(userSubscription, _) in userSubscriptions {
                                        if postCategory as! String == userSubscription as! String {
                                            isUserSubscribed = true
                                            break
                                        }
                                    }
                                    if isUserSubscribed { break }
                                }
                                if isUserSubscribed && currentUser["user_ref"] as? String != postDict["user_id"] as? String {
                                    
                                    let postLat = Double((postDict["latitude"] as? Double)!)
                                    let postLong = Double((postDict["longitude"] as? Double)!)
                                    let userLat = Double((currentUser["latitude"] as? Double)!)
                                    let userLong = Double((currentUser["longitude"] as? Double)!)
                                    
                                    let postDistance = postDict["distance"] as? Int
                                    let postLocation = CLLocation(latitude: postLat, longitude: postLong)
                                    let userLocation = CLLocation(latitude: userLat, longitude: userLong)
                                    
                                    let distanceBetweenUserAndPost = userLocation.distanceFromLocation(postLocation)
                                    let isUserInRadius = distanceBetweenUserAndPost - Double(postDistance!)
                                    
                                    if(isUserInRadius < 0) {
                                        print("User is in radius. Adding Post...")
                                        
                                        let post = Post(postKey: key, dictionary: postDict)
                                        self.posts.append(post)
                                    } else {
                                        print("User is not in radius.")
                                        continue
                                    }
                                    
                                }
                            } else {
                                print("User is not subscribed to anything!")
                            }
                        }
                    }
                }
                            self.tableView.reloadData()
            })
        }) { (error) in
            print("CurrentUserError: \(error.localizedDescription)")
        }



        //Burger side menu
        if revealViewController() != nil {
            
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), forControlEvents: UIControlEvents.TouchUpInside)
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
    
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        var post: Post!
        
        post = posts[indexPath.row]
        
        performSegueWithIdentifier("PostDetailVC", sender: post)
        
    }

    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if posts.count > 0 {
            pulseImg.hidden = true
            pulsator.stop()
        }
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let post = posts[indexPath.row]
        var didUpdateLocation = false
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            let userLat = currentLocation["latitude"] as? Double
            let userLong = currentLocation["longitude"] as? Double

            if userLat != nil && userLong != nil {
                didUpdateLocation = true
            }
            if didUpdateLocation {
                cell.configureCell(post, currentLocation: currentLocation)
            }
            return cell
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let post = posts[indexPath.row]
        
        if post.type == "text" {
            return 200
        }
        return tableView.estimatedRowHeight
        
    }
    
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        animation.fromValue = NSValue(CGPoint: CGPointMake(pulseImg.center.x - 5, pulseImg.center.y))
        animation.toValue = NSValue(CGPoint: CGPointMake(pulseImg.center.x + 5, pulseImg.center.y))
        pulseImg.layer.addAnimation(animation, forKey: "position")
    }

    

    func notificationBtnPressed() {
        
    }
    
    @IBAction func unwindToActivityPost(segue: UIStoryboardSegue) {
        
    }

    
    @IBAction func unwindToActivityVC(segue: UIStoryboardSegue) {
        
    }

}
