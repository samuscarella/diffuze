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
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("NewPostVC")
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.title = "New Post"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton

        
//        textView.separatorColor = UIColor.clear
//        linkView.separatorColor = UIColor.clear
//        imageView.separatorColor = UIColor.clear
//        videoView.separatorColor = UIColor.clear
//        audioView.separatorColor = UIColor.clear
//        premiumView.separatorColor = UIColor.clear
        
        NotificationCenter.default.addObserver(LocationService(), selector: #selector(LocationService.stopUpdatingLocation), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        //Burger side menu
        if revealViewController() != nil {
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }

    }
    
    @IBAction func unwindToNewPost(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func cancelNewPostBtn(_ sender: AnyObject) {
        
        if (self.navigationController != nil) {
            self.navigationController!.popViewController(animated: true)
        }
    }
    

}
