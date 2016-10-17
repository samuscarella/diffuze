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
import Foundation

private var latitude = 0.0
private var longitude = 0.0

class CategoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, CLUploaderDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createBtn: MaterialButton!
    
    let storage = FIRStorage.storage()
    let firebasePost = PostService.ds.REF_POSTS.childByAutoId()
    var key: String! = nil

    var userID: String!
    var username: String!
    var explosionPlayer: AVAudioPlayer!
    var categories = [Category]()
    var checked: [[String:String]] = []
    var message: String?
    var linkObj: [String:AnyObject] = [:]
    var previousVC: String!
    var locationService: LocationService!
    var post = [String:AnyObject]()
    var postImg: Data?

//    var locationManager: CLLocationManager!
//    var currentLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")

        print("CategoryVC")
        print("\(message)\(previousVC)")
        print("\(postImg)\(previousVC)\n\n\n\n\n\n")
        
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.title = "Pick Categories"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        createBtn.setTitleColor(ANTI_FLASH_WHITE, for: .normal)

        if previousVC == TEXT_POST_VC {
            createBtn.backgroundColor = AUBURN_RED
        } else if previousVC == LINK_POST_VC {
            createBtn.backgroundColor = FIRE_ORANGE
        } else if previousVC == IMAGE_POST_VC {
            createBtn.backgroundColor = GOLDEN_YELLOW
        } else if previousVC == VIDEO_POST_VC {
            createBtn.backgroundColor = DARK_GREEN
        } else if previousVC == AUDIO_POST_VC {
            createBtn.backgroundColor = OCEAN_BLUE
        } else if previousVC == QUOTE_POST_VC {
            createBtn.backgroundColor = PURPLE
        }
        
        userID = UserService.ds.currentUserID
        username = UserService.ds.currentUserUsername
        key = firebasePost.key

        tableView.delegate = self
        tableView.dataSource = self
        
        locationService = LocationService()
