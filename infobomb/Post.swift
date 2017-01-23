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
    fileprivate var _text: String?
    fileprivate var _type: String!
    fileprivate var _categories: [String]!
    fileprivate var _views: [String]!
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
    fileprivate var _description: String?
    fileprivate var _video: String?
    fileprivate var _audio: String?
    fileprivate var _author: String?
    fileprivate var _quoteType: String?
    fileprivate var _thumbnail: String?
    fileprivate var _shortUrl: String?
    fileprivate var _url: String?
    fileprivate var _active: Bool!
    fileprivate var _timestamp: Double!
    fileprivate var _detonated_at: Double!
    fileprivate var _extension: String?
    fileprivate var _download: String?
    fileprivate var _usersInRadius: Int!
    fileprivate var _viewCount: Int!
    fileprivate var _rating: Double!
    fileprivate var _score: Int!
    fileprivate var _newReceivers: Int!
    fileprivate var _recentInteractions: Int!
    fileprivate var _receivers: NSMutableArray!
    fileprivate var _initial: Bool!
    fileprivate var _lastInteraction: Double!
    
    var message: String? {
        return _message
    }
    
    var text: String? {
        return _text
    }
    
    var image: String? {
        return _image
    }
    
    var video: String? {
        return _video
    }
    
    var ext: String? {
        return _extension
    }
    
    var download: String? {
        return _download
    }
    
    var initial: Bool {
        return _initial
    }
    
    var audio: String? {
        return _audio
    }
    
    var thumbnail: String? {
        return _thumbnail
    }
    
    var viewCount: Int {
        return _viewCount
    }
    
    var views: [String] {
        return _views
    }
    
    var rating: Double {
        return _rating
    }
    
    var lastInteraction: Double {
        return _lastInteraction
    }
    
    var usersInRadius: Int {
        return _usersInRadius
    }
    
    var newReceivers: Int {
        return _newReceivers
    }
    
    var receivers: NSMutableArray {
        return _receivers
    }
    
    var recentInteractions: Int {
        return _recentInteractions
    }
        
    var distance: Int {
        return _distance
    }
    
    var categories: [String]! {
        return _categories
    }
    
    var author: String? {
        return _author
    }
    
    var quoteType: String? {
        return _quoteType
    }
    
    var type: String {
        return _type
    }
    
    var user_id: String {
        return _user_id
    }
    
    var descrip: String? {
        return _description
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
        set { _likes = newValue }
        get { return _likes }
    }
    
    var dislikes: Int {
        set { _dislikes = newValue }
        get { return _dislikes }
    }
    
    var score: Int {
        return _score
    }
    
    var active: Bool {
        return _active
    }
    
    var timestamp: Double {
        return _timestamp
    }
    
    var detonated_at: Double {
        return _detonated_at
    }
    
    var title: String? {
        return _title
    }
    
    var shortUrl: String? {
        return _shortUrl
    }
    
    var url: String? {
        return _url
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
        if let text = dictionary["text"] as? String {
            self._text = text
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
        if let score = dictionary["score"] as? Int {
            self._score = score
        }
        if let newReceivers = dictionary["newReceivers"] as? Int {
            self._newReceivers = newReceivers
        }
        if let receivers = dictionary["receivers"] as? NSMutableArray {
            self._receivers = receivers
        }
        if let recentInteractions = dictionary["recentInteractions"] as? Int {
            self._recentInteractions = recentInteractions
        }
        if let lastInteraction = dictionary["last_interaction"] as? Double {
            self._lastInteraction = lastInteraction
        }
        if let initial = dictionary["init"] as? Bool {
            self._initial = initial
        }
        if let distance = dictionary["distance"] as? Int {
            self._distance = distance
        }
        if let title = dictionary["title"] as? String {
            self._title = title
        }
        if let description = dictionary["description"] as? String {
            self._description = description
        }
        if let shortUrl = dictionary["shortUrl"] as? String {
            self._shortUrl = shortUrl
        }
        if let url = dictionary["url"] as? String {
            self._url = url
        }
        if let author = dictionary["author"] as? String {
            self._author = author
        }
        if let image = dictionary["image"] as? String {
            self._image = image
        }
        if let video = dictionary["video"] as? String {
            self._video = video
        }
        if let ext = dictionary["extension"] as? String {
            self._extension = ext
        }
        if let download = dictionary["download"] as? String {
            self._download = download
        }
        if let audio = dictionary["audio"] as? String {
            self._audio = audio
        }
        if let timestamp = dictionary["created_at"] as? Double {
            self._timestamp = timestamp
        }
        if let detonated_at = dictionary["detonated_at"] as? Double {
            self._detonated_at = detonated_at
        }
        if let quoteType = dictionary["quoteType"] as? String {
            self._quoteType = quoteType
        }
        if let distance = dictionary["distance"] as? Int {
            self._distance = distance
        }
        if let uIR = dictionary["usersInRadius"] as? Int {
            self._usersInRadius = uIR
        }
        if let thumbnail = dictionary["thumbnail"] as? String {
            self._thumbnail = thumbnail
        }
        if let active = dictionary["active"] as? Bool {
            self._active = active
        }
        if let viewCount = dictionary["viewCount"] as? Int {
            self._viewCount = viewCount
        }
        if let rating = dictionary["rating"] as? Double {
            self._rating = rating
        }
        if let viewsDict = dictionary["views"] as? Dictionary<String,AnyObject> {
            
            var views = [String]()
            for(key, _) in viewsDict {
                views.append(key)
            }
            self._views = views
        }
        if let categoryDict = dictionary["categories"] as? Dictionary<String,AnyObject> {
            
            var categoryNames = [String]()
            for(key, _) in categoryDict {
                categoryNames.append(key)
            }
            self._categories = categoryNames
        }
        
        self._postRef = PostService.ds.REF_POSTS.child(self._postKey!)

    }
    
    
}
