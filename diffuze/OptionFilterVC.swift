//
//  OptionFilterVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 1/4/17.
//  Copyright © 2017 samuscarella. All rights reserved.
//

import UIKit

class OptionFilterVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    let postTypeText = ["All","Text","Link","Image","Video","Audio","Quote"]
    let personalFilterOptions = ["My Posts","Liked","Disliked"]
    let viralFilterOptions = ["Popularity","Rating"]
    
    var filterType: String!
    var previousVC: String!
    var activePostType: String?
    var activePersonalOption: String?
    var activeViralOption: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if previousVC == "ViralVC" && filterType == "Viral" {
            print("u98dihfaihornvt8uanwep9r8byaptv\n\n\n\n\n\n\n\n\n\n")
            tableViewHeight.constant = 120
            tableView.isScrollEnabled = false
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filterType == "PostType" {
            return postTypeText.count
        } else if filterType == "Personal" {
            return personalFilterOptions.count
        } else if filterType == "Viral" {
            return viralFilterOptions.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if filterType == "PostType" {
            
            let postType = postTypeText[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as? FilterCell {
                
                cell.configureCell(filterName: postType, activePostType: activePostType!)
                
                return cell
            }
        } else if filterType == "Personal" {
            
            let personalFilter = personalFilterOptions[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as? FilterCell {
                
                cell.configureCell(filterName: personalFilter, activePostType: activePersonalOption!)
                
                return cell
            }
        } else if filterType == "Viral" {
            
            let viralFilter = viralFilterOptions[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as? FilterCell {
                
                cell.configureCell(filterName: viralFilter, activePostType: activeViralOption!)
                
                return cell
            }
        }
        return FilterCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as? FilterCell
        cell?.selectionStyle = .none
        
        if filterType == "PostType" {
            activePostType = cell?.filterOptionLbl.text
        } else if filterType == "Personal" {
            activePersonalOption = cell?.filterOptionLbl.text
        } else if filterType == "Viral" {
            activeViralOption = cell?.filterOptionLbl.text
        }
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if previousVC == "RadarVC" {
            
            let vC = segue.destination as! ActivityVC
            vC.activePostType = self.activePostType
            vC.comingFromPostTypeFilterVC = true
        } else if previousVC == "MyInfoVC" {
            
            let vC = segue.destination as! MyInfoVC
            vC.activePostType = self.activePostType
            vC.activePersonalOption = self.activePersonalOption
            
            if filterType == "PostType" {
                vC.comingFromPostTypeFilterVC = true
            } else if filterType == "Personal" {
                vC.comingFromPersonalFilterVC = true
            }
        } else if previousVC == "ViralVC" {
            
            let vC = segue.destination as! ViralVC
            vC.activePostType = self.activePostType
            vC.activeViralOption = self.activeViralOption
            
            if filterType == "PostType" {
                vC.comingFromPostTypeFilterVC = true
            } else if filterType == "Viral" {
                vC.comingFromPersonalFilterVC = true
            }
        }
    }

    @IBAction func backBtnPressed(_ sender: AnyObject) {
        
        if previousVC == "RadarVC" {
            performSegue(withIdentifier: "unwindToActivityVC", sender: self)
        } else if previousVC == "MyInfoVC" {
            performSegue(withIdentifier: "unwindToMyInfoVC", sender: self)
        } else if previousVC == "ViralVC" {
            performSegue(withIdentifier: "unwindToViralVC", sender: self)
        }
    }
}
