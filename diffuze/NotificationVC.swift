//
//  NotificationVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 1/7/17.
//  Copyright © 2017 samuscarella. All rights reserved.
//

import UIKit
import Firebase

class NotificationVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var notificationView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var notificationHeaderLbl: UILabel!
    @IBOutlet weak var notificationHeaderImageView: UIImageView!

    static var imageCache = NSCache<AnyObject, AnyObject>()
    
    var notifications = [NotificationCustom]()
    var sortedNotifications = [NotificationCustom]()
    var lineView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        notificationView.layer.cornerRadius = 3
        
        print(notifications)
        if notifications.count > 0 {
            
            sortedNotifications = notifications.sorted(by: { $0.timestamp > $1.timestamp })
            
            tableView.isHidden = false
            tableView.delegate = self
            tableView.dataSource = self
            tableView.layer.cornerRadius = 3
            
            lineView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width, height: 1.0))
            lineView.backgroundColor = UIColor.lightGray
            tableView.addSubview(lineView)
            
        } else {
            notificationHeaderLbl.isHidden = true
            notificationHeaderImageView.isHidden = true
        }
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as? NotificationCell
        if cell?.type == "radar" {
            
            performSegue(withIdentifier: "ActivityVC", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if sortedNotifications.count > 0 {
            
            let notification = sortedNotifications[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as? NotificationCell {
                
                cell.selectionStyle = .none
                
                cell.request?.cancel()
                
                cell.configureCell(notification: notification)
                
                return cell
            }
        }
        return NotificationCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ModalTransitionMediator.instance.sendPopoverDismissed(modelChanged: true)
    }
    
    @IBAction func notificationBtnPressed(_ sender: AnyObject) {
        
        dismiss(animated: true, completion: nil)
    }
    
}
