//
//  Post.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/17/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import Firebase

class Post {
    
    fileprivate var _message: String?
    fileprivate var _type: String!
    fileprivate var _categories: [String]!
    fileprivate var _postKey: String!
    fileprivate var _postRef: FIRDatabaseReference!
    fileprivate var _user_id: String!
    fileprivate var _username: String!
    fileprivate var _shares: Int!
    fileprivate var _longitude: Double!
    fileprivate var _latitude: Double!
    fileprivate var _likes: Int!
    fileprivate var _dislikes: Int!
    fileprivate var _distance: Int!
    fileprivate var _title: String?
    fileprivate var _image: String?
    fileprivate var _video: String?
    fileprivate var _thumbnail: String?
    fileprivate var _shortUrl: String?

    
    var message: String? {
        return _message
    }
    
    var image: String? {
        return _image
    }
    
    var video: String? {
        return _video
    }
    
    var thumbnail: String? {
        return _thumbnail
    }
    
    var categories: [String]! {
        return _categories
    }
    
    var type: String {
        return _type
    }
    
    var user_id: String {
        return _user_id
    }
    
    var username: String {
        return _username
    }
    
    var shares: Int {
        return _shares
    }

    var longitude: Double {
        return _longitude
    }
    
    var latitude: Double {
        return _latitude
    }
    
    var likes: Int {
        return _likes
    }
    
    var dislikes: Int {
        return _dislikes
    }
    
    var distance: Int {
        return _distance
    }
    
    var title: String? {
        return _title
    }
    
    var shortUrl: String? {
        return _shortUrl
    }
    
    var postKey: String {
        return _postKey
    }
    
    var postRef: FIRDatabaseReference {
        return _postRef
    }
    
    init(postKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        
        if let message = dictionary["message"] as? String {
            self._message = message
        }
        if let type = dictionary["type"] as? String {
            self._type = type
        }
        if let user = dictionary["user_id"] as? String {
            self._user_id = user
        }
        if let username = dictionary["username"] as? String {
            self._username = username
        }
        if let shares = dictionary["shares"] as? Int {
            self._shares = shares
        }
        if let longitude = dictionary["longitude"] as? Double {
            self._longitude = longitude
        }
        if let latitude = dictionary["latitude"] as? Double {
            self._latitude = latitude
        }
        if let likes = dictionary["likes"] as? Int {
            self._likes = likes
        }
        if let dislikes = dictionary["dislikes"] as? Int {
            self._dislikes = dislikes
        }
        if let distance = dictionary["distance"] as? Int {
            self._distance = distance
        }
        if let title = dictionary["title"] as? String {
            self._title = title
        }
        if let shortUrl = dictionary["shortUrl"] as? String {
            self._shortUrl = shortUrl
        }
        if let image = dictionary["image"] as? String {
            self._image = image
        }
        if let video = dictionary["video"] as? String {
            self._video = video
        }
        if let thumbnail = dictionary["thumbnail"] as? String {
            self._thumbnail = thumbnail
        }
        if let categoryArray = dictionary["categories"] as? NSArray {
            
            var categoryNames = [String]()
            for cat in categoryArray {
                let categoryObj = cat as! Dictionary<String, AnyObject>
                for(key, _) in categoryObj {
                    categoryNames.append(key)
                }
            }
            self._categories = categoryNames
        }
        
        self._postRef = PostService.ds.REF_POSTS.child(self._postKey!)

    }
    
    
}
