//
//  ActivityVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import CoreLocation

class ActivityVC: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var burgerBtn: UIBarButtonItem!
    @IBOutlet weak var notificationBtn: UIBarButtonItem!
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!

    
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
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()

        //Burger side menu
        if revealViewController() != nil {
            
            burgerBtn.target = revealViewController()
            burgerBtn.action = #selector(SWRevealViewController.revealToggle(_:))
            
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
        print("LatitudeOfUser: \(currentLocation.coordinate.latitude)...LongitudeOfUser: \(currentLocation.coordinate.longitude)")
    }

    func notificationBtnPressed() {
    }
    
    @IBAction func unwindToActivityVC(segue: UIStoryboardSegue) {
        
    }

}
