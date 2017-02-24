//
//  CategoryService.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/8/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import Firebase

class CategoryService {
    
    static let ds = CategoryService()
    
    fileprivate var _REF_BASE = URL_BASE
    fileprivate var _REF_CATEGORIES = URL_BASE.child("categories")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_CATEGORIES: FIRDatabaseReference {
        return _REF_CATEGORIES
    }
    
    func createFirebaseCategory(_ name: String, image: UIImage) {
        
        let categoryImageRef = REF_IMAGES_BUCKET.child("image_\(Date.timeIntervalSinceReferenceDate).png")
        let imgData = UIImagePNGRepresentation(image)
        let localFile = imgData
        // Upload the file to the path "images/rivers.jpg"
        let _ = categoryImageRef.put(localFile!, metadata: nil) { metadata, error in
            
            if (error != nil) {
                print(error.debugDescription)
            } else {
                print("HERE...")
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL
                
                let category: Dictionary<String, AnyObject> = [
                    "name": name as AnyObject,
                    "image_path": downloadURL()!.absoluteString as AnyObject,
                    "createdAt": FIRServerValue.timestamp() as AnyObject,
                    "updatedAt": FIRServerValue.timestamp() as AnyObject
                ]
                
                //Create new model and pass in object
                let firebaseCategory = CategoryService.ds.REF_CATEGORIES.childByAutoId()
                firebaseCategory.setValue(category)

            }
        }
        
    }
    
}
