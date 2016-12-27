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
    var checked = [String]()
    var comingFromCategoryVC = true
    var previousVC: String!
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //        let category = categories[indexPath.row]
        if let cell = tableView.cellForRow(at: indexPath) as? CategoryCell {
            
            let category = categories[(indexPath as NSIndexPath).row]

            var doesItExist = false
            
            if checked.count == 0 {
                checked.append(category.name)
                cell.categoryCheckmark.image = UIImage(named: "checked")
            } else if checked.count > 0 {
                for i in 0...checked.count - 1 {
                    if checked[i] == category.name {
                        doesItExist = true
                        checked.remove(at: i)
                        cell.categoryCheckmark.image = nil
                        break
                    }
                }
                if doesItExist == false {
                    checked.append(category.name)
                    cell.categoryCheckmark.image = UIImage(named: "checked")
                }
            }
            print(checked)
        }
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
            
            if checked.count > 0 {
                for i in 0...checked.count - 1 {
                    if checked[i] == category.name {
                        cell.categoryCheckmark.image = UIImage(named: "checked")
                        break
                    }
                }
            }
            return cell
        } else {
            return CategoryCell()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if previousVC == "MyInfoVC" {
            
            let vC = segue.destination as! MyInfoVC;
            vC.categoryFilterOptions = self.checked
            vC.comingFromCategoryFilterVC = true
        } else if previousVC == "ActivityVC" {
            
            let vC = segue.destination as! ActivityVC;
            vC.categoryFilterOptions = self.checked
            vC.comingFromCategoryFilterVC = true
        }
    }
    
    @IBAction func darkenedViewBtnPressed(_ sender: AnyObject) {
        if previousVC == "MyInfoVC" {
            
            self.performSegue(withIdentifier: "unwindToMyInfoVC", sender: self)
        } else if previousVC == "RadarVC" {
            self.performSegue(withIdentifier: "unwindToActivityVC", sender: self)
        } else if previousVC == "ViralVC" {
            self.performSegue(withIdentifier: "unwindToViralVC", sender: self)
        }
    }
    
}
