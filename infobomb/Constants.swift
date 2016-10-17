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
let storageRef = storage.reference(forURL: "gs://infobomb-9b66c.appspot.com")
let REF_IMAGES_BUCKET = storageRef.child("images")
let REF_VIDEO_BUCKET = storageRef.child("video")
let REF_AUDIO_BUCKET = storageRef.child("audio")

//development
let DALLAS_LATITUDE = 32.85477263390352
let DALLAS_LONGITUDE = -96.74635749319265
let PLACEHOLDER_TEXT = "Enter Text..."

//Scroll View
let FLT_MAX = 1000

//Keys
let KEY_UID = "uid"
let KEY_USERNAME = "username"

//Auth Providers
let FACEBOOK = "facebook"
let FIREBASE = "firebase"
let CLOUDINARY_URL = "cloudinary://466524748444115:RSAd9YoIfC3A8AZED33PJQhfbac@infobomb"

//Segues
let SEGUE_LOGGED_IN = "loggedIn"
let SEGUE_NEW_POST = "newPost"
let TEXT_POST_VC = "TextPostVC"
let LINK_POST_VC = "LinkPostVC"
let VIDEO_POST_VC = "VideoPostVC"
let AUDIO_POST_VC = "AudioPostVC"
let IMAGE_POST_VC = "ImagePostVC"
let NEW_IMAGE_POST = "newImagePost"
let NEW_VIDEO_POST = "newVideoPost"
let QUOTE_POST_VC = "QuotePostVC"

//Status Codes
let USER_NOT_FOUND = 17011
let PASSWORD_NOT_FOUND = 17009

//Colors
let RED: UIColor = UIColor(red: 255.0, green: 0, blue: 0, alpha: 1)
let SHADOW_COLOR: CGFloat = 157.0 / 255.0
let CRIMSON: UIColor = UIColor(red: 230.0 / 255.0, green: 0.0, blue: 0.0, alpha: 1)
let GOLDEN_YELLOW: UIColor = UIColor(red: 232.0 / 255.0, green: 197.0 / 255.0, blue: 71.0 / 255.0, alpha: 1)
let OCEAN_BLUE = UIColor(red: 25.0 / 255.0, green: 100.0 / 255.0, blue: 126.0 / 255.0, alpha: 1)
let POWDER_BLUE = UIColor(red: 143.0 / 255.0, green: 191.0 / 255.0, blue: 224.0 / 255.0, alpha: 1)
let PURPLE = UIColor(red: 107.0 / 255.0, green: 78.0 / 255.0, blue: 113.0 / 255.0, alpha: 1)
let DARK_GREY: UIColor = UIColor(red: 85.0 / 255.0, green: 85.0 / 255.0, blue: 85.0 / 255.0, alpha: 1)
let SUPER_DARK_GREY: UIColor = UIColor(colorLiteralRed: 46.0, green: 46.0, blue: 46.0, alpha: 1)
let DARK_GREEN: UIColor = UIColor(red: 101.0 / 255.0, green: 145.0 / 255.0, blue: 87.0 / 255.0, alpha: 1)
let AUBURN_RED: UIColor = UIColor(red: 140.0 / 255.0, green: 39.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
let FIRE_ORANGE: UIColor = UIColor(red: 255.0 / 255.0, green: 126.0 / 255.0, blue: 0.0 / 255.0, alpha: 1)
let LIGHT_GREY: UIColor = UIColor(red: 211.0 / 255.0, green: 208.0 / 255.0, blue: 203.0 / 255.0, alpha: 1)
let ANTI_FLASH_WHITE: UIColor = UIColor(red: 234.0 / 255.0, green: 242.0 / 255.0, blue: 239.0 / 255.0, alpha: 1)
let SMOKY_BLACK: UIColor = UIColor(red: 10.0 / 255.0, green: 9.0 / 255.0, blue: 8.0 / 255.0, alpha: 1)
