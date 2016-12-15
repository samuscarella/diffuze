//
//  MyInfoVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/10/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase

class MyInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var darkendViewBtn: UIButton!
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var personalFilterBtn: UIButton!
    @IBOutlet weak var postTypeFilterBtn: UIButton!
    @IBOutlet weak var categoryFilterBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    let personalDataSource = ["My Posts","Liked","Disliked"]
    let postTypeDataSource = ["All","Text","Link","Image","Video","Audio","Quote"]
    let categoryDataSource = ["All"]

    var posts = [Post]()
    var currentLocation: [String:AnyObject] = [:]
    var personalFilterOption: String!
    var postTypeFilterOption: String!
    var categoryFilterOption: String!
    var personalFilterActive = false
    var postTypeFilterActive = false
    var categoryFilterActive = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.delegate = self
        pickerView.dataSource = self

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        personalFilterBtn.imageEdgeInsets = UIEdgeInsetsMake(30, 75, 30, 75)
        personalFilterBtn.setImage(UIImage(named: "filter-slider-black"), for: .normal)
        postTypeFilterBtn.imageEdgeInsets = UIEdgeInsetsMake(30, 75, 30, 75)
        postTypeFilterBtn.setImage(UIImage(named: "funnel-black"), for: .highlighted)
        categoryFilterBtn.imageEdgeInsets = UIEdgeInsetsMake(30, 75, 30, 75)
        categoryFilterBtn.setImage(UIImage(named: "categories-icon"), for: .highlighted)
        
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "folder-black.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(MyInfoVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        
        personalFilterOption = "My Posts"
        postTypeFilterOption = "All"
        categoryFilterOption = "All"
        
        let iD = UserService.ds.currentUserID
        URL_BASE.child("user-posts").child(iD).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary ?? [:]
            for post in value {
                let key = post.key as! String
                let postDict = post.value as! Dictionary<String,AnyObject>
                let post = Post(postKey: key, dictionary: postDict)
                self.posts.append(post)
            }
            self.tableView.reloadData()
        })

        if revealViewController() != nil {
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }

    }
    
    func notificationBtnPressed() {
        
    }
    
//    private func tableView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
//        
//        var post: Post!
//        post = posts[(indexPath as NSIndexPath).row]
//        performSegue(withIdentifier: "PostDetailVC", sender: post)
//    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if personalFilterActive {
            return personalDataSource.count
        } else if postTypeFilterActive {
            return postTypeDataSource.count
        } else if categoryFilterActive {
            return categoryDataSource.count
        }
        return personalDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if personalFilterActive {
            return personalDataSource[row]
        } else if postTypeFilterActive {
            return postTypeDataSource[row]
        } else if categoryFilterActive {
            return categoryDataSource[row]
        }
        return personalDataSource[row]
    }
    
    func  pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if personalFilterActive {
            self.personalFilterOption = personalDataSource[row]
        } else if postTypeFilterActive {
            self.postTypeFilterOption = postTypeDataSource[row]
        } else if categoryFilterActive {
            self.categoryFilterOption = categoryDataSource[row]
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if posts.count > 0 {
            let post = posts[(indexPath as NSIndexPath).row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell {
                
                cell.request?.cancel()
                
                let userLat = currentLocation["latitude"] as? Double
                let userLong = currentLocation["longitude"] as? Double
                
                var img: UIImage?
                
                if let postImgUrl = post.image {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                } else if let postImgUrl = post.thumbnail {
                    img = ActivityVC.imageCache.object(forKey: postImgUrl as AnyObject) as? UIImage
                }
                                
                cell.configureCell(post, currentLocation: currentLocation, image: img, postType: "myinfo")
                
                return cell
            } else {
                return PostCell(coder: NSCoder())
            }
        }
        return PostCell(coder: NSCoder())
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "PostDetailVC", sender: posts[indexPath.row])
    }
    
    @IBAction func personalFilterBtnPressed(_ sender: AnyObject) {
        
            personalFilterActive = true
            postTypeFilterActive = false
            categoryFilterActive = false
            pickerView.isHidden = false
            darkendViewBtn.isHidden = false
            darkendViewBtn.isUserInteractionEnabled = true
            darkendViewBtn.alpha = 0.0
            
            UIView.animate(withDuration: 0.5, animations: {
                
                self.darkendViewBtn.alpha = 0.75
            }, completion: { finished in
                
            })
        pickerView.reloadAllComponents()
    }
    
    @IBAction func postTypeFilterBtnPressed(_ sender: AnyObject) {
        
        personalFilterActive = false
        postTypeFilterActive = true
        categoryFilterActive = false
        pickerView.isHidden = false
        darkendViewBtn.isHidden = false
        darkendViewBtn.isUserInteractionEnabled = true
        darkendViewBtn.alpha = 0.0
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.darkendViewBtn.alpha = 0.75
        }, completion: { finished in
                
        })
        pickerView.reloadAllComponents()
    }
    
    @IBAction func darkenedViewBtnPressed(_ sender: AnyObject) {
        
        pickerView.isHidden = true
        darkendViewBtn.isHidden = true
        darkendViewBtn.isUserInteractionEnabled = false
        darkendViewBtn.alpha = 0.0
        
        print(personalFilterOption)
        print(postTypeFilterOption)
        print(categoryFilterOption)
    }
    
    @IBAction func unwindToMyInfoVC(_ segue: UIStoryboardSegue) {
        
        
    }

}
