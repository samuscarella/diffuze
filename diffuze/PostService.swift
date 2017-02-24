//
//  PostService.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/13/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import Firebase

class PostService {
    
    static let ds = PostService()
    
    fileprivate var _REF_BASE = URL_BASE
    fileprivate var _REF_POSTS = URL_BASE.child("posts")
    fileprivate var _REF_ACTIVE_POSTS = URL_BASE.child("active-posts")
    fileprivate var _REF_ACTIVITY_FEED = URL_BASE.child("user-activity-feed")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_POSTS: FIRDatabaseReference {
        return _REF_POSTS
    }
    
    var REF_ACTIVE_POSTS: FIRDatabaseReference {
        return _REF_ACTIVE_POSTS
    }
    
    var REF_ACTIVITY_FEED: FIRDatabaseReference {
        return _REF_ACTIVITY_FEED
    }
    
}
