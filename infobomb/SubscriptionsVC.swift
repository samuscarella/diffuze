//
//  SubscriptionsVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/6/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import GeoFire

private var latitude: Double = 0.0
private var longitude: Double = 0.0

class SubscriptionsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let iD = UserService.ds.currentUserID

    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var subscribedToAll = false
    
    static var imageCache = NSCache<AnyObject, AnyObject>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "subscribe-rss-button.png")
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
//        button.addTarget(self, action: #selector(SubscriptionsVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton

        geoFire = GeoFire(firebaseRef: geofireRef)
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        tableView.delegate = self
        tableView.dataSource = self
        
        URL_BASE.child("users").child(iD).child("subscriptions").child("All").observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
            
            let allSubscription = snapshot.value as? Bool ?? false
            
            if allSubscription {
                self.subscribedToAll = true
            }
            
            self.categories = []
            for i in 0...CATEGORY_TITLE_ARRAY.count - 1 {
                let category = Category(name: CATEGORY_TITLE_ARRAY[i], img: CATEGORY_IMAGE_ARRAY[i])
                self.categories.append(category)
            }
            self.tableView.reloadData()
        })
        
        URL_BASE.child("users").child(iD).child("subscriptions").observe(FIRDataEventType.value, with: { snapshot in
            
            let subscriptions = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            let cells = self.tableView.visibleCells as? [SubscriptionCell] ?? []
            
            self.subscribedToAll = false
            for sub in subscriptions {
                if sub.key == "All" {
                    self.subscribedToAll = true
                }
            }
            if self.subscribedToAll == true {
                for cell in cells {
                    cell.subscriptionSwitch.isOn = true
                }
            } else {
                for cell in cells {
                    var isSubscribedToCell = false
                    for sub in subscriptions {
                        if cell.category.name == sub.key {
                            isSubscribedToCell = true
                            cell.subscriptionSwitch.isOn = true
                        }
                    }
                    if !isSubscribedToCell {
                        cell.subscriptionSwitch.isOn = false
                    }
                }
            }
        })
        
        //Burger side menu
        if revealViewController() != nil {
            
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }
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

    override func viewWillDisappear(_ animated: Bool) {
        
        timer?.invalidate()
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
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let category = categories[(indexPath as NSIndexPath).row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionCell") as? SubscriptionCell {
            
            cell.request?.cancel()
            
            cell.configureCell(category, subscribedToAll)
            
            return cell
            
        } else {
            return SubscriptionCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
}
