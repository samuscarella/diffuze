//
//  NotificationService.swift
//  infobomb
//
//  Created by Stephen Muscarella on 1/7/17.
//  Copyright © 2017 samuscarella. All rights reserved.
//

import Foundation
import Firebase

class NotificationService: NSObject {
    
    static let ns = NotificationService()
        
    let iD = UserService.ds.currentUserID
    
    var initialRadarSnap = true
    var currentRadarPosts = 0
    var notifications = [NotificationCustom]()
    
    func getNotifications() {
        
        URL_BASE.child("notifications").child(iD).observe(FIRDataEventType.value, with: { snapshot in
            
            let notifications = snapshot.value as? Dictionary<String,AnyObject>
            
            self.notifications = []
            if notifications != nil {
                
                for notif in notifications! {

                    let notificationDict = notif.value as! Dictionary<String,AnyObject>
                    
                    var notification: NotificationCustom
                    
                    if notif.key == "watch" {
                        notification = NotificationCustom(dictionary: notificationDict)
                        if !notification.read {
                            self.notifications.append(notification)
                        }
                    } else {
                        notification = NotificationCustom(notifier: notif.key, dictionary: notificationDict)
                        if notification.status! {
                            self.notifications.append(notification)
                        }
                    }
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "newFollowersNotification"), object: self.notifications)
            print(self.notifications.count)
        })
    }
    
    func watchRadar() {
        
        URL_BASE.child("users").child(iD).child("radar").observe(FIRDataEventType.value, with: {
            snapshot in
            
            if self.initialRadarSnap == true {
                let radarPosts = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
                self.currentRadarPosts = radarPosts.count
                print("Initial Radar Posts: \(self.currentRadarPosts)")
                self.initialRadarSnap = false
                return
            }
            
            let radarPosts = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            if radarPosts.count > self.currentRadarPosts {
                
                let watchObj = [
                    "type": "radar",
                    "read": false,
                    "timestamp": FIRServerValue.timestamp()
                    ] as [String: Any]
                
                URL_BASE.child("notifications").child(self.iD).child("watch").updateChildValues(watchObj)
                self.currentRadarPosts = radarPosts.count
                print("Updated Radar Posts: \(self.currentRadarPosts)")
            }
        })
    }
    
}
