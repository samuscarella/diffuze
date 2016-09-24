//
//  NewPostControllerVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/10/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import CoreLocation

class NewPostVC: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var textView: MaterialView!
    @IBOutlet weak var linkView: MaterialView!
    @IBOutlet weak var imageView: MaterialView!
    @IBOutlet weak var videoView: MaterialView!
    @IBOutlet weak var audioView: MaterialView!
    @IBOutlet weak var premiumView: MaterialView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "New Post"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "notification.png"), forState: UIControlState.Normal)
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 27, 27)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        textView.separatorColor = UIColor.clearColor()
        linkView.separatorColor = UIColor.clearColor()
        imageView.separatorColor = UIColor.clearColor()
        videoView.separatorColor = UIColor.clearColor()
        audioView.separatorColor = UIColor.clearColor()
        premiumView.separatorColor = UIColor.clearColor()
        

        //Burger side menu
        if revealViewController() != nil {
            menuBtn.target = revealViewController()
            menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
        }

    }
    
    @IBAction func unwindToNewPost(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func cancelNewPostBtn(sender: AnyObject) {
        
        if (self.navigationController != nil) {
            self.navigationController!.popViewControllerAnimated(true)
        }
    }
    

}
