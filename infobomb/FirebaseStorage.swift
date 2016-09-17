//
//  FirebaseStorage.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/9/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//
//
//import Foundation
//import Firebase
//
//
//class FirebaseStorage {
//    
//    let fs = FirebaseStorage()
//    
//    
    // Local file you want to upload
//    let localFile: NSURL = ...
//    // Create the file metadata
//    let metadata = FIRStorageMetadata()
//    metadata.contentType = "image/jpeg"
//    
//    // Upload file and metadata to the object 'images/mountains.jpg'
//    let uploadTask = storageRef.child("images/mountains.jpg").putFile(localFile, metadata: metadata);
//    
//    // Listen for state changes, errors, and completion of the upload.
//    uploadTask.observeStatus(.Pause) { snapshot in
//    // Upload paused
//    }
//    
//    uploadTask.observeStatus(.Resume) { snapshot in
//    // Upload resumed, also fires when the upload starts
//    }
//    
//    uploadTask.observeStatus(.Progress) { snapshot in
//    // Upload reported progress
//    if let progress = snapshot.progress {
//    let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
//    }
//    }
//    
//    uploadTask.observeStatus(.Success) { snapshot in
//    // Upload completed successfully
//    }
//    
//    // Errors only occur in the "Failure" case
//    uploadTask.observeStatus(.Failure) { snapshot in
//    guard let storageError = snapshot.error else { return }
//    guard let errorCode = FIRStorageErrorCode(rawValue: storageError.code) else { return }
//    switch errorCode {
//    case .ObjectNotFound:
//    // File doesn't exist
//    
//    case .Unauthorized:
//    // User doesn't have permission to access file
//    
//    case .Cancelled:
//    // User canceled the upload
//}