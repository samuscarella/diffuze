//
//  Location.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/10/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import CoreLocation

struct Location {
    
    func getDistanceBetweenUserAndPost(_ userLocation: Dictionary<String, AnyObject>, post: Post) -> String {
        
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
        
        return "\(intFinalDistance)mi away"
    }
}
