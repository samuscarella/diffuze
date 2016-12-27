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



    @IBOutlet weak var categoryImage: UIImageView?
    @IBOutlet weak var categoryTxt: UILabel!
    @IBOutlet weak var categoryCheckmark: UIImageView!
    
    var category: Category!
    var request: Request?
    var checked: [[String:String]] = []

    override func draw(_ rect: CGRect) {
        
        categoryImage?.layer.cornerRadius = (categoryImage?.frame.size.width)! / 2
        categoryImage?.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ category: Category, img: UIImage?) {
        
        self.category = category
        self.categoryTxt.text = category.name
        self.categoryCheckmark.image = nil
        
        //subscriptionRef = UserService.ds.REF_USER_CURRENT.child("subscriptions").child(category.name)
        
        if img != nil {
            self.categoryImage?.image = img
        } else {
            
            request = Alamofire.request(category.image_path!).validate(contentType: ["image/*"]).response { response in
                
                if response.error == nil {
                    let img = UIImage(data: response.data!)!
                    self.categoryImage?.image = img
                    SubscriptionsVC.imageCache.setObject(img, forKey: self.category.image_path! as AnyObject)
                }
            }
        }
    }

}
