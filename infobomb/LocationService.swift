//
//  LocationService.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/15/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import CoreLocation
import FirebaseAuth

class LocationService: NSObject, CLLocationManagerDelegate {
    
    static let ls = LocationService()
    
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    
    func startTracking() {
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        currentLocation = locations.last! as CLLocation
        
        latitude = Double(currentLocation.coordinate.latitude)
        longitude = Double(currentLocation.coordinate.longitude)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "userUpdatedLocation"), object: nil)
    }

    
    func stopUpdatingLocation() {
        locationManager?.stopUpdatingLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR GETTING LOCATION. IS DEVICE PLUGGED IN?")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            print("Access NotDetermined")
            break
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            print("Access WhenInUse")
            break
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            print("Access Always")
            break
        case .restricted:
            print("Access Restricted")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
            break
        case .denied:
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)
            print("Access Denied")
            break
        }
    }
}
