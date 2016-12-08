//
//  User.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/10/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import Firebase

class User {
    
    fileprivate var _userID: String?
    fileprivate var _userPhoto: String?
    fileprivate var _email: String!
    fileprivate var _username: String!
    fileprivate var _subscriptions: [Category]?
    fileprivate var _followers: [String]?
    
    var userID: String? {
        return _userID
    }
    
    var email: String {
        return _email
    }
    
    var followers: [String]? {
        return _followers
    }
    
    var username: String {
        return _username
    }
    
    var userPhoto: String? {
        return _userPhoto
    }
    
    var subscriptions: [Category]? {
        return _subscriptions
    }
    
    init(email: String, username: String) {
        self._email = email
        self._username = username
    }
    
    init(userId: String, dictionary: Dictionary<String,AnyObject>) {
        self._userID = userId
        
        if let username = dictionary["username"] as? String {
            self._username = username
        }
        
        if let userPhoto = dictionary["photo"] as? String {
            self._userPhoto = userPhoto
        }
        
        if let followers = dictionary["followers"] as? Dictionary<String,AnyObject> {
            
            var followersArray = [String]()
            for follower in followers {
                let key = follower.key
                followersArray.append(key)
            }
            self._followers = followersArray
        }
    }

}
