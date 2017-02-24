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

    override func draw(_ rect: CGRect) {
        
        categoryImage?.layer.cornerRadius = (categoryImage?.frame.size.width)! / 2
        categoryImage?.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ category: Category) {
        
        self.category = category
        self.categoryTxt.text = category.name
        self.categoryCheckmark.image = nil
        self.categoryImage.image = UIImage(named: category.imagePath)
    }

}
