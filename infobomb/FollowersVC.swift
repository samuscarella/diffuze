//
//  FollowersVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 12/4/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase

class FollowersVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var followersBtn: UIButton!
    @IBOutlet weak var followingBtn: UIButton!
    @IBOutlet weak var noFollowersImageView: UIImageView!
    @IBOutlet weak var noFollowersLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var currentUserID: String!
    var lineView: UIView!
    var users = [User]()
    var filteredUsers = [User]()
    var usersIds = [String]()
    var followingTableCurrent = true
    var followerTableCurrent = false
    var inSearchMode = false
    var myGroup = DispatchGroup()
    var secondGroup = DispatchGroup()
    
    static var imageCache = NSCache<AnyObject, AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.returnKeyType = UIReturnKeyType.done

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "follower-black.png")
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
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menuButton: UIButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "menu-btn.png"), for: UIControlState())
        menuButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        let leftBarButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        self.searchBar.searchBarStyle = UISearchBarStyle.prominent
        self.searchBar.isTranslucent = false
        self.searchBar.barTintColor = UIColor.white
        
        followersBtn.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width / 2, height: 36)
        followingBtn.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width / 2, height: 36)
        
        lineView = UIView(frame: CGRect(x: 0.0, y: followersBtn.frame.size.height - 1, width: followersBtn.frame.size.width, height: 3.0))
        lineView.backgroundColor = UIColor.red
        followingBtn.addSubview(lineView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        currentUserID = UserDefaults.standard.object(forKey: KEY_UID) as! String
        
        self.noFollowersImageView.image = UIImage(named: "followers-grey")
        self.noFollowersLbl.text = "You are not following anyone yet. They will show up here after you do."

        getFollowing()
       /* URL_BASE.child("users").child(currentUserID).child("following").observe(FIRDataEventType.value, with: { (snapshot) in
            
            let followingUsers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            for user in followingUsers {
                self.usersIds.append(user.key)
            }
            
            for id in self.usersIds {
                URL_BASE.child("users").child(id).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                  
                    if let userDict = snapshot.value as? Dictionary<String,AnyObject> {
                        
                        let user = User.init(userId: userDict["user_ref"] as! String, dictionary: userDict)
                        print(user)
                        self.users.append(user)
                        self.tableView.reloadData()
                    }
                })
            }
            
        }) */

        //Burger side menu
        if revealViewController() != nil {
            menuButton.addTarget(revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if users.count > 0 || filteredUsers.count > 0 {
        
            var user: User!
            
            if inSearchMode {
                user = filteredUsers[(indexPath as NSIndexPath).row]
            } else {
                user = users[(indexPath as NSIndexPath).row]
            }

            if let cell = tableView.dequeueReusableCell(withIdentifier: "FollowerCell") as? FollowerCell {

//                cell.request?.cancel()
                
                var img: UIImage?
                
                if let url = user.userPhoto {
                    img = FollowersVC.imageCache.object(forKey: url as AnyObject) as? UIImage
                }
                
                cell.configueCell(user: user, img: img)
                
                return cell
                
            } else {
                return FollowerCell()
            }
        }
        return FollowerCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode {
            if filteredUsers.count > 0 {
                noFollowersImageView.isHidden = true
                noFollowersLbl.isHidden = true
            } else {
                noFollowersImageView.isHidden = false
                noFollowersLbl.isHidden = false
                noFollowersImageView.image = UIImage(named: "search-grey")
                noFollowersLbl.text = "There are no results matching your search criteria"
            }
            return filteredUsers.count
        } else {
            if users.count > 0 {
                noFollowersImageView.isHidden = true
                noFollowersLbl.isHidden = true
            } else {
                noFollowersImageView.isHidden = false
                noFollowersLbl.isHidden = false
            }
            return users.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    @IBAction func followersBtnPressed(_ sender: AnyObject) {

        self.followersBtn.titleLabel?.font = UIFont(name: "Ubuntu-Bold", size: 18.0)
        self.followingBtn.titleLabel?.font = UIFont(name: "Ubuntu", size: 18.0)
        self.lineView.removeFromSuperview()
        self.followersBtn.addSubview(lineView)
        noFollowersImageView.isHidden = false
        noFollowersLbl.isHidden = false
        self.noFollowersImageView.image = UIImage(named: "follower-grey")
        self.noFollowersLbl.text = "You do not have any followers yet. They will show up here after you get some."
        getFollowers()
    }
    
    @IBAction func followingBtnPressed(_ sender: AnyObject) {
        
        self.followingBtn.titleLabel?.font = UIFont(name: "Ubuntu-Bold", size: 18.0)
        self.followersBtn.titleLabel?.font = UIFont(name: "Ubuntu", size: 18.0)
        self.lineView.removeFromSuperview()
        self.followingBtn.addSubview(lineView)
        noFollowersImageView.isHidden = false
        noFollowersLbl.isHidden = false
        self.noFollowersImageView.image = UIImage(named: "followers-grey")
        self.noFollowersLbl.text = "You are not following anyone yet. They will show up here after you do."
        getFollowing()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == nil || searchBar.text == "" {
            inSearchMode = false
            view.endEditing(true)
        } else {
            inSearchMode = true
            let lower = searchBar.text?.lowercased()
            filteredUsers = users.filter({$0.username.lowercased().range(of: lower!) != nil})
        }
        tableView.reloadData()
    }
    
    func getFollowing() {
        
        self.usersIds = []
        self.users = []
        URL_BASE.child("users").child(currentUserID).child("following").observe(FIRDataEventType.value, with: { (snapshot) in
            
            let followingUsers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            if followingUsers.count == 0 {
                self.users = []
                self.tableView.reloadData()
            } else {
                self.noFollowersLbl.isHidden = true
                self.noFollowersImageView.isHidden = true
            }
            
            for user in followingUsers {
                self.usersIds.append(user.key)
            }
            
            for id in self.usersIds {
                
                self.myGroup.enter()
                URL_BASE.child("users").child(id).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                    
                    if let userDict = snapshot.value as? Dictionary<String,AnyObject> {
                        
                        let user = User.init(userId: userDict["user_ref"] as! String, dictionary: userDict)
                        self.users.append(user)
                    }
                    self.myGroup.leave()
                })
            }
            
            self.myGroup.notify(queue: DispatchQueue.main, execute: {
                
                if self.users.count > 0 {
                    self.noFollowersLbl.isHidden = true
                    self.noFollowersImageView.isHidden = true
                    self.tableView.reloadData()
                } else {
                    
                    self.noFollowersLbl.isHidden = false
                    self.noFollowersImageView.isHidden = false
                }
            })
        })
        
    }
    
    func getFollowers() {
        
        self.usersIds = []
        self.users = []
        URL_BASE.child("users").child(currentUserID).child("followers").observe(FIRDataEventType.value, with: { (snapshot) in
            
            let followers = snapshot.children.allObjects as? [FIRDataSnapshot] ?? []
            
            if followers.count == 0 {
                self.users = []
                self.tableView.reloadData()
            } else {
                self.noFollowersLbl.isHidden = true
                self.noFollowersImageView.isHidden = true
            }
            
            for user in followers {
                self.usersIds.append(user.key)
            }
            
            for id in self.usersIds {
                
                self.secondGroup.enter()
                URL_BASE.child("users").child(id).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                    
                    if let userDict = snapshot.value as? Dictionary<String,AnyObject> {
                        
                        let user = User.init(userId: userDict["user_ref"] as! String, dictionary: userDict)
                        self.users.append(user)
                    }
                    self.secondGroup.leave()
                })
            }
            
            self.secondGroup.notify(queue: DispatchQueue.main, execute: {
                
                if self.users.count > 0 {
                    self.noFollowersLbl.isHidden = true
                    self.noFollowersImageView.isHidden = true
                    self.tableView.reloadData()
                } else {
                    
                    self.noFollowersLbl.isHidden = false
                    self.noFollowersImageView.isHidden = false
                }
            })
        })
    }
    

}
