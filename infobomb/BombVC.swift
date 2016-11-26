//
//  BombVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 11/22/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import GeoFire
import FirebaseDatabase
import FirebaseAuth

class BombVC: UIViewController {
        
    @IBOutlet weak var bombVCView: UIView!
    @IBOutlet weak var activitySpinnerView: UIActivityIndicatorView!
    
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    
    var bombData: [String:AnyObject] = [:]
    var locations: [[Double:Double]] = [[:]]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bombVCView.layer.cornerRadius = 6
        activitySpinnerView.startAnimating()
        print("Bomb Data: \(bombData)")
        
        let geoFire = GeoFire(firebaseRef: geofireRef)
        let center = CLLocation(latitude: SAN_FRANCISCO_LATITUDE, longitude: SAN_FRANCISCO_LONGITUDE)
        
        let query = geoFire?.query(at: center, withRadius: 50)
        
        var queryHandle = query?.observe(.keyEntered, with: { (key, location) in
            print("Key '\(key)' entered the search area and is at location '\(location)'\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
        })
        
        query?.observeReady({
            print("All initial data has been loaded and events have been fired!")
        })

    }
    
}
