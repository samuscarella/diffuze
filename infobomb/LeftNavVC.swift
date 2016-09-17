//
//  LeftNavVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/6/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class LeftNavVC: UITableViewController {
    

    @IBOutlet var table: UITableView!
    
    @IBOutlet var navButtons: [UIButton]!
    @IBOutlet weak var activityBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Subclass navigation bar after app is finished and all other non DRY
        table.allowsSelection = false
        table.scrollEnabled = false;
        activityBtn.setTitleColor(CRIMSON, forState: .Normal)
    }
    
    
    @IBAction func navBtnPressed(sender: AnyObject) {
        
        for button in navButtons {
            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        }
        
        if(sender.tag == 1) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 2) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 3) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 4) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 5) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 6) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 7) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 8) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 9) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 10) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 11) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        } else if(sender.tag == 12) {
            sender.setTitleColor(CRIMSON, forState: .Normal)
        }
        
    }
    
    
}
