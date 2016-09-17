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
    
    private var _REF_BASE = URL_BASE
    private var _REF_POSTS = URL_BASE.child("posts")
    private var _REF_ACTIVE_POSTS = URL_BASE.child("active-posts")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_POSTS: FIRDatabaseReference {
        return _REF_POSTS
    }
    
    var REF_ACTIVE_POSTS: FIRDatabaseReference {
        return _REF_ACTIVE_POSTS
    }
    
}
