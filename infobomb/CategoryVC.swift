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
    let uploadMetadata = FIRStorageMetadata()
    
    var key: String! = nil
    var userID: String!
    var username: String!
    var explosionPlayer: AVAudioPlayer!
    var categories = [Category]()
    var checked = [String]()
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
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "categories-icon.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
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
        
        if FIRAuth.auth()?.currentUser != nil {
            username = FIRAuth.auth()?.currentUser?.displayName
        } else {
           print("No user is signed in and this shouldnt be saying this.")
        }
        userID = UserService.ds.currentUserID
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
                checked.append(category.name)
                cell.accessoryType = .checkmark
            } else if checked.count > 0 {
                for i in 0...checked.count - 1 {
//                    print(value)
                    if checked[i] == category.name {
                        doesItExist = true
                        checked.remove(at: i)
                        cell.accessoryType = .none
                        break
                    }
                }
                if doesItExist == false {
                    checked.append(category.name)
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
    
    
//    @IBAction func createPostBtnPressed(_ sender: AnyObject) {
//        
//        if checked.count > 0 {
//
//            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
//                print("You have to allow location to make a post!")
//            } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
//                
//                if previousVC == TEXT_POST_VC {
//                    self.gatherPostData(postType: "text", data: linkObj as AnyObject)
//                } else if previousVC == LINK_POST_VC {
//                    self.gatherPostData(postType: "link", data: linkObj as AnyObject)
//                } else if previousVC == IMAGE_POST_VC {
//                    self.gatherPostData(postType: "image", data: linkObj as AnyObject)
//                } else if previousVC == VIDEO_POST_VC {
//                    self.gatherPostData(postType: "video", data: linkObj as AnyObject)
//                } else if previousVC == AUDIO_POST_VC {
//                    self.gatherPostData(postType: "audio", data: linkObj as AnyObject)
//                } else if previousVC == QUOTE_POST_VC {
//                    if linkObj["text"] != nil {
//                        self.gatherPostData(postType: "quoteText", data: linkObj as AnyObject)
//                    } else if linkObj["image"] != nil {
//                        self.gatherPostData(postType: "quoteImg", data: linkObj as AnyObject)
//                    }
//                }
//            }
//        } else {
//            print("Please pick at least one category!")
//        }
//    }
//    
//    func gatherPostData(postType: String, data: AnyObject) {
//        
//        
//        let storageRef = storage.reference(forURL: "gs://infobomb-9b66c.appspot.com")
//        var selectedCategories: [String:AnyObject] = [:]
//
//        
//        post = [
//            "user_id": userID as AnyObject,
//            "username": username as AnyObject,
//            "post_ref": key as AnyObject,
//            "active": true as AnyObject,
//            "likes": 0 as AnyObject,
//            "dislikes": 0 as AnyObject,
//            "shares": 0 as AnyObject,
//            "latitude": DALLAS_LATITUDE as AnyObject,
//            "longitude": DALLAS_LONGITUDE as AnyObject,
//            "distance": 1000.0 as AnyObject,
//            "usersInRadius": 0 as AnyObject,
//            "created_at": FIRServerValue.timestamp() as AnyObject
//        ]
//        
//        let uniqueString = NSUUID().uuidString
//        
//        if postType == "text" {
//            
//            post["type"] = postType as AnyObject?
//
//            if let message = data as? String {
//                post["message"] = message as AnyObject?
//            }
//            self.postToFirebase()
//            
//        } else if postType == "link" {
//            
//            post["type"] = postType as AnyObject?
//            
//            if let linkTitle = data["title"] as! String? {
//                post["title"] = linkTitle as AnyObject?
//            }
//            if let linkDescription = data["description"] as! String? {
//                post["description"] = linkDescription as AnyObject?
//            }
//            if let linkShortUrl = data["canonicalUrl"] as! String? {
//                post["shortUrl"] = linkShortUrl as AnyObject?
//            }
//            if let linkUrl = data["url"] as! String? {
//                post["url"] = linkUrl as AnyObject?
//            }
//            if let msg = data["message"] as! String? {
//                post["message"] = msg as AnyObject?
//            }
//            if let linkImage = data["image"] as! NSData? {
//                //need to store in storage and reference it from path
//                let linkPreviewRef = storageRef.child("link-preview/image_\(NSUUID().uuidString)")
//                // Upload the file to the path "images/rivers.jpg"
//                let uploadTask = linkPreviewRef.put(linkImage as Data, metadata: nil) { metadata, error in
//                    if (error != nil) {
//
//                        print("Failed to upload image to firebase\n\n\n\n\n\n\n\n")
//                    } else {
//                        let downloadURL = metadata!.downloadURL()!.absoluteString
//                        self.post["image"] = downloadURL as AnyObject?
//                        self.postToFirebase()
//                    }
//                }
//                return
//            }
//            self.postToFirebase()
//            
//        } else if postType == "image" {
//            
//            post["type"] = postType as AnyObject?
//            
//            if let imageText = data["text"] as! String? {
//                post["message"] = imageText as AnyObject?
//            }
//            
//            let image = data["image"] as! NSData
//            
//            let imageRef = storageRef.child("images/image_post/image_\(uniqueString)")
//            
//                let uploadTask = imageRef.put(image as Data, metadata: nil) { metadata, error in
//                    if (error != nil) {
//                        // Uh-oh, an error occurred!
//                        print("Failed to upload image to firebase")
//                    } else {
//                        print("HERE")
//                        let downloadURL = metadata!.downloadURL()!.absoluteString
//                        self.post["image"] = downloadURL as AnyObject?
//                        self.postToFirebase()
//                    }
//                }
//        } else if postType == "video" {
//            
//            post["type"] = postType as AnyObject?
//            
//            
//            if let videoText = data["text"] as! String? {
//                post["message"] = videoText as AnyObject?
//            }
//            
//            let video = data["video"] as! NSData
//
//            let videoRef = storageRef.child("videos/video_post/video_\(uniqueString)")
//            
//            let uploadTask = videoRef.put(video as Data, metadata: nil) { metadata, error in
//                if (error != nil) {
//                    // Uh-oh, an error occurred!
//                    print("Failed to upload image to firebase")
//                } else {
//                    let downloadURL = metadata!.downloadURL()!.absoluteString
//                    self.post["video"] = downloadURL as AnyObject?
//                    
//                    if let videoThumbnail = data["thumbnail"] as! NSData? {
//                    
//                        let thumbnailRef = storageRef.child("videos/video_post/thumbnail_\(uniqueString)")
//                    
//                        let uploadTask = thumbnailRef.put(videoThumbnail as Data, metadata: nil) { metadata, error in
//                            if (error != nil) {
//                                // Uh-oh, an error occurred!
//                                print("Failed to upload image to firebase")
//                            } else {
//                                let downloadURL = metadata!.downloadURL()!.absoluteString
//                                self.post["thumbnail"] = downloadURL as AnyObject?
//                                self.postToFirebase()
//                            }
//                        }
//                    }
//                }
//            }
//        } else if postType == "audio" {
//            
//            post["type"] = postType as AnyObject?
//            post["title"] = data["title"] as! NSString
//            
//            let audio = data["audio"] as! NSData
//            let audioRef = storageRef.child("audio/audio_post/audio_\(uniqueString)")
//
//            uploadMetadata.contentType = "audio/mpeg"
//            
//            let uploadTask = audioRef.put(audio as Data, metadata: uploadMetadata) { metadata, error in
//                if (error != nil) {
//                    print("Failed to upload audio to firebase.")
//                } else {
//                    
//                    let name = "audio/audio_post/\(metadata!.name!)"
//                    let audioRefDownload = storageRef.child(name)
//                    
//                    //WHY THE FUCK DO I HAVE TO MAKE 2 CALLS?!
//                    
//                    // Fetch the download URL
//                    audioRefDownload.downloadURL { (URL, error) -> Void in
//                        if (error != nil) {
//                            print(error)
//                        } else {
//                            let downloadUrlString = "\(URL!)"
//                            self.post["audio"] = downloadUrlString as AnyObject
//                            self.postToFirebase()
//                        }
//                    }
//                }
//            }
//            
//        } else if postType == "quoteText" {
//            
//                post["type"] = "quote" as AnyObject?
//                post["quoteType"] = "text" as AnyObject?
//                
//                if let author = data["author"] {
//                    post["author"] = author as AnyObject?
//                }
//                post["text"] = data["text"] as! NSString
//                self.postToFirebase()
//                
//        } else if postType == "quoteImg" {
//            
//                post["type"] = "quote" as AnyObject?
//                post["quoteType"] = "image" as AnyObject?
//                
//                let image = data["image"] as! NSData
//                
//                let quoteRef = storageRef.child("images/quote_post/image_\(uniqueString)")
//                
//                let uploadTask = quoteRef.put(image as Data, metadata: nil) { metadata, error in
//                    if (error != nil) {
//                        print("Failed to upload image to firebase")
//                    } else {
//                        let downloadURL = metadata!.downloadURL()!.absoluteString
//                        self.post["image"] = downloadURL as AnyObject?
//                        self.postToFirebase()
//                    }
//                }
//        }
//        
//    }
//    
//    func postToFirebase() {
//        
//        let activeFirebasePost = PostService.ds.REF_ACTIVE_POSTS.child(key)
//        let userPostRef = UserService.ds.REF_USER_POSTS.child(userID).child(key)
//        let postRef = PostService.ds.REF_POSTS.child(key)
//
//        activeFirebasePost.setValue(post)
//        firebasePost.setValue(post)
//        userPostRef.setValue(post)
//        
//        for check in checked {
//            let selectedCategory = [
//                check: true
//            ]
//            postRef.child("categories").updateChildValues(selectedCategory)
//            userPostRef.child("categories").updateChildValues(selectedCategory)
//            activeFirebasePost.child("categories").updateChildValues(selectedCategory)
//        }
//        
//        let userPostsRef = UserService.ds.REF_USER_CURRENT.child("posts")
//        let userPost = [
//            key: true
//        ]
//        userPostsRef.updateChildValues(userPost)
//        
//        let url = URL(string: "https://nameless-chamber-44579.herokuapp.com/post")!
//        Alamofire.request(url, method: .post, parameters: post).validate().responseJSON { response in
//            switch response.result {
//            case .success( _):
//                print(response.result.value!)
//                print("Validation Successful")
//                self.playExplosion()
//            case .failure(let error):
//                print("POST REQUEST ERROR: \(error)")
//            }
//        }
//    }
//    
//
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        
        if previousVC == TEXT_POST_VC {
            //locationService.stopUpdatingLocation()
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
    
    func notificationBtnPressed() {
        
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if checked.count > 0 && checked.count < 3 {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if (segue.identifier == BOMB_VC) {
            
            let bombVC = segue.destination as! BombVC
            bombVC.checked = self.checked
            bombVC.bombData = linkObj
            bombVC.previousVC = previousVC
        }
        
    }

}
    

