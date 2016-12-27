//
//  VideoUploadOptionVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 11/6/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class VideoUploadOptionVC: UIViewController {

    
    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var infoBombUploadBtn: UIButton!
    @IBOutlet weak var youTubeUploadBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
//        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.white
        let logo = UIImage(named: "menu.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView

        
//        let explodingSunImg = UIImage(named: "exploding-sun")
//        infoBombUploadBtn.setImage(explodingSunImg, for: .normal)
        infoBombUploadBtn.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        infoBombUploadBtn.layer.cornerRadius = infoBombUploadBtn.bounds.size.width / 2
        infoBombUploadBtn.clipsToBounds = true
        
        let youTubeLogo = UIImage(named: "youtube-logo.png")
        youTubeUploadBtn.setImage(youTubeLogo, for: .normal)
        youTubeUploadBtn.imageEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
        youTubeUploadBtn.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        youTubeUploadBtn.layer.cornerRadius = youTubeUploadBtn.bounds.size.width / 2
        youTubeUploadBtn.clipsToBounds = true
        youTubeUploadBtn.layer.borderWidth = 1
        youTubeUploadBtn.layer.borderColor = UIColor.black.cgColor

    }
    
    @IBAction func infoBombBtnPressed(_ sender: AnyObject) {
        
    }
    
    @IBAction func youTubeBtnPressed(_ sender: AnyObject) {
        
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }
    
    @IBAction func unwindToVideoUploadOption(_ segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
       if segue.identifier == NEW_VIDEO_POST {
            let nav = segue.destination as! UINavigationController;
            let mediaView = nav.topViewController as! ImagePostVC
            mediaView.previousVC = NEW_VIDEO_POST
        }
        
    }

    

}
