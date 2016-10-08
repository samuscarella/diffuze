//
//  Category.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/7/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import Firebase

class Category {
    
    fileprivate var _categoryKey: String!
    fileprivate var _name: String!
    fileprivate var _image_path: String?
    fileprivate var _categoryRef: FIRDatabaseReference!
    
    var categoryKey: String {
        return _categoryKey
    }
    
    var name: String {
        return _name
    }
    
    var image_path: String? {
        return _image_path
    }
    
    var categoryRef: FIRDatabaseReference {
        return _categoryRef
    }
    
    init(name: String, img: String) {
        self._name = name
        self._image_path = img
    }
    
    init(categoryKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._categoryKey = categoryKey
        
        if let name = dictionary["name"] as? String {
            self._name = name
        }
        
        if let img = dictionary["image_path"] as? String {
            self._image_path = img
        }
        
        self._categoryRef = CategoryService.ds.REF_CATEGORIES.child(self._categoryKey!)
    }
    
}
