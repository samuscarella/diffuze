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

private var latitude = 0.0
private var longitude = 0.0

class ActivityVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var burgerBtn: UIBarButtonItem!
    @IBOutlet weak var notificationBtn: UIBarButtonItem!
    @IBOutlet weak var pulseImg: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    let pulsator = Pulsator()
    var locationService: LocationService!
    
    
    var currentLocation: CLLocation?

    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")
        self.navigationController!.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Activity"
        self.navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size:36)!, NSForegroundColorAttributeName: LIGHT_GREY]

        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "notification.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 27, 27)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .New, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .New, context: &longitude)

//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ActivityVC.refreshTableView), name: "userUpdatedLocation", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(locationService, selector: #selector(locationService.stopUpdatingLocation), name: "userSignedOut", object: nil)
//        pulsator.radius = 240.0
//        pulsator.backgroundColor = UIColor(red: 255.0, green: 0, blue: 0, alpha: 1).CGColor
//        pulsator.animationDuration = 1
//        pulseImg.layer.superlayer?.insertSublayer(pulsator, below: pulseImg.layer)
//        pulsator.start()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 300 // for example. Set your average height
        
        let userID = UserService.ds.currentUserID
        PostService.ds.REF_ACTIVE_POSTS.child(userID).observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                self.posts = []
                for snap in snapshots {
//                    print("SNAP: \(snap)")
                    
                    if let postDict = snap.value as?  Dictionary<String, AnyObject> {
                        let key = snap.key
                        print(postDict)
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })

        //Burger side menu
        if revealViewController() != nil {
            
            burgerBtn.target = revealViewController()
            burgerBtn.action = #selector(SWRevealViewController.revealToggle(_:))
            
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if context == &latitude {
            latitude = Double(change![NSKeyValueChangeNewKey]! as! NSNumber)
            print("LatitudeOfUser: \(latitude)")
            tableView.reloadData()
        }
        if context == &longitude {
            longitude = Double(change![NSKeyValueChangeNewKey]! as! NSNumber)
            print("LongitudeOfUser: \(longitude)")
            tableView.reloadData()
        }
    }

    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        pulseImg.layer.layoutIfNeeded()
//        pulsator.position = pulseImg.layer.position
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {

            if let cl = currentLocation {
                cell.configureCell(post, currentLocation: cl)
            } else {
                cell.configureCell(post, currentLocation: nil)
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
    
//    func refreshTableView() {
//        tableView.reloadData()
//    }


    func notificationBtnPressed() {
    }
    
    @IBAction func unwindToActivityVC(segue: UIStoryboardSegue) {
        
    }

}
