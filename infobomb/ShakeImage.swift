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
        animation.fromValue = NSValue(CGPoint: CGPointMake(self.center.x - 10, self.center.y))
        animation.toValue = NSValue(CGPoint: CGPointMake(self.center.x + 10, self.center.y))
        self.layer.addAnimation(animation, forKey: "position")
    }
    


}
