//
//  TransparentPasswordField.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class TransparentPasswordField: UITextField {

    override func awakeFromNib() {
        
        makeTextFieldBottomBorderOnly()
    }
    
    //For placeholder
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        
        return CGRectInset(bounds, 5, 0)
    }
    
    //For editable text
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 5, 0)
    }
    
    func makeTextFieldBottomBorderOnly() {
        
        let bottomLine = CALayer()
        bottomLine.frame = CGRectMake(0.0, frame.height - 1, frame.width, 1.0)
        bottomLine.backgroundColor = UIColor.whiteColor().CGColor
        borderStyle = UITextBorderStyle.None
        layer.addSublayer(bottomLine)
        attributedPlaceholder = NSAttributedString(string: "Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
    }

}
