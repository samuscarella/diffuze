//
//  TransparentTextField.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/5/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class TransparentUsernameField: UITextField {

    
    
    override func awakeFromNib() {
        
        makeTextFieldBottomBorderOnly()
    }
    
    //For placeholder
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        
        return bounds.insetBy(dx: 5, dy: 0)
    }
    
    //For editable text
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        
        return bounds.insetBy(dx: 5, dy: 0)
    }
    
    func makeTextFieldBottomBorderOnly() {
        
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: frame.height - 1, width: frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.white.cgColor
        borderStyle = UITextBorderStyle.none
        layer.addSublayer(bottomLine)
        attributedPlaceholder = NSAttributedString(string: "Username", attributes:[NSForegroundColorAttributeName: UIColor.white])
        
    }


}
