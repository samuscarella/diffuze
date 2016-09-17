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
    
    private var _REF_BASE = URL_BASE
    private var _REF_CATEGORIES = URL_BASE.child("categories")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_CATEGORIES: FIRDatabaseReference {
        return _REF_CATEGORIES
    }
    
    func createFirebaseCategory(name: String, image: UIImage) {
        
        let categoryImageRef = REF_IMAGES_BUCKET.child("image_\(NSDate.timeIntervalSinceReferenceDate()).png")
        let imgData = UIImagePNGRepresentation(image)
        let localFile = imgData
        // Upload the file to the path "images/rivers.jpg"
        let _ = categoryImageRef.putData(localFile!, metadata: nil) { metadata, error in
            
            if (error != nil) {
                print(error.debugDescription)
            } else {
                print("HERE...")
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL
                
                let category: Dictionary<String, AnyObject> = [
                    "name": name,
                    "image_path": downloadURL()!.absoluteString,
                    "createdAt": FIRServerValue.timestamp(),
                    "updatedAt": FIRServerValue.timestamp()
                ]
                
                //Create new model and pass in object
                let firebaseCategory = CategoryService.ds.REF_CATEGORIES.childByAutoId()
                firebaseCategory.setValue(category)

            }
        }
        
    }
    
}