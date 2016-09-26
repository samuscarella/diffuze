//
//  SubscriptionsVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/6/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase

class SubscriptionsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var subscriptionSwitch: UISwitch!
    
    var categories = [Category]()
    
    static var imageCache = NSCache()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.title = "Subscriptions"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
//        let menuButton: UIButton = UIButton(type: UIButtonType.Custom)
//        menuButton.setImage(UIImage(named: "menu-btn.png"), forState: UIControlState.Normal)
//        //        button.addTarget(self, action: #selector(SubscriptionsVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
//        menuButton.frame = CGRectMake(0, 0, 50, 32)
//        let menuBar = UIBarButtonItem(customView: menuButton)
//        self.navigationItem.leftBarButtonItem = menuBar

        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "notification.png"), forState: UIControlState.Normal)
//        button.addTarget(self, action: #selector(SubscriptionsVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 27, 27)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.Custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), forState: UIControlState.Normal)
        menuButton.frame = CGRectMake(0, 0, 60, 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton


        NSNotificationCenter.defaultCenter().addObserver(LocationService(), selector: #selector(LocationService.stopUpdatingLocation), name: "userSignedOut", object: nil)

        tableView.delegate = self
        tableView.dataSource = self

        CategoryService.ds.REF_CATEGORIES.queryOrderedByChild("name").observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                self.categories = []
                for snap in snapshots {
                    
                    if let categoryDict = snap.value as?  Dictionary<String, AnyObject> {
                        let key = snap.key
                        let category = Category(categoryKey: key, dictionary: categoryDict)
                        self.categories.append(category)
                    }
                }
            }
            
            self.tableView.reloadData()
        })

        
        //Burger side menu
        if revealViewController() != nil {
            
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }

    }
    

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let category = categories[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("SubscriptionCell") as? SubscriptionCell {
            
            cell.request?.cancel()
        
            var img: UIImage?
            
            if let url = category.image_path {
                img = SubscriptionsVC.imageCache.objectForKey(url) as? UIImage
            }
        
            cell.configureCell(category, img: img)
            
            return cell
            
        } else {
            return SubscriptionCell()
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
}
