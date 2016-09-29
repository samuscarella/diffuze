
//
//  PostCell.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/18/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import CoreLocation

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var postTypeView: UIView!
    @IBOutlet weak var postTypeImg: UIImageView!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var distanceAway: UILabel!
    @IBOutlet weak var postImg: UIImageView!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var postScore: UILabel!
    @IBOutlet weak var followPosterImg: UIImageView!
    @IBOutlet weak var sharePostImg: UIImageView!
    @IBOutlet weak var playAudioBtn: UIButton!
    @IBOutlet weak var visitSiteBtn: UIButton!
    
    @IBOutlet weak var postMessageTopConstraint: NSLayoutConstraint!
    
    var post: Post!
//    var request: Request?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
//        showcaseImg.clipsToBounds = true
    }
    
    func configureCell(post: Post, currentLocation: Dictionary<String, AnyObject>?) {

        self.post = post
        self.username.text = post.username
        
        if post.type == "text" {
            
            let img = UIImage(named: "font-large")
            let imgView = UIImageView(image: img)
            let score = post.likes + post.dislikes

            
            self.postTypeImg = imgView
            self.postTypeView.backgroundColor = AUBURN_RED
            self.message.text = post.message
            self.postScore.text = String(score)
            
            self.postImg.hidden = true
            self.playAudioBtn.hidden = true
            self.visitSiteBtn.hidden = true
//            self.postMessageTopConstraint.
            self.postMessageTopConstraint.constant = -200
            
            if (currentLocation != nil) {
                let distance = LocationService.ls.getDistanceBetweenUserAndPost(currentLocation!, post: post)
                self.distanceAway.text = "\(distance)mi away"
            } else {
                self.distanceAway.text = " "
            }
            
        } else if post.type == "link" {
            
        } else if post.type == "image" {
            
        } else if post.type == "video" {
            
        } else if post.type == "audio" {
            
        } else if post.type == "premium" {
            
        }
        
    }
    


}
