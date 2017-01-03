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
    
    let subscriptionRef = UserService.ds.REF_USER_CURRENT?.child("subscriptions")

    var category: Category!
    var request: Request?
    var subscribedToAll: Bool!
    var isSubscribed = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func draw(_ rect: CGRect) {
        
        subscriptionImage.layer.cornerRadius = subscriptionImage.frame.size.width / 2
        subscriptionImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(_ category: Category,_ subscribedToAll: Bool) {
        
        self.category = category
        self.subscriptionTxt.text = category.name
        self.subscriptionImage.image = UIImage(named: category.imagePath)
        self.subscribedToAll = subscribedToAll
        
        if subscribedToAll {
            self.subscriptionSwitch.isOn = true
        } else {
            subscriptionRef?.child(category.name).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let doesNotExist = snapshot.value as? NSNull {
                    self.subscriptionSwitch.isOn = false
                    self.isSubscribed = false
                } else {
                    self.subscriptionSwitch.isOn = true
                    self.isSubscribed = true
                }
            })
        }
        
        subscriptionSwitch.addTarget(self, action: #selector(SubscriptionCell.subscribeSwitchPressed(_:)), for: UIControlEvents.touchUpInside)
    }
    
    
    func subscribeSwitchPressed(_ sender: UISwitch) {
        
        subscriptionRef?.child(category.name).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let doesNotExist = snapshot.value as? NSNull {
                
                if self.category.name == "All" {
                    
                    self.subscriptionRef?.removeValue()
                    self.subscriptionRef?.updateChildValues(["All":true])
                    
                } else {
                    self.isSubscribed = true
                    let subscription = [
                        self.category.name: true
                    ]
                    self.subscriptionRef?.updateChildValues(subscription)
                    self.subscriptionRef?.child("All").removeValue()
                }
            } else {
                self.isSubscribed = false
                self.subscriptionRef?.child(self.category.name).removeValue()
            }
        })
        
    }
    

    
    
}
