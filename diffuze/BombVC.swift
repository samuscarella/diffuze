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
    let iD = UserService.ds.currentUserID
    
    var locationService = LocationService()
    var geoFire: GeoFire?
    var query: GFQuery?
    var explosionPlayer: AVAudioPlayer!
    var center: CLLocation?
    var previousVC: String!
    var userID: String!
    var username: String!
    var key: String! = nil
    var checked = [String]()
    var currentLocation: [String:AnyObject] = [:]
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
    var totalUsersTrackable: Int!
    var distanceTraveled = 0
    var targetUsersRemaining = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationService.stopUpdatingLocation()

        bombVCView.layer.cornerRadius = 6
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        URL_BASE.child("users").child(iD).observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
            
            let user = snapshot.value as! Dictionary<String,AnyObject>
            
            let userLat = user["latitude"] as? Double
            let userLong = user["longitude"] as? Double
            
            self.center = CLLocation(latitude: userLat!, longitude: userLong!)
        })
        
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
         
            self.totalUsersTrackable = userLocations.count
            self.explosionAnimationImageView.startAnimating()
            self.startGeoFireQuery()
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    func startGeoFireQuery() {
        
        meters += 1.0
        query = geoFire?.query(at: center, withRadius: Double(meters))

        query?.observe(.keyEntered, with: { (key: String?, location: CLLocation?) in
            
            if !self.usersInRadius.contains(key!) && self.userID != key {
                self.usersInRadius.append(key!)
                self.uncheckedUsersInRadius.append(key!)
            }
        })
        
        query?.observeReady({
            
            if self.totalUsersTrackable < 100 {
                
                if self.meters == MAX_DISTANCE {
            
                    self.getAllSubscribedUsersFromRadius() { uniqueSubscribers, distanceTraveled in
                        
                        self.distanceTraveled = distanceTraveled
                        self.createPost()
                    }
                } else {
                    self.startGeoFireQuery()
                }
            } else if self.totalUsersTrackable >= 100 {
            
                //NEEDS WORK!!!!
                
                self.getAllSubscribedUsersFromRadius() { uniqueSubscribers, distanceTraveled in
            
                    print("All Subscribers: \(self.subscribedUsers)")
                    
                    self.distanceTraveled = distanceTraveled
                    
                    if uniqueSubscribers < TARGET_SUBS && self.meters != MAX_DISTANCE {
                        self.startGeoFireQuery()
                    } else {
                        self.createPost()
                    }
                }
            }
        })
    }
    
    func getAllSubscribedUsersFromRadius(completion: @escaping (_ uniqueSubscribers: Int, _ distanceTraveled: Int) -> Void) {
        
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
                            if name == sub.key || sub.key == "All" {
                                
                                self.subscribedUsers.append(iD)
                                isUserSubscribed = true
                                
                                let userLocation = CLLocation(latitude: userLat!, longitude: userLong!)
                                let distance = userLocation.distance(from: self.center!)

                                if Int(distance) > self.distanceTraveled {
                                    self.distanceTraveled = Int(distance)
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
            completion(self.subscribedUsers.count, self.distanceTraveled)
        })
    }
    
    func createPost() {
        
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
            } else if bombData["image"] == nil {
                self.gatherPostData(postType: "quoteText", data: bombData as AnyObject)
            }
        }
    }
    
    func gatherPostData(postType: String, data: AnyObject) {
        
        let storageRef = storage.reference(forURL: "gs://infobomb-9b66c.appspot.com")
        
        let latitude = currentLocation["latitude"] as! Double
        let longitude = currentLocation["longitude"] as! Double
        
        post = [
            "user_id": userID as AnyObject,
            "username": username as AnyObject,
            "post_ref": key as AnyObject,
            "active": true as AnyObject,
            "likes": 0 as AnyObject,
            "dislikes": 0 as AnyObject,
            "score": 0 as AnyObject,
            "rating": 0 as AnyObject,
            "shares": 0 as AnyObject,
            "latitude": latitude as AnyObject,
            "longitude": longitude as AnyObject,
            "recentInteractions": 0 as AnyObject,
            "distance": self.distanceTraveled as AnyObject,
            "newReceivers": self.subscribedUsers.count as AnyObject,
            "receivers": self.subscribedUsers as AnyObject,
            "init": true as AnyObject,
            "last_interaction": FIRServerValue.timestamp() as AnyObject,
            "created_at": FIRServerValue.timestamp() as AnyObject,
            "detonated_at": FIRServerValue.timestamp() as AnyObject
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
            newMetadata.contentType = "video/quicktime"

            let uploadTask = videoRef.put(video as Data, metadata: newMetadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                    print("Failed to upload image to firebase")
                } else {
                    
                    let downloadURL = metadata?.downloadURL()
                    
                    self.post["video"] = downloadURL?.absoluteString as AnyObject?
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
        
        for check in checked {
            selectedCategories[check] = true
        }
        
        postRef.child("categories").updateChildValues(selectedCategories)
        userPostRef.child("categories").updateChildValues(selectedCategories)
        activeFirebasePost.child("categories").updateChildValues(selectedCategories)
        
        let userPostsRef = UserService.ds.REF_USER_CURRENT?.child("posts")
        let userPost = [
            key: true
        ]
        userPostsRef?.updateChildValues(userPost)
        
        for user in self.subscribedUsers {
            secondGroup.enter()
            URL_BASE.child("users").child(user).child("radar").updateChildValues(userPost)
            secondGroup.leave()
        }
        
        secondGroup.notify(queue: DispatchQueue.main, execute: {
            self.bombFinished()
            Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.goToRadarVC), userInfo: nil, repeats: false);
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
