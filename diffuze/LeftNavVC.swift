//
//  LeftNavVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/6/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import GeoFire

private var latitude: Double = 0.0
private var longitude: Double = 0.0

class LeftNavVC: UITableViewController, CLLocationManagerDelegate {
    

    @IBOutlet var table: UITableView!
    @IBOutlet var navButtons: [UIButton]!
    @IBOutlet weak var activityBtn: UIButton!
    
    var locationService: LocationService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationService = LocationService()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        self.view.backgroundColor = UIColor.black
        table.isScrollEnabled = false
        table.allowsSelection = false
        activityBtn.setTitleColor(CRIMSON, for: UIControlState())
    }
    
    func terminateAuthentication() {
        
        do {
            try FIRAuth.auth()!.signOut()
            self.performSegue(withIdentifier: "unwindToLoginVC", sender: self)
        } catch let err as NSError {
            print(err)
        }
    }
    
    @IBAction func navBtnPressed(_ sender: AnyObject) {
        
        for button in navButtons {
            button.setTitleColor(UIColor.white, for: UIControlState())
        }
        
        if(sender.tag == 1) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 2) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 3) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 4) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 5) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 6) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 7) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 8) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 9) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 10) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 11) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
        } else if(sender.tag == 12) {
            sender.setTitleColor(CRIMSON, for: UIControlState())
            
                do {
                    try FIRAuth.auth()!.signOut()
                    locationService.stopUpdatingLocation()
                } catch let err as NSError {
                    print(err)
                }            

        }
        
    }
    
}
