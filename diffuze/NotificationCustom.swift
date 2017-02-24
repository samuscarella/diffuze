//
//  Notification.swift
//  infobomb
//
//  Created by Stephen Muscarella on 1/7/17.
//  Copyright © 2017 samuscarella. All rights reserved.
//

import Foundation

class NotificationCustom {
    
    fileprivate var _notifier: String?
    fileprivate var _username: String?
    fileprivate var _type: String!
    fileprivate var _read: Bool!
    fileprivate var _status: Bool?
    fileprivate var _timestamp: Int!
    
    var notifier: String? {
        return _notifier
    }
    
    var username: String? {
        return _username
    }
    
    var read: Bool {
        return _read
    }
    
    var status: Bool? {
        return _status
    }
    
    var timestamp: Int {
        return _timestamp
    }
    
    var type: String! {
        return _type
    }
    
    init(notifier: String, dictionary: Dictionary<String,AnyObject>) {
     
        self._notifier = notifier
        
        if let username = dictionary["username"] as? String {
            self._username = username
        }
        if let read = dictionary["read"] as? Bool {
            self._read = read
        }
        if let type = dictionary["type"] as? String {
            self._type = type
        }
        if let status = dictionary["status"] as? Bool {
            self._status = status
        }
        if let timestamp = dictionary["timestamp"] as? Int {
            self._timestamp = timestamp
        }
    }
    
    init(dictionary: Dictionary<String,AnyObject>) {
        
        if let timestamp = dictionary["timestamp"] as? Int {
            self._timestamp = timestamp
        }
        if let type = dictionary["type"] as? String {
            self._type = type
        }
        if let read = dictionary["read"] as? Bool {
            self._read = read
        }
    }
}
