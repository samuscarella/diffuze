//
//  MaterialImgView.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/3/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class MaterialImgView: UIImageView {

    override func awakeFromNib() {
        
        layer.cornerRadius = 2.0
        layer.shadowColor = UIColor(red: 0.0 / 255.0, green: 0.0 / 255.0, blue: 0.0 / 255.0, alpha: 0.5).cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 5.0
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
    }

}
