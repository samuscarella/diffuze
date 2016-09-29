//
//  PostDetailVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/27/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class PostDetailVC: UIViewController {

    @IBOutlet weak var backBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NSUserDefaults.standardUserDefaults().setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        print("PostDetailVC")

        let image = UIImage(named: "metal-bg.jpg")?.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.Stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Text"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "notification.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 27, 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    @IBAction func backBtnPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindToActivityVC", sender: self)
    }


}
