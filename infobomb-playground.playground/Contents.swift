//: Playground - noun: a place where people can play

import UIKit
import CoreLocation

let DALLAS_LATITUDE = 32.85477263390352
let DALLAS_LONGITUDE = -96.74635749319265

let PHEONIX_LATITUDE = 33.4484
let PHEONIX_LONGITUDE = -112.074

let ALBUQUERQUE_LATITUDE = 35.0853
let ALBUQUERQUE_LONGITUDE = -106.6056

let city1 = CLLocation(latitude: DALLAS_LATITUDE, longitude: DALLAS_LONGITUDE)
let city2 = CLLocation(latitude: PHEONIX_LATITUDE, longitude: PHEONIX_LONGITUDE)

let meters = city1.distanceFromLocation(city2)
print(meters)

//6IUJWkbAM9OgkfPXXMPlMj8KNzq1 = san francisco
//BbTNVNPIHhM8ozBJ9uGK7CCpn203 = pheonix
//Ep3bBnHHISNqlYatUG2wc2wimhB3 = albuquerque
//S3gysL2mx4ckXEftgAfXGTtqlhq1 = tulsa
//TQO01fB2mpUHwawivLSlngbxRsC2 = little rock
//Tx7BITCQAehotxVw4G4sgbpVqly1 = nashville
