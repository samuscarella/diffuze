//
//  Constants.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import UIKit
import Firebase

/////////////////////////////////Constants

//db
let URL_BASE = FIRDatabase.database().reference()
let storage = FIRStorage.storage()
let storageRef = storage.referenceForURL("gs://infobomb-9b66c.appspot.com")
let REF_IMAGES_BUCKET = storageRef.child("images")
let REF_VIDEO_BUCKET = storageRef.child("video")
let REF_AUDIO_BUCKET = storageRef.child("audio")

//development
let DALLAS_LATITUDE = 32.85477263390352
let DALLAS_LONGITUDE = -96.74635749319265
//Keys
let KEY_UID = "uid"
let KEY_USERNAME = "username"

//Auth Providers
let FACEBOOK = "facebook"
let FIREBASE = "firebase"

//Segues
let SEGUE_LOGGED_IN = "loggedIn"
let SEGUE_NEW_POST = "newPost"
let TEXT_POST_VC = "TextPostVC"

//Status Codes
let USER_NOT_FOUND = 17011
let PASSWORD_NOT_FOUND = 17009

//Colors
let SHADOW_COLOR: CGFloat = 157.0 / 255.0
let CRIMSON: UIColor = UIColor(red: 230.0 / 255.0, green: 0.0, blue: 0.0, alpha: 1)
let AUBURN_RED: UIColor = UIColor(red: 140.0 / 255.0, green: 39.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
let LIGHT_GREY: UIColor = UIColor(red: 211.0 / 255.0, green: 208.0 / 255.0, blue: 203.0 / 255.0, alpha: 1)
let ANTI_FLASH_WHITE: UIColor = UIColor(red: 234.0 / 255.0, green: 242.0 / 255.0, blue: 239.0 / 255.0, alpha: 1)
let SMOKY_BLACK: UIColor = UIColor(red: 10.0 / 255.0, green: 9.0 / 255.0, blue: 8.0 / 255.0, alpha: 1)
