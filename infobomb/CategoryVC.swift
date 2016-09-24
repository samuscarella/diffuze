//
//  CategoryVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/11/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import AVFoundation

class CategoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var explosionPlayer: AVAudioPlayer!
    
    var categories = [Category]()
    var checked: [[String:String]] = []

    var message: String?
    var previousVC: String!
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(message)\(previousVC)")
        
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Pick Categories"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        tableView.delegate = self
        tableView.dataSource = self
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
        CategoryService.ds.REF_CATEGORIES.queryOrderedByChild("name").observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                self.categories = []
                for snap in snapshots {
                    
                    if let categoryDict = snap.value as?  Dictionary<String, AnyObject> {
                        let key = snap.key
                        let category = Category(categoryKey: key, dictionary: categoryDict)
                        self.categories.append(category)
                    }
                }
                
            }
            
            self.tableView.reloadData()
        })

    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let category = categories[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCell") as? CategoryCell {
            
            cell.request?.cancel()
            
            var img: UIImage?
            
            if let url = category.image_path {
                img = SubscriptionsVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(category, img: img)
            
//            if checked.contains(category.name) {
//                cell.accessoryType = .Checkmark
//            } else {
//                cell.accessoryType = .None
//            }
            return cell
            
            
        } else {
            return CategoryCell()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
//        let category = categories[indexPath.row]
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            
            let category = categories[indexPath.row]
//            print(category.categoryKey)
            var doesItExist = false
            
            if checked.count == 0 {
                let cat = [
                    category.categoryKey:category.name
                ]
                checked.append(cat)
                cell.accessoryType = .Checkmark
            } else if checked.count > 0 {
                for(index, value) in checked.enumerate() {
//                    print(value)
                    if let _ = value[category.categoryKey] {
                        doesItExist = true
                        checked.removeAtIndex(index)
                        cell.accessoryType = .None
                        break
                    }
                }
                if doesItExist == false {
                    let cat = [
                        category.categoryKey: category.name
                    ]
                    checked.append(cat)
                    cell.accessoryType = .Checkmark
                }

            }
//            print(checked)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    @IBAction func createPostBtnPressed(sender: AnyObject) {
        
        if checked.count > 0 {

            var post = [String:AnyObject]()
            
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                print("You have to allow location to make a post!")
            } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways {
                
//                let one = currentLocation
//                let two = CLLocation(latitude: 37.774929, longitude: -122.419416)
//                let distance = two.distanceFromLocation(one)
//                print(finalDistance)
                let userID = UserService.ds.currentUserID
                let username = UserService.ds.currentUserUsername
                
                if let msg = message where msg != "" {
                    
                    let firebasePost = PostService.ds.REF_POSTS.childByAutoId()
                    let key = firebasePost.key
                    let activeFirebasePost = PostService.ds.REF_ACTIVE_POSTS.child(key)

                    var selectedCategories: [[String:AnyObject]] = []
                    for(_, value) in checked.enumerate() {
                        for (_, val) in value {
                            let selectedCategory = [
                                val: true
                            ]
                            selectedCategories.append(selectedCategory)
                        }
                    }
//                    let msg = message!

                        post = [
                            "user_id": userID,
                            "username": username,
                            "post_ref": key,
                            "categories": selectedCategories,
                            "type": "text",
                            "message": msg,
                            "active": true,
                            "likes": 0,
                            "dislikes": 0,
                            "shares": 0,
                            "latitude": currentLocation.coordinate.latitude,
                            "longitude": currentLocation.coordinate.longitude,
                            "distance": 10.0,
                            "created_at": FIRServerValue.timestamp()
                        ]
                
                    activeFirebasePost.setValue(post)
                    
                    post["categories"] = nil
                    firebasePost.setValue(post)
                
                    let userPostsRef = UserService.ds.REF_USER_CURRENT.child("posts")
                    let userPost = [
                        key: true
                    ]
                    userPostsRef.updateChildValues(userPost)
                
                    let postCategoryRef = PostService.ds.REF_POSTS.child(key).child("categories")

                    for(_, value) in checked.enumerate() {
                        for (_, val) in value {
                            let selectedCategory = [
                                val: true
                            ]
                            postCategoryRef.updateChildValues(selectedCategory)
//                            activePostCategoryRef.updateChildValues(selectedCategory)
                        }
                    }
                    playExplosion()
                }
                //End of if message != nil
            }
        } else {
            print("Please pick at least one category!")
        }
    }
    

    @IBAction func backBtnPressed(sender: AnyObject) {
        
        if previousVC == "TextPostVC" {
            
            self.performSegueWithIdentifier("unwindToTextPost", sender: self)
        }
        
    }
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization()
            print("Access NotDetermined")
            break
        case .AuthorizedWhenInUse:
            locationManager.startUpdatingLocation()
            print("Access WhenInUse")
            break
        case .AuthorizedAlways:
            locationManager.startUpdatingLocation()
            break
        case .Restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            print("Access Restricted")
            break
        case .Denied:
            // user denied your app access to Location Services, but can grant access from Settings.app
            locationManager.requestWhenInUseAuthorization()
            print("Access Denied")
            break
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        currentLocation = locations.last! as CLLocation
        print("CategoryVC: \(currentLocation.coordinate.latitude)...CategoryVC: \(currentLocation.coordinate.longitude)")
    }

    func playExplosion() {
        
        let path = NSBundle.mainBundle().pathForResource("blast", ofType: "mp3")!
        
        do {
            explosionPlayer = try AVAudioPlayer(contentsOfURL: NSURL(string: path)!)
            explosionPlayer.prepareToPlay()
            explosionPlayer.play()
            
        } catch let err as NSError {
            print(err.debugDescription)
        } catch {
            print("Error Could not play Sound!")
        }
    }
    
    
}
