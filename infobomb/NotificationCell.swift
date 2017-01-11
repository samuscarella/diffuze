//
//  NotificationCell.swift
//  infobomb
//
//  Created by Stephen Muscarella on 1/7/17.
//  Copyright © 2017 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class NotificationCell: UITableViewCell {

    @IBOutlet weak var notificationImageView: UIImageView!
    @IBOutlet weak var notificationLbl: UILabel!
    @IBOutlet weak var dotView: UIView!
    
    
    
    let currentUserID = UserService.ds.currentUserID
    
    var lineView: UIView!
    var request: Request?
    var type: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        notificationImageView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        
        notificationImageView.layer.cornerRadius = notificationImageView.frame.size.height / 2
        notificationImageView.clipsToBounds = true

        lineView = UIView(frame: CGRect(x: 0.0, y: self.frame.size.height - 1, width: self.frame.size.width, height: 1.0))
        lineView.backgroundColor = UIColor.lightGray
        self.addSubview(lineView)
        
        dotView.frame = CGRect(x: 0, y: 0, width: 9, height: 9)
        dotView.layer.cornerRadius = dotView.frame.size.height / 2
    }

    func configureCell(notification: NotificationCustom) {
        
        self.type = notification.type
        
        if notification.type == "follower" {
            
            URL_BASE.child("users").child(notification.notifier!).child("photo").observeSingleEvent(of: FIRDataEventType.value, with: {
                snapshot in
                
                let userPhoto = snapshot.value as? String ?? ""
                
                if let photoCheck = NotificationVC.imageCache.object(forKey: userPhoto as AnyObject) as? UIImage {
                    self.notificationImageView.image = photoCheck
                } else if userPhoto != "" {
                    self.getImageFromServer(urlString: userPhoto)
                }
            })

            let string = "\(notification.username!) is now following you" as NSString
            
            let attributedString = NSMutableAttributedString(string: string as String, attributes: [NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
            
            let boldFontAttribute = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0)]
            
            attributedString.addAttributes(boldFontAttribute, range: string.range(of: notification.username!))
            
            self.notificationLbl.attributedText = attributedString
            
            if notification.read == false {
                
                dotView.isHidden = false
                URL_BASE.child("notifications").child(currentUserID).child(notification.notifier!).child("read").setValue(true)
            } else {
                dotView.isHidden = true
            }
        } else if notification.type == "radar" {
            
            self.notificationImageView.image = UIImage(named: "radar-big")
            self.notificationLbl.text = "You have new posts in your radar!"
        }
        
    }
    
    func getImageFromServer(urlString: String) {
        
        let url = URL(string: urlString)!
        Alamofire.request(url, method: .get).response { response in
            if response.error == nil {
                
                let img = UIImage(data: response.data!)
                self.notificationImageView.image = img
                NotificationVC.imageCache.setObject(img!, forKey: urlString as AnyObject)
            } else {
                print("\(response.error)")
            }
        }
    }
}
