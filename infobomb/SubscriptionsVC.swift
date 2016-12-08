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
    
    static var imageCache = NSCache<AnyObject, AnyObject>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "subscribe-rss-button.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView

        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
//        button.addTarget(self, action: #selector(SubscriptionsVC.notificationBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton


        NotificationCenter.default.addObserver(LocationService(), selector: #selector(LocationService.stopUpdatingLocation), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        tableView.delegate = self
        tableView.dataSource = self

        CategoryService.ds.REF_CATEGORIES.queryOrdered(byChild: "name").observe(FIRDataEventType.value, with: { (snapshot) in
            
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
            
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }

    }
    

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let category = categories[(indexPath as NSIndexPath).row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionCell") as? SubscriptionCell {
            
            cell.request?.cancel()
        
            var img: UIImage?
            
            if let url = category.image_path {
                img = SubscriptionsVC.imageCache.object(forKey: url as AnyObject) as? UIImage
            }
            
            cell.configureCell(category, img: img)
            
            return cell
            
        } else {
            return SubscriptionCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
}
