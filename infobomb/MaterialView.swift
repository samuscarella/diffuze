//
//  MaterialView.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/9/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class MaterialView: UITableView {
    
    override func awakeFromNib() {
        
        layer.cornerRadius = 2.0
        layer.shadowColor = UIColor(red: 0.0 / 255.0, green: 0.0 / 255.0, blue: 0.0 / 255.0, alpha: 0.5).CGColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 5.0
        layer.shadowOffset = CGSizeMake(0.0, 2.0)
        
    }
    
}
