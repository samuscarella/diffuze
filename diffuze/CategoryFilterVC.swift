//
//  CategoryFilterVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/14/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import GeoFire

private var latitude = 0.0
private var longitude = 0.0

class CategoryFilterVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    let iD = UserService.ds.currentUserID
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let personalFilterOptions = ["My Posts","Liked","Disliked"]
    let postTypeFilterOptions = ["All","Text","Link","Image","Video","Audio","Quote"]
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var checked = [String]()
    var comingFromCategoryVC = true
    var previousVC: String!
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    var notifications = [NotificationCustom]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "categories-icon")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView
        
        dot = UIView(frame: CGRect(x: 14, y: 16, width: 12, height: 12))
        dot.backgroundColor = UIColor.red
        dot.layer.cornerRadius = dot.frame.size.height / 2
        dot.isHidden = true
        dot.isUserInteractionEnabled = false
        dot.isExclusiveTouch = false
        dot.isHidden = true
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
                button.addTarget(self, action: #selector(self.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        button.addSubview(dot)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton

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
        
        NotificationCenter.default.addObserver(locationService, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
        
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
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") as? CategoryCell {
                
                let category = categories[(indexPath as NSIndexPath).row]
                                
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
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        
        if previousVC == "MyInfoVC" {
            
            self.performSegue(withIdentifier: "unwindToMyInfoVC", sender: self)
        } else if previousVC == "RadarVC" {
            self.performSegue(withIdentifier: "unwindToActivityVC", sender: self)
        } else if previousVC == "ViralVC" {
            self.performSegue(withIdentifier: "unwindToViralVC", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if previousVC == "MyInfoVC" {
            
            let vC = segue.destination as! MyInfoVC;
            vC.categoryFilterOptions = self.checked
            vC.comingFromCategoryFilterVC = true
        } else if previousVC == "ActivityVC" {
            
            let vC = segue.destination as! ActivityVC;
            vC.categoryFilterOptions = self.checked
            vC.comingFromCategoryFilterVC = true
        } else if previousVC == "ViralVC" {
            
            let vC = segue.destination as! ViralVC;
            vC.categoryFilterOptions = self.checked
            vC.comingFromCategoryFilterVC = true
        }
    }
    
    @IBAction func darkenedViewBtnPressed(_ sender: AnyObject) {
        
    }
}
