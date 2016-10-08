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
import Alamofire

private var latitude = 0.0
private var longitude = 0.0

class CategoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var explosionPlayer: AVAudioPlayer!
    var categories = [Category]()
    var checked: [[String:String]] = []
    var message: String?
    var previousVC: String!
    var locationService: LocationService!

//    var locationManager: CLLocationManager!
//    var currentLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSUserDefaults.standardUserDefaults().setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")

        print("CategoryVC")
        print("\(message)\(previousVC)")
        
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.Stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Pick Categories"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        locationService = LocationService()
//        locationService.startTracking()
//        locationService.addObserver(self, forKeyPath: "latitude", options: .New, context: &latitude)
//        locationService.addObserver(self, forKeyPath: "longitude", options: .New, context: &longitude)

        
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
    
//    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//        
//        if context == &latitude {
//            latitude = Double(change![NSKeyValueChangeNewKey]! as! NSNumber)
//            print("LatitudeOfUser: \(latitude)")
//        }
//        if context == &longitude {
//            longitude = Double(change![NSKeyValueChangeNewKey]! as! NSNumber)
//            print("LongitudeOfUser: \(longitude)")
//        }
//    }

    
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
            print(checked)
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
            } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
                
                let userID = UserService.ds.currentUserID
                let username = UserService.ds.currentUserUsername
                
                if previousVC == "TextPostVC" {
                    
                    if let msg = message where msg != "" {
                    
                        let firebasePost = PostService.ds.REF_POSTS.childByAutoId()
                        let key = firebasePost.key
                        let activeFirebasePost = PostService.ds.REF_ACTIVE_POSTS.child(key)
                        let userPosts = UserService.ds.REF_USER_POSTS.child(userID).child(key)
                        let postCategoryRef = PostService.ds.REF_POSTS.child(key).child("categories")

                        var selectedCategories: [String:AnyObject] = [:]
                        for(_, value) in checked.enumerate() {
                            for (_, val) in value {
//                                let selectedCategory = [
//                                    val: true
//                                ]
                                selectedCategories[val] = true
                            }
                        }
                        let msg = message!

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
                                "latitude": DALLAS_LATITUDE,
                                "longitude": DALLAS_LONGITUDE,
                                "distance": 1000.0,
                                "usersInRadius": 0,
                                "created_at": FIRServerValue.timestamp()
                            ]
                
                        activeFirebasePost.setValue(post)
                        firebasePost.setValue(post)
                        userPosts.setValue(post)

                        
                        for(_, value) in checked.enumerate() {
                            for (_, val) in value {
                                let selectedCategory = [
                                    val: true
                                ]
                                postCategoryRef.updateChildValues(selectedCategory)
                                userPosts.child("categories").updateChildValues(selectedCategory)
                                activeFirebasePost.child("categories").updateChildValues(selectedCategory)
                                //activePostCategoryRef.updateChildValues(selectedCategory)
                            }
                        }
                        
                        let userPostsRef = UserService.ds.REF_USER_CURRENT.child("posts")
                        let userPost = [
                            key: true
                        ]
                        userPostsRef.updateChildValues(userPost)

                        
                        let url = NSURL(string: "https://nameless-chamber-44579.herokuapp.com/post")!
                        Alamofire.request(.POST, url, parameters: post).validate().responseString { response in
                            switch response.result {
                            case .Success( _):
                                print(response.result.value!)
                                print("Validation Successful")
                            case .Failure(let error):
                                print(error)
                            }
                        }
//                        Alamofire.request(.GET, url).validate().responseJSON { response in
//                            switch response.result {
//                            case .Success:
//                                print(response.result.value!)
////                                print(response.data)
////                                print(response.response)
////                                print(response.request)
//
//                                print("Validation Successful")
//                            case .Failure(let error):
//                                print("ERROR:\n")
//                                print(error)
//                            }
//                        }

//                        post["categories"] = nil
                
                

//                        print(post)
                        playExplosion()
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                    //End of if message != nil
                }
            }
        } else {
            print("Please pick at least one category!")
        }
    }
    

    @IBAction func backBtnPressed(sender: AnyObject) {
        
        if previousVC == "TextPostVC" {
//            locationService.stopUpdatingLocation()
            self.performSegueWithIdentifier("unwindToTextPost", sender: self)
        }
        
    }
    
//    func bypassAuthentication() {
//        let manager = Alamofire.Manager.sharedInstance
//        manager.delegate.sessionDidReceiveChallenge = { session, challenge in
//            var disposition: NSURLSessionAuthChallengeDisposition = .PerformDefaultHandling
//            var credential: NSURLCredential?
//            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//                disposition = NSURLSessionAuthChallengeDisposition.UseCredential
//                credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
//            } else {
//                if challenge.previousFailureCount > 0 {
//                    disposition = .CancelAuthenticationChallenge
//                } else {
//                    credential = manager.session.configuration.URLCredentialStorage?.defaultCredentialForProtectionSpace(challenge.protectionSpace)
//                    if credential != nil {
//                        disposition = .UseCredential
//                    }
//                }
//            }
//            return (disposition, credential)
//        }
//    }


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
