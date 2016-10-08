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
    
    fileprivate var _email: String!
    fileprivate var _username: String!
    fileprivate var _subscriptions: [Category]?
    
    var email: String {
        return _email
    }
    
    var username: String {
        return _username
    }
    
    var subscriptions: [Category]? {
        return _subscriptions
    }
    
    init(email: String, username: String) {
        self._email = email
        self._username = username
    }
    
    
}
