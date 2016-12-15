//
//  CategoryFilterVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/14/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase

class CategoryFilterVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var categories = [Category]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        CategoryService.ds.REF_CATEGORIES.queryOrdered(byChild: "name").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
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
            if self.categories.count > 0 {
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let category = categories[(indexPath as NSIndexPath).row]
            
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") as? CategoryCell {
                
                cell.request?.cancel()
                
                var img: UIImage?
                
                if let url = category.image_path {
                    img = SubscriptionsVC.imageCache.object(forKey: url as AnyObject) as? UIImage
                }
                
                cell.configureCell(category, img: img)
                
            return cell
        } else {
            return CategoryCell()
        }
    }
    
    @IBAction func darkenedViewBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToMyInfoVC", sender: self)
    }
    
    
}
