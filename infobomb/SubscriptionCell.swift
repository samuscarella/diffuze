//
//  SubscriptionCell.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/7/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Alamofire
import Firebase

class SubscriptionCell: UITableViewCell {

    @IBOutlet weak var subscriptionImage: UIImageView!
    @IBOutlet weak var subscriptionTxt: UILabel!
    @IBOutlet weak var subscriptionSwitch: UISwitch!
    
    let subscriptionRef = UserService.ds.REF_USER_CURRENT.child("subscriptions")

    var category: Category!
    var request: Request?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func drawRect(rect: CGRect) {
        
        subscriptionImage.layer.cornerRadius = subscriptionImage.frame.size.width / 2
        subscriptionImage.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(category: Category, img: UIImage?) {
        
        self.category = category
        self.subscriptionTxt.text = category.name
        
//        subscriptionRef = UserService.ds.REF_USER_CURRENT.child("subscriptions").child(category.name)
        
        if img != nil {
            self.subscriptionImage.image = img
        } else {

            request = Alamofire.request(.GET, category.image_path!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, err in
            
                if err == nil {
                    let img = UIImage(data: data!)!
                    self.subscriptionImage.image = img
                    SubscriptionsVC.imageCache.setObject(img, forKey: self.category.image_path!)
                }
            })
        }
        
        subscriptionRef.child(category.name).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            if let doesNotExist = snapshot.value as? NSNull {
                self.subscriptionSwitch.on = false
            } else {
                self.subscriptionSwitch.on = true
            }
        })
        
        subscriptionSwitch.addTarget(self, action: #selector(SubscriptionCell.subscribeSwitchPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    
    func subscribeSwitchPressed(sender: UISwitch) {
        
        let subscriberRef = CategoryService.ds.REF_CATEGORIES.child(category.categoryKey).child("subscribers")
        let username = UserService.ds.currentUserUsername
        
        subscriptionRef.child(category.name).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            if let doesNotExist = snapshot.value as? NSNull {
                
                let subscription = [
                    self.category.name: true
                ]
                let subscriber = [
                    username: true
                ]
                self.subscriptionRef.updateChildValues(subscription)
                subscriberRef.updateChildValues(subscriber)
            } else {
                self.subscriptionRef.child(self.category.name).removeValue()
                subscriberRef.child(username).removeValue()
            }
        })
        
    }
    

    
    
}
