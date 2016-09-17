//
//  PremiumVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/6/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class PremiumVC: UIViewController {

    @IBOutlet weak var menuBtn: UIBarButtonItem!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Premium"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        //Burger side menu
        if revealViewController() != nil {
            menuBtn.target = revealViewController()
            menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
        }
    }
}
