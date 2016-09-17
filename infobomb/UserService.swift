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
    
        private var _REF_BASE = URL_BASE
        private var _REF_USERS = URL_BASE.child("users")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String
        let user = URL_BASE.child("users").child(uid)
        return user
    }
    
    var currentUserUsername: String {
        let username = NSUserDefaults.standardUserDefaults().valueForKey(KEY_USERNAME) as! String
        return username
    }
    
    var currentUserID: String {
        let userID = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String
        return userID
    }
    
    func createFirebaseUser(uid: String, user: Dictionary<String, String>) {
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