//
//  BombVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 11/22/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import GeoFire
import Firebase
import AVKit
import AVFoundation
import SwiftyGif
import Alamofire

class BombVC: UIViewController {
    
    @IBOutlet weak var explosionAnimationImageView: UIImageView!
    @IBOutlet weak var activityLbl: UILabel!
    @IBOutlet weak var bombVCView: UIView!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let storage = FIRStorage.storage()
    let firebasePost = PostService.ds.REF_POSTS.childByAutoId()
    let userRef = UserService.ds.REF_USERS
    let uploadMetadata = FIRStorageMetadata()

    var geoFire: GeoFire?
    var query: GFQuery?
    var explosionPlayer: AVAudioPlayer!
    var center: CLLocation?
    var previousVC: String!
    var userID: String!
    var username: String!
    var key: String! = nil
    var checked = [String]()
    var bombData: [String:AnyObject] = [:]
    var post = [String:AnyObject]()
    var postImg: Data?
    var usersInRadius = [String]()
    var uncheckedUsersInRadius = [String]()
    var subscribedUsers = [String]()
    var latDeltVal = 0.0
    var longDeltVal = 0.0
    var meters = 0.0
    var explosionArray = [UIImage]()
    var myGroup = DispatchGroup()
    var secondGroup = DispatchGroup()
    var videoLayer: AVPlayerLayer?
    var player: AVPlayer?
    var fileExtension: String?
    var checkingUserInRadius: Bool = false
    var distanceTraveled: Int!
    var totalUsersTrackable: [[String:AnyObject]] = [[:]]
    var targetUsersCount = 100
    var queryCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bombVCView.layer.cornerRadius = 6
        geoFire = GeoFire(firebaseRef: geofireRef)
        center = CLLocation(latitude: DALLAS_LATITUDE, longitude: DALLAS_LONGITUDE)
        
        for i in 0...91 {
            if i < 10 {
                self.explosionArray.append(UIImage(named: "explosion__0000\(i)")!)
            } else {
                self.explosionArray.append(UIImage(named: "explosion__000\(i)")!)
            }
        }
        userID = UserService.ds.currentUserID
        if FIRAuth.auth()?.currentUser != nil {
            username = FIRAuth.auth()?.currentUser?.displayName
        } else {
            print("No user is signed in and this shouldnt be saying this.")
        }
        key = firebasePost.key
        self.explosionAnimationImageView.animationImages = explosionArray
        
        URL_BASE.child("user-locations").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in

            let userLocations = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
         
            for userLoc in userLocations {
                
                let userLocDict = userLoc.value as! Dictionary<String,AnyObject>
                self.totalUsersTrackable.append(userLocDict)
                print(self.totalUsersTrackable.count)
            }
            
