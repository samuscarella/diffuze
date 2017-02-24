//
//  PostTextView.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/18/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class PostTextView: UITextView {

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
    
    override func awakeFromNib() {
        self.scrollRangeToVisible(NSMakeRange(0, 0))
    }
}
