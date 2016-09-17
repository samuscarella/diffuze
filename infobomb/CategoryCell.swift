//
//  CategoryCell.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/11/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class CategoryCell: UITableViewCell {



    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryTxt: UILabel!
    @IBOutlet weak var categoryCheckmark: UIImageView!
    
    var category: Category!
    var request: Request?
    var checked: [[String:String]] = []

    override func drawRect(rect: CGRect) {
        
        categoryImage.layer.cornerRadius = categoryImage.frame.size.width / 2
        categoryImage.clipsToBounds = true
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(category: Category, img: UIImage?) {
        
        self.category = category
        self.categoryTxt.text = category.name
        self.categoryCheckmark.hidden = true
        
        //subscriptionRef = UserService.ds.REF_USER_CURRENT.child("subscriptions").child(category.name)
        
        if img != nil {
            self.categoryImage.image = img
        } else {
            
            request = Alamofire.request(.GET, category.image_path!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, err in
                
                if err == nil {
                    let img = UIImage(data: data!)!
                    self.categoryImage.image = img
                    SubscriptionsVC.imageCache.setObject(img, forKey: self.category.image_path!)
                }
            })
        }
        
//        subscriptionRef.child(category.name).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//            
//            if let doesNotExist = snapshot.value as? NSNull {
//                self.subscriptionSwitch.on = false
//            } else {
//                self.subscriptionSwitch.on = true
//            }
//        })
//        
//        categorySwitch.addTarget(self, action: #selector(SubscriptionCell.categorySwitchPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    

}
