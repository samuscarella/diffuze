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
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
            currentLocation = locations.last! as CLLocation
    
            let longRef = UserService.ds.REF_USER_CURRENT.child("longitude")
            let latRef = UserService.ds.REF_USER_CURRENT.child("latitude")
    
            longRef.setValue(currentLocation!.coordinate.longitude)
            latRef.setValue(currentLocation!.coordinate.latitude)
        
            latitude = Double(currentLocation.coordinate.latitude)
            longitude = Double(currentLocation.coordinate.longitude)
        
            NSNotificationCenter.defaultCenter().postNotificationName("userUpdatedLocation", object: nil)
    }

    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("ERROR GETTING LOCATION. IS DEVICE PLUGGED IN?")
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
            print("Access Always")
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


    func getDistanceBetweenUserAndPost(userLocation: CLLocation, post: Post) -> Int {
        
        let postLatitude = post.latitude
        let postLongitude = post.longitude
        let postLocation = CLLocation(latitude: postLatitude, longitude: postLongitude)
        let meters = userLocation.distanceFromLocation(postLocation)
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