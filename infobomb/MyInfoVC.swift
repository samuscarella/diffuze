//
//  MyInfoVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/10/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class MyInfoVC: UIViewController {

    @IBOutlet weak var newPostBtn: UIBarButtonItem!
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.Stretch)

        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "My Info"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        let menuButton: UIButton = UIButton(type: UIButtonType.Custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), forState: UIControlState.Normal)
        menuButton.frame = CGRectMake(0, 0, 60, 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton

        
        //Burger side menu
        if revealViewController() != nil {
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }

    }
    
    @IBAction func newPostBtnPressed(sender: AnyObject) {
        
    }
    

}
