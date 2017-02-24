//
//  TimeService.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/10/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation

struct TimeService {
        
    func getTimeStampFromMilliSeconds(millis: Double) -> String {
        
        let date = NSDate()
        let millisecondsDateOfNow = date.timeIntervalSince1970 * 1000
        let milliseconds = millisecondsDateOfNow - Double(millis)
        
        let seconds = Int((milliseconds / 1000).rounded())
        if seconds < 60 {
            return "A second ago"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) min ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours) hr ago"
        }
        let days = hours / 24
        if days == 1 {
            return "\(days) day ago"
        } else if days < 30 {
            return "\(days) days ago"
        }
        let months = days / 30
        if months < 12 {
            return "\(months) mo ago"
        }
        let years = months / 12
        if years == 1 {
            return "\(years) yr ago"
        } else if years > 1 {
            return "\(years) yrs ago"
        }
        return ""
    }
    
    func getSecondsBetweenNowAndPast(millis: Double) -> Int {
        
        let date = NSDate()
        let millisecondsDateOfNow = date.timeIntervalSince1970 * 1000
        let milliseconds = millisecondsDateOfNow - Double(millis)
        let seconds = Int((milliseconds / 1000).rounded())
        
        return seconds
    }
}
