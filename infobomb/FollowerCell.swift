//
//  FollowerCell.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Alamofire

class FollowerCell: UITableViewCell {

    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var userFollowersLbl: UILabel!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    
    var request: Request?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userPhotoImageView.layer.cornerRadius = userPhotoImageView.bounds.size.height / 2
        userPhotoImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configueCell(user: User, img: UIImage?) {
        self.usernameLbl.text = user.username
        
            if img != nil {
                self.userPhotoImageView.image = img
            } else if let photo = user.userPhoto {
                
                let url = URL(string: photo)!
                self.request = Alamofire.request(url, method: .get).response { response in
                    if response.error == nil {
                        print("\(response.data)")
                        let data = response.data as NSData?
                        let img = UIImage(data: data as! Data)
                        self.userPhotoImageView.image = img
                        FollowersVC.imageCache.setObject(img!, forKey: photo as AnyObject)
                    } else {
                        print("\(response.error)")
                    }
                }
            } else {
                self.userPhotoImageView.image = UIImage(named: "user")
            }
        
        if let followers = user.followers {
            if followers.count == 1 {
                self.userFollowersLbl.text = "\(followers.count) Follower"
            } else {
                self.userFollowersLbl.text = "\(followers.count) Followers"
            }
        } else {
             self.userFollowersLbl.text = "0 Followers"
        }
    }

}
