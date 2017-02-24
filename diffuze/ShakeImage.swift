//
//  ShakeImage.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/25/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class ShakeImage: UIImageView {

    override func awakeFromNib() {
        shake()
    }
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
    


}
