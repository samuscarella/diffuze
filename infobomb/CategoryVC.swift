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
import SCLAlertView
import GeoFire

private var latitude = 0.0
private var longitude = 0.0

class CategoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, CLUploaderDelegate {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createBtn: MaterialButton!
    
    let storage = FIRStorage.storage()
    let firebasePost = PostService.ds.REF_POSTS.childByAutoId()
    let uploadMetadata = FIRStorageMetadata()
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let iD = UserService.ds.currentUserID
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var key: String! = nil
    var userID: String!
    var username: String!
    var explosionPlayer: AVAudioPlayer!
    var checked = [String]()
    var message: String?
    var linkObj: [String:AnyObject] = [:]
    var previousVC: String!
    var post = [String:AnyObject]()
    var postImg: Data?
    var fileExtension: String?
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    var notifications = [NotificationCustom]()

    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        dot = UIView(frame: CGRect(x: 14, y: 16, width: 12, height: 12))
        dot.backgroundColor = UIColor.red
        dot.layer.cornerRadius = dot.frame.size.height / 2
        dot.isHidden = true
        dot.isUserInteractionEnabled = false
        dot.isExclusiveTouch = false
        dot.isHidden = true

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
        button.addTarget(self, action: #selector(self.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        button.addSubview(dot)
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
        }
        
        userID = UserService.ds.currentUserID
        key = firebasePost.key

        tableView.delegate = self
        tableView.dataSource = self
                
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        notificationService = NotificationService()
        notificationService.getNotifications()
        notificationService.watchRadar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotifications), name: NSNotification.Name(rawValue: "newFollowersNotification"), object: nil)
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        categories = []
        for i in 0...CATEGORY_TITLE_ARRAY.count - 1 {
            if i > 0 {
                let category = Category(name: CATEGORY_TITLE_ARRAY[i], img: CATEGORY_IMAGE_ARRAY[i])
                categories.append(category)
            }
        }
        tableView.reloadData()        
    }
    
    func popoverDismissed() {
        
        notificationService.getNotifications()
    }
    
    func updateNotifications(notification: NSNotification) {
        
        self.notifications = []
        let incomingNotifications = notification.object as! [NotificationCustom]
        self.notifications = incomingNotifications
        var newNotifications = false
        for n in notifications {
            if n.read == false {
                newNotifications = true
                dot.isHidden = false
                break
            }
        }
        if !newNotifications {
            dot.isHidden = true
        }
        print("Updated Notifications From Followers: \(self.notifications)")
    }
    
    func notificationBtnPressed() {
        
        let notificationVC = self.storyboard?.instantiateViewController(withIdentifier: "NotificationVC") as! NotificationVC
        notificationVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        notificationVC.notifications = self.notifications
        present(notificationVC, animated: true, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &latitude {
            latitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["latitude"] = latitude as AnyObject?
        }
        if context == &longitude {
            longitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["longitude"] = longitude as AnyObject?
        }
    }
    
    func updateUserLocation() {
        
        if currentLocation["latitude"] != nil && currentLocation["longitude"] != nil {
            
            geoFire.setLocation(CLLocation(latitude: (currentLocation["latitude"] as? CLLocationDegrees)!, longitude: (currentLocation["longitude"] as? CLLocationDegrees)!), forKey: iD)
            
            if UserService.ds.REF_USER_CURRENT != nil {
                let longRef = UserService.ds.REF_USER_CURRENT?.child("longitude")
                let latRef = UserService.ds.REF_USER_CURRENT?.child("latitude")
                
                longRef?.setValue(currentLocation["longitude"])
                latRef?.setValue(currentLocation["latitude"])
            }
            print(currentLocation)
        }
    }
    
    func terminateAuthentication() {
        
        do {
            try FIRAuth.auth()!.signOut()
            self.performSegue(withIdentifier: "unwindToLoginVC", sender: self)
        } catch let err as NSError {
            print(err)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        
        timer?.invalidate()
    }
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let category = categories[(indexPath as NSIndexPath).row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") as? CategoryCell {
        
            cell.request?.cancel()
            
            cell.configureCell(category)
            
            if checked.count > 0 {
                for i in 0...checked.count - 1 {
                    if checked[i] == category.name {
                        cell.categoryCheckmark.image = UIImage(named: "checked")
                        break
                    }
                }
            }

            return cell
            
        } else {
            return CategoryCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
 
        if let cell = tableView.cellForRow(at: indexPath) as? CategoryCell {
            
            let category = categories[(indexPath as NSIndexPath).row]
            
            var doesItExist = false
            
            if checked.count == 0 {
                checked.append(category.name)
                cell.categoryCheckmark.image = UIImage(named: "checked")
            } else if checked.count > 0 {
                for i in 0...checked.count - 1 {
                    if checked[i] == category.name {
                        doesItExist = true
                        checked.remove(at: i)
                        cell.categoryCheckmark.image = nil
                        break
                    }
                }
                if doesItExist == false {
                    checked.append(category.name)
                    cell.categoryCheckmark.image = UIImage(named: "checked")
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
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        
        if previousVC == TEXT_POST_VC {
            self.performSegue(withIdentifier: "unwindToTextPost", sender: self)
        } else if previousVC == LINK_POST_VC {
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        let alertView = SCLAlertView()
        
        if checked.count > 0 && checked.count < 3 {
            return true
        } else if checked.count > 2 {
            
            alertView.showWarning("Warning", subTitle: "\nPlease pick only two of the best categories that best describe your post.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xffb400, colorTextButton: 0x000000, circleIconImage: UIImage(named: "warning"), animationStyle: .topToBottom)
            return false
        } else if checked.count == 0 {
            
            alertView.showWarning("Warning", subTitle: "\nPlease pick at least one category.", closeButtonTitle: "Ok", duration: 0.0, colorStyle: 0xffb400, colorTextButton: 0x000000, circleIconImage: UIImage(named: "warning"), animationStyle: .topToBottom)
            return false
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if (segue.identifier == BOMB_VC) {
            
            let bombVC = segue.destination as! BombVC
            bombVC.checked = self.checked
            bombVC.bombData = linkObj
            bombVC.previousVC = previousVC
            bombVC.currentLocation = currentLocation
            if self.fileExtension != nil {
                bombVC.fileExtension = self.fileExtension
            }
            locationService.stopUpdatingLocation()
        }
        
    }

}
    

