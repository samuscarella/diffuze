//
//  UserService.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import Firebase

class UserService {
    
    static let ds = UserService()
    
    fileprivate var _REF_BASE = URL_BASE
    fileprivate var _REF_USERS = URL_BASE.child("users")
    fileprivate var _REF_USER_LOCATIONS = URL_BASE.child("user-locations")
    fileprivate var _REF_USER_POSTS = URL_BASE.child("user-posts")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_USER_LOCATIONS: FIRDatabaseReference {
        return _REF_USER_LOCATIONS
    }
    
    var REF_USER_POSTS: FIRDatabaseReference {
        return _REF_USER_POSTS
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference? {
        let uid = UserDefaults.standard.value(forKey: KEY_UID) as? String ?? ""
        var user: FIRDatabaseReference?
        if uid != "" {
            user = URL_BASE.child("users").child(uid)
        }
        return user
    }
    
    var currentUserUsername: String {
        let username = UserDefaults.standard.value(forKey: KEY_USERNAME) as! String
        return username
    }
    
    var currentUserID: String {
        let userID = UserDefaults.standard.value(forKey: KEY_UID) as! String
        return userID
    }
    
    func createFirebaseUser(_ uid: String, user: Dictionary<String, Any>) {
        REF_USERS.child(uid).updateChildValues(user)
    }
    
//    func getCurrentUserEmail() -> String {
//        
//        var email: String!
//        let userID = FIRAuth.auth()?.currentUser?.uid
//        let userRef = UserService.ds.REF_USERS.child(userID!)
//        
//        print(userID)
//        
//        userRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//            
//            email = snapshot.value!["email"] as! String
//            
//        }) { (error) in
//            print(error.localizedDescription)
//        }
//        return email!
//    }
    
}