            self.explosionAnimationImageView.startAnimating()
            self.startGeoFireQuery(latitudeDelta: self.latDeltVal + 1000.0, longitudeDelta: self.longDeltVal + 1000.0)
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

//        self.explosionAnimationImageView.startAnimating()
//        startGeoFireQuery(latitudeDelta: latDeltVal + 1000.0, longitudeDelta: longDeltVal + 1000.0)
    }
    
    func startGeoFireQuery(latitudeDelta: Double, longitudeDelta: Double) {
        
//        let regionWithDistance = MKCoordinateRegionMakeWithDistance((center?.coordinate)!, latitudeDelta, longitudeDelta)
//        let region = MKCoordinateRegionMake((center?.coordinate)!, regionWithDistance.span)
        meters += 1.0
        query = geoFire?.query(at: center, withRadius: Double(meters))

        query?.observe(.keyEntered, with: { (key: String?, location: CLLocation?) in
            
            if !self.usersInRadius.contains(key!) && self.userID != key {
                self.usersInRadius.append(key!)
                self.uncheckedUsersInRadius.append(key!)
            }
        })
        
        query?.observeReady({
            
            print(self.meters * 1)
            print(self.usersInRadius.count)
            print(self.subscribedUsers)
            print(self.totalUsersTrackable.count)
            
            if self.totalUsersTrackable.count - 2 < 100 {
                
                print("\(self.meters):\(MAX_DISTANCE)")
                if self.meters == MAX_DISTANCE {

                    self.getAllSubscribedUsersFromRadius() { uniqueSubscribers, distanceTraveled in
                        
                        print("All Subscribers: \(self.subscribedUsers)")
                        
                        self.distanceTraveled = distanceTraveled
                        self.createPost()
                    }
                } else if self.usersInRadius.count == self.totalUsersTrackable.count - 2 {
                    
                    self.getAllSubscribedUsersFromRadius() { uniqueSubscribers, distanceTraveled in
                        
                        print("All Subscribers: \(self.subscribedUsers)")
                        
                        self.distanceTraveled = distanceTraveled
                        self.createPost()
                    }
                } else {
                    self.continueGeoFireQuery()
                }
            } else if self.totalUsersTrackable.count - 1 >= 100 {
                
                self.getAllSubscribedUsersFromRadius() { uniqueSubscribers, distanceTraveled in

                    print("All Subscribers: \(self.subscribedUsers)")
                    
                    self.distanceTraveled = distanceTraveled
                    
                    if uniqueSubscribers < TARGET_SUBS && self.meters != MAX_DISTANCE {
                        self.continueGeoFireQuery()
                    } else {
                        self.createPost()
                    }
                }
            }
        })
    }
    
    func continueGeoFireQuery() {
        self.latDeltVal += 1000.0
        self.longDeltVal += 1000.0
        self.startGeoFireQuery(latitudeDelta: self.latDeltVal, longitudeDelta: self.longDeltVal)
    }
    
    func getAllSubscribedUsersFromRadius(completion: @escaping (_ uniqueSubscribers: Int, _ distanceTraveled: Int) -> Void) {
        
        var distanceTraveled = 0
        
        for user in uncheckedUsersInRadius {
            print(user)
        }
        while(self.uncheckedUsersInRadius.count > 0) {
            
            myGroup.enter()
            let iD = uncheckedUsersInRadius.removeFirst()
            URL_BASE.child("users").child(iD).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let value = snapshot.value as? NSDictionary
                let subscriptions = value?["subscriptions"] as? Dictionary<String, AnyObject>
                let userLat = value?["latitude"] as? Double
                let userLong = value?["longitude"] as? Double
                
                var isUserSubscribed = false

                if (subscriptions != nil) {
                    for name in self.checked {
                        for sub in subscriptions! {
                            if name == sub.key {
                                
                                self.subscribedUsers.append(iD)
                                isUserSubscribed = true
                                
                                let userLocation = CLLocation(latitude: 35.1495, longitude: 90.0490)
                                let distance = userLocation.distance(from: self.center!)

                                if Int(distance) > distanceTraveled {
                                    distanceTraveled = Int(distance)
                                }
                                break
                            }
                        }
                        if isUserSubscribed {
                            break
                        }
                    }
                }
                self.myGroup.leave()
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
        myGroup.notify(queue: DispatchQueue.main, execute: {
            completion(self.subscribedUsers.count, distanceTraveled)
        })
    }
    
    func createPost() {
        
        if checked.count > 0 {
            
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
                print("You have to allow location to make a post!")
            } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
                
                if previousVC == TEXT_POST_VC {
                    self.gatherPostData(postType: "text", data: bombData as AnyObject)
                } else if previousVC == LINK_POST_VC {
                    self.gatherPostData(postType: "link", data: bombData as AnyObject)
                } else if previousVC == IMAGE_POST_VC {
                    self.gatherPostData(postType: "image", data: bombData as AnyObject)
                } else if previousVC == VIDEO_POST_VC {
                    self.gatherPostData(postType: "video", data: bombData as AnyObject)
                } else if previousVC == AUDIO_POST_VC {
                    self.gatherPostData(postType: "audio", data: bombData as AnyObject)
                } else if previousVC == QUOTE_POST_VC {
                    if bombData["image"] != nil {
                        self.gatherPostData(postType: "quoteImg", data: bombData as AnyObject)
                    } else if bombData["image"] != nil {
                        self.gatherPostData(postType: "quoteText", data: bombData as AnyObject)
                    }
                }
            }
        } else {
            print("Please pick at least one category!")
        }
    }
    
    func gatherPostData(postType: String, data: AnyObject) {
        
        let storageRef = storage.reference(forURL: "gs://infobomb-9b66c.appspot.com")
        
        let miles = Double(self.distanceTraveled) * 0.000621371
        
        var finalDistance: Double
        
        if miles < 1 {
            finalDistance = 1
        } else {
            finalDistance = round(miles)
        }
        let intFinalDistance = Int(finalDistance)
        
        post = [
            "user_id": userID as AnyObject,
            "username": username as AnyObject,
            "post_ref": key as AnyObject,
            "active": true as AnyObject,
            "likes": 0 as AnyObject,
            "dislikes": 0 as AnyObject,
            "rating": 0 as AnyObject,
            "shares": 0 as AnyObject,
            "latitude": DALLAS_LATITUDE as AnyObject,
            "longitude": DALLAS_LONGITUDE as AnyObject,
            "distance": intFinalDistance as AnyObject,
            "usersInRadius": self.subscribedUsers.count as AnyObject,
            "created_at": FIRServerValue.timestamp() as AnyObject
        ]
        
        self.activityLbl.text = "Sending Post..."
        
        let uniqueString = NSUUID().uuidString
        
        if postType == "text" {
            
            post["type"] = postType as AnyObject?
            
            if let message = data["message"] as? String {
                post["message"] = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as AnyObject?
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
            if let msg = data["message"] as! String? {
                post["message"] = msg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as AnyObject?
            }
            if let linkImage = data["image"] as! NSData? {
                //need to store in storage and reference it from path
                let linkPreviewRef = storageRef.child("link-preview/image_\(NSUUID().uuidString)")
                // Upload the file to the path "images/rivers.jpg"
                let uploadTask = linkPreviewRef.put(linkImage as Data, metadata: nil) { metadata, error in
                    if (error != nil) {
                        print("Failed to upload image to firebase\n\n\n\n\n\n\n\n")
                    } else {
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
                post["message"] = imageText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as AnyObject?
            }
            
            let image = data["image"] as! NSData
            
            let imageRef = storageRef.child("images/image_post/image_\(uniqueString)")
            
            let uploadTask = imageRef.put(image as Data, metadata: nil) { metadata, error in
                if (error != nil) {

                    print("Failed to upload image to firebase")
                } else {

                    let downloadURL = metadata!.downloadURL()!.absoluteString
                    self.post["image"] = downloadURL as AnyObject?
                    self.postToFirebase()
                }
            }
        } else if postType == "video" {
            
            post["type"] = postType as AnyObject?
            
            if let videoText = data["text"] as! String? {
                post["message"] = videoText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as AnyObject?
            }
            
            let video = data["video"] as! NSData
            
            let videoRef = storageRef.child("videos/video_post/video_\(uniqueString)")
            
            let newMetadata = FIRStorageMetadata()
            newMetadata.contentType = "video/quicktime";

            let uploadTask = videoRef.put(video as Data, metadata: newMetadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                    print("Failed to upload image to firebase")
                } else {
                    
                    let downloadURL = metadata?.downloadURL()
                    
                    self.post["video"] = downloadURL as AnyObject?
                    self.post["contentType"] = metadata!.contentType as AnyObject?
                    
                    if let videoThumbnail = data["thumbnail"] as! NSData? {
                        
                        let thumbnailRef = storageRef.child("videos/video_post/thumbnail_\(uniqueString)")
                        
                        let uploadTask = thumbnailRef.put(videoThumbnail as Data, metadata: nil) { metadata, error in
                            if (error != nil) {
                                // Uh-oh, an error occurred!
                                print("Failed to upload image to firebase")
                            } else {
                                
                                let downloadURL = metadata!.downloadURL()!.absoluteString
                                self.post["thumbnail"] = downloadURL as AnyObject?
                                self.postToFirebase()
                            }
                        }
                    }
                }
            }
        } else if postType == "audio" {
            
            post["type"] = postType as AnyObject?
            
            if let title = data["title"] as? String {
                let trimmedTitle = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                post["title"] = trimmedTitle as AnyObject?
            }
            
            let audio = data["audio"] as! NSData
            let audioRef = storageRef.child("audio/audio_post/audio_\(uniqueString)")
            
            uploadMetadata.contentType = "audio/m4a"
            
            let uploadTask = audioRef.put(audio as Data, metadata: uploadMetadata) { metadata, error in
                if (error != nil) {
                    print("Failed to upload audio to firebase.")
                } else {
                    
                    let downloadUrlString = metadata!.downloadURL()!.absoluteString
                    self.post["audio"] = downloadUrlString as AnyObject?
                    self.postToFirebase()
                }
            }
            
        } else if postType == "quoteText" {
            
            post["type"] = "quote" as AnyObject?
            post["quoteType"] = "text" as AnyObject?
            
            if let author = data["author"] {
                post["author"] = author as AnyObject?
            }
            
            if let text = data["text"] as? String {
                let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                post["text"] = trimmedText as AnyObject?
            }
            self.postToFirebase()
            
        } else if postType == "quoteImg" {
            
            post["type"] = "quote" as AnyObject?
            post["quoteType"] = "image" as AnyObject?
            
            let image = data["image"] as! NSData
            let quoteRef = storageRef.child("images/quote_post/image_\(uniqueString)")
            
            let uploadTask = quoteRef.put(image as Data, metadata: nil) { metadata, error in
                if (error != nil) {
                    print("Failed to upload image to firebase")
                } else {
                    let downloadURL = metadata!.downloadURL()!.absoluteString
                    self.post["image"] = downloadURL as AnyObject?
                    self.postToFirebase()
                }
            }
        }
    }
    
    func postToFirebase() {
        
        let activeFirebasePost = PostService.ds.REF_ACTIVE_POSTS.child(key)
        let userPostRef = UserService.ds.REF_USER_POSTS.child(userID).child(key)
        let postRef = PostService.ds.REF_POSTS.child(key)
        
        activeFirebasePost.setValue(post)
        firebasePost.setValue(post)
        userPostRef.setValue(post)
        
        var selectedCategories: Dictionary<String, Bool> = [:]
        
        print(checked)
        for check in checked {
            selectedCategories[check] = true
        }
        
        postRef.child("categories").updateChildValues(selectedCategories)
        userPostRef.child("categories").updateChildValues(selectedCategories)
        activeFirebasePost.child("categories").updateChildValues(selectedCategories)
        
        let userPostsRef = UserService.ds.REF_USER_CURRENT.child("posts")
        let userPost = [
            key: true
        ]
        userPostsRef.updateChildValues(userPost)
        
        for user in self.subscribedUsers {
            secondGroup.enter()
            URL_BASE.child("users").child(user).child("radar").updateChildValues(userPost)
            secondGroup.leave()
        }
        
        secondGroup.notify(queue: DispatchQueue.main, execute: {
            self.bombFinished()
            Timer.scheduledTimer(timeInterval: 1.8, target: self, selector: #selector(self.goToRadarVC), userInfo: nil, repeats: false);
        })
    }

    func goToRadarVC() {
        self.performSegue(withIdentifier: "ActivityVC", sender: nil)
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
    
    func bombFinished() {
        self.explosionAnimationImageView.stopAnimating()
        let gif = UIImage(gifName: "animated-green-checkmark")
        let gifmanager = SwiftyGifManager(memoryLimit: 20)
        self.checkmarkImageView.setGifImage(gif, manager: gifmanager, loopCount: 1)
        self.checkmarkImageView.startAnimatingGif()
        self.activityLbl.text = "Complete!"
    }
    
}
