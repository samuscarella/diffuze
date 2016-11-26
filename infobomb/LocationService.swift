//
//  LocationService.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/15/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import CoreLocation

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
    
            let longRef = UserService.ds.REF_USER_CURRENT.child("longitude")
            let latRef = UserService.ds.REF_USER_CURRENT.child("latitude")
    
            longRef.setValue(currentLocation!.coordinate.longitude)
            latRef.setValue(currentLocation!.coordinate.latitude)
        
            latitude = Double(currentLocation.coordinate.latitude)
            longitude = Double(currentLocation.coordinate.longitude)
        
            NotificationCenter.default.post(name: Notification.Name(rawValue: "userUpdatedLocation"), object: nil)
    }

    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
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
            // restricted by e.g. parental controls. User can't enable Location Services
            print("Access Restricted")
            break
        case .denied:
            // user denied your app access to Location Services, but can grant access from Settings.app
            locationManager.requestWhenInUseAuthorization()
            print("Access Denied")
            break
        }
    }


    func getDistanceBetweenUserAndPost(_ userLocation: Dictionary<String, AnyObject>, post: Post) -> Int {
        
        let postLocation = CLLocation(latitude: post.latitude, longitude: post.longitude)
        let userLoc = CLLocation(latitude: Double(userLocation["latitude"]! as! NSNumber), longitude: Double(userLocation["longitude"]! as! NSNumber))
        
        let meters = userLoc.distance(from: postLocation)
        let miles = meters * 0.000621371
        
        var finalDistance: Double
        
        if miles < 1 {
            finalDistance = 1
        } else {
            finalDistance = round(miles)
        }
        let intFinalDistance = Int(finalDistance)
        
        return intFinalDistance
    }
}