//        locationService.startTracking()
//        locationService.addObserver(self, forKeyPath: "latitude", options: .New, context: &latitude)
//        locationService.addObserver(self, forKeyPath: "longitude", options: .New, context: &longitude)

        
        CategoryService.ds.REF_CATEGORIES.queryOrdered(byChild: "name").observe(FIRDataEventType.value, with: { (snapshot) in
            
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

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let category = categories[(indexPath as NSIndexPath).row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") as? CategoryCell {
            
            cell.request?.cancel()
            
            var img: UIImage?
            
            if let url = category.image_path {
                img = SubscriptionsVC.imageCache.object(forKey: url as AnyObject) as? UIImage
            }
            
            cell.configureCell(category, img: img)
            
            return cell
            
            
        } else {
            return CategoryCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        let category = categories[indexPath.row]
        if let cell = tableView.cellForRow(at: indexPath) {
            
            let category = categories[(indexPath as NSIndexPath).row]
//            print(category.categoryKey)
            var doesItExist = false
            
            if checked.count == 0 {
                let cat = [
                    category.categoryKey:category.name
                ]
                checked.append(cat)
                cell.accessoryType = .checkmark
            } else if checked.count > 0 {
                for(index, value) in checked.enumerated() {
//                    print(value)
                    if let _ = value[category.categoryKey] {
                        doesItExist = true
                        checked.remove(at: index)
                        cell.accessoryType = .none
                        break
                    }
                }
                if doesItExist == false {
                    let cat = [
                        category.categoryKey: category.name
                    ]
                    checked.append(cat)
                    cell.accessoryType = .checkmark
                }

            }
            print(checked)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    @IBAction func createPostBtnPressed(_ sender: AnyObject) {
        
        if checked.count > 0 {

            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
                print("You have to allow location to make a post!")
            } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
                
                if previousVC == TEXT_POST_VC {
                    self.gatherPostData(postType: "text", data: message! as AnyObject)
                } else if previousVC == LINK_POST_VC {
                    self.gatherPostData(postType: "link", data: linkObj as AnyObject)
                } else if previousVC == IMAGE_POST_VC {
                    self.gatherPostData(postType: "image", data: linkObj as AnyObject)
                } else if previousVC == VIDEO_POST_VC {
                    self.gatherPostData(postType: "video", data: linkObj as AnyObject)
                } else if previousVC == AUDIO_POST_VC {
                    self.gatherPostData(postType: "audio", data: linkObj as AnyObject)
                } else if previousVC == QUOTE_POST_VC {
                    self.gatherPostData(postType: "quote", data: linkObj as AnyObject)
                }
            }
        } else {
            print("Please pick at least one category!")
        }
    }
    
    func gatherPostData(postType: String, data: AnyObject) {
        
        
        let storageRef = storage.reference(forURL: "gs://infobomb-9b66c.appspot.com")
        
        var selectedCategories: [String:AnyObject] = [:]
        for(_, value) in checked.enumerated() {
            for (_, val) in value {
                selectedCategories[val] = true as AnyObject?
            }
        }
        
        post = [
            "user_id": userID as AnyObject,
            "username": username as AnyObject,
            "post_ref": key as AnyObject,
            "categories": selectedCategories as AnyObject,
            "active": true as AnyObject,
            "likes": 0 as AnyObject,
            "dislikes": 0 as AnyObject,
            "shares": 0 as AnyObject,
            "latitude": DALLAS_LATITUDE as AnyObject,
            "longitude": DALLAS_LONGITUDE as AnyObject,
            "distance": 1000.0 as AnyObject,
            "usersInRadius": 0 as AnyObject,
            "created_at": FIRServerValue.timestamp() as AnyObject
        ]
        
        let uniqueString = NSUUID().uuidString
        
        if postType == "text" {
            
            post["type"] = postType as AnyObject?

            if let message = data as? String {
                post["message"] = message as AnyObject?
            }
            self.postToFirebase()
            
        } else if postType == "link" {
            
            post["type"] = postType as AnyObject?
            
            if let linkTitle = data["title"] as! String? {
                post["title"] = linkTitle as AnyObject?
            }
            if let linkDescription = data["description"] as! String? {
                post["description"] = linkDescription as AnyObject?
            }
            if let linkShortUrl = data["canonicalUrl"] as! String? {
                post["shortUrl"] = linkShortUrl as AnyObject?
            }
            if let linkUrl = data["url"] as! String? {
                post["url"] = linkUrl as AnyObject?
            }
            if let linkImage = data["image"] as! NSData? {
                //need to store in storage and reference it from path
                let linkPreviewRef = storageRef.child("link-preview/image_\(NSUUID().uuidString)")
                // Upload the file to the path "images/rivers.jpg"
                let uploadTask = linkPreviewRef.put(linkImage as Data, metadata: nil) { metadata, error in
                    if (error != nil) {

                        print("Failed to upload image to firebase\n\n\n\n\n\n\n\n")
                    } else {
                        print("HERE")
                        let downloadURL = metadata!.downloadURL()!.absoluteString
                        self.post["image"] = downloadURL as AnyObject?
                        self.postToFirebase()
                    }
                }
                return
            }
            self.postToFirebase()
            
        } else if postType == "image" {
            
            post["type"] = postType as AnyObject?
            
            if let imageText = data["text"] as! String? {
                post["message"] = imageText as AnyObject?
            }
            
            let image = data["image"] as! NSData
            
            let imageRef = storageRef.child("images/image_post/image_\(uniqueString)")
            
                let uploadTask = imageRef.put(image as Data, metadata: nil) { metadata, error in
                    if (error != nil) {
                        // Uh-oh, an error occurred!
                        print("Failed to upload image to firebase")
                    } else {
                        print("HERE")
                        let downloadURL = metadata!.downloadURL()!.absoluteString
                        self.post["image"] = downloadURL as AnyObject?
                        self.postToFirebase()
                    }
                }
        } else if postType == "video" {
            
            post["type"] = postType as AnyObject?
            
            if let videoText = data["text"] as! String? {
                post["message"] = videoText as AnyObject?
            }
            
            let video = data["video"] as! NSData
            
            let imageRef = storageRef.child("videos/video_post/video_\(uniqueString)")
            
            let uploadTask = imageRef.put(video as Data, metadata: nil) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                    print("Failed to upload image to firebase")
                } else {
                    print("HERE")
                    let downloadURL = metadata!.downloadURL()!.absoluteString
                    self.post["video"] = downloadURL as AnyObject?
                    self.postToFirebase()
                }
            }

        } else if postType == "audio" {
            
        } else if postType == "quote" {
            
        }

    }
    
    func postToFirebase() {
        
        let activeFirebasePost = PostService.ds.REF_ACTIVE_POSTS.child(key)
        let userPosts = UserService.ds.REF_USER_POSTS.child(userID).child(key)
        let postCategoryRef = PostService.ds.REF_POSTS.child(key).child("categories")

        
        activeFirebasePost.setValue(post)
        firebasePost.setValue(post)
        userPosts.setValue(post)
        
        for(_, value) in checked.enumerated() {
            for (_, val) in value {
                let selectedCategory = [
                    val: true
                ]
                postCategoryRef.updateChildValues(selectedCategory)
                userPosts.child("categories").updateChildValues(selectedCategory)
                activeFirebasePost.child("categories").updateChildValues(selectedCategory)
            }
        }
        
        let userPostsRef = UserService.ds.REF_USER_CURRENT.child("posts")
        let userPost = [
            key: true
        ]
        userPostsRef.updateChildValues(userPost)
        
        let url = URL(string: "https://nameless-chamber-44579.herokuapp.com/post")!
        Alamofire.request(url, method: .post, parameters: post).validate().responseJSON { response in
            switch response.result {
            case .success( _):
                print(response.result.value!)
                print("Validation Successful")
                self.playExplosion()
            case .failure(let error):
                print("POST REQUEST ERROR: \(error)")
            }
        }

    }
    

    @IBAction func backBtnPressed(_ sender: AnyObject) {
        
        if previousVC == TEXT_POST_VC {
//            locationService.stopUpdatingLocation()
            self.performSegue(withIdentifier: "unwindToTextPost", sender: self)
        } else if previousVC == LINK_POST_VC {
            //locationService.stopUpdatingLocation()
            self.performSegue(withIdentifier: "unwindToLinkPost", sender: self)
        } else if previousVC == IMAGE_POST_VC {
            self.performSegue(withIdentifier: "unwindToImagePost", sender: self)
        } else if previousVC == VIDEO_POST_VC {
            self.performSegue(withIdentifier: "unwindToImagePost", sender: self)
        } else if previousVC == AUDIO_POST_VC {
            self.performSegue(withIdentifier: "unwindToAudioPost", sender: self)
        } else if previousVC == QUOTE_POST_VC {
            self.performSegue(withIdentifier: "unwindToQuotePost", sender: self)
        }
        
    }


    func playExplosion() {
        
        let path = Bundle.main.path(forResource: "blast", ofType: "mp3")!
        
        do {
            explosionPlayer = try AVAudioPlayer(contentsOf: URL(string: path)!)
            explosionPlayer.prepareToPlay()
            explosionPlayer.play()
            
        } catch let err as NSError {
            print(err.debugDescription)
        } catch {
            print("Error Could not play Sound!")
        }
    }
    
    
}
