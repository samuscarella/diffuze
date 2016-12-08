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

//DB
let URL_BASE = FIRDatabase.database().reference()
let storage = FIRStorage.storage()
let storageRef = storage.reference(forURL: "gs://infobomb-9b66c.appspot.com")
let REF_IMAGES_BUCKET = storageRef.child("images")
let REF_VIDEO_BUCKET = storageRef.child("video")
let REF_AUDIO_BUCKET = storageRef.child("audio")

//Development

let INITIAL_USERS = 100

let DALLAS_LATITUDE = 32.7767
let DALLAS_LONGITUDE = 96.7970

let AUSTIN_LATITUDE = 30.2672
let AUSTIN_LONGITUDE = 97.7431

let TULSA_LATITUDE = 36.1540
let TULSA_LONGITUDE = 95.9928

let MEMPHIS_LATITUDE = 35.1495
let MEMPHIS_LONGITUDE = 90.0490

let DENVER_LATITUDE = 39.7392
let DENVER_LONGITUDE = 104.9903

let DETROIT_LATITUDE = 42.3314
let DETROIT_LONGITUDE = 83.0458

let ALBUQUERQUE_LATITUDE = 35.0853
let ALBUQUERQUE_LONGITUDE = 106.6056

let CINCINNATI_LATITUDE = 39.1031
let CINCINNATI_LONGITUDE = 84.5120

let PHEONIX_LATITUDE = 33.4484
let PHEONIX_LONGITUDE = 112.0740

let LOS_ANGELES_LATITUDE = 34.0522
let LOS_ANGELES_LONGITUDE = 118.2437

let SAN_FRANCISCO_LATITUDE = 37.7749
let SAN_FRANCISCO_LONGITUDE = 122.4194

let PLACEHOLDER_TEXT = "Enter Text..."

//Post Constraints
let POST_IMAGE_HEIGHT: CGFloat = 180
let POST_LINK_URL_HEIGHT: CGFloat = 20
let POST_MESSAGE_HORIZONTAL_MARGINS: CGFloat = 8
let POST_MESSAGE_TOP_MARGIN: CGFloat = 3

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
let BOMB_VC = "BombVC"

//Status Codes
let USER_NOT_FOUND = 17011
let PASSWORD_NOT_FOUND = 17009

//Colors
let BABY_BLUE: UIColor = UIColor(red: 82.0 / 255.0, green: 178.0 / 255.0, blue: 207.0 / 255.0, alpha: 1)
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
