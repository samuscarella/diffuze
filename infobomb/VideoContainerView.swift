//
//  VideoContainerView.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/8/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class VideoContainerView: UIView {

    var playerLayer: CALayer?
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        playerLayer?.frame = self.bounds
    }
}
