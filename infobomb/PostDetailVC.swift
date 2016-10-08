//
//  PostDetailVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 9/27/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import SwiftLinkPreview
import Alamofire

class PostDetailVC: UIViewController {

    @IBOutlet weak var mediaImg: UIImageView!
    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var messageLblHeight: NSLayoutConstraint!
    @IBOutlet weak var mediaViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var linkTitleLbl: UILabel!
    @IBOutlet weak var linkLbl: UILabel!
    @IBOutlet weak var linkDescriptionLbl: UILabel!
    @IBOutlet weak var linkDescriptionLblHeight: NSLayoutConstraint!
    @IBOutlet weak var openLinkBtn: UIButton!
    
    var isMessageEmpty = true
    var isLinkDescriptionLblEmpty = true
    var request: Request?

    let slp = SwiftLinkPreview()
    
    let font = UIFont(name: "Helvetica", size: 20.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        print("PostDetailVC")

        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.title = "Text"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!, NSForegroundColorAttributeName: LIGHT_GREY]
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(ActivityVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.automaticallyAdjustsScrollViewInsets = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(PostDetailVC.updateViews), name: NSNotification.Name(rawValue: "messageHeightUpdated"), object: nil)
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

        //dynamically size messageLbl height
        if messageLbl.text! != "" {
            isMessageEmpty = false
            let height = heightForView(messageLbl, text: messageLbl.text!, font: font!)
            messageLblHeight.constant = height
            print(height)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
        } else {
            messageLblHeight.constant = 1.0
            NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
        }
        
        slp.preview(
            "https://www.appcoda.com/uiscrollview-introduction/",
            onSuccess: { result in
                print("\(result)")
                self.linkTitleLbl.text = result["title"] as! String?
                self.linkLbl.text = result["canonicalUrl"] as! String?
                self.linkDescriptionLbl.text = result["description"] as! String?
                
                if let imageUrl = result["image"] as! String? {
                    
                    self.request = Alamofire.request(imageUrl).validate(contentType: ["image/*"]).response {  response in
                    
                        if response.error == nil {
                            let img = UIImage(data: response.data!)!
                            self.mediaImg.image = img
                            self.openLinkBtn.isHidden = false
                        } else {
                            print(response.error)
                        }
                    }
                }

                //dynamically size linkDescriptionLbl height
                if self.linkDescriptionLbl.text! != "" {
                    self.isLinkDescriptionLblEmpty = false
                    let height = self.heightForView(self.linkDescriptionLbl, text: self.linkDescriptionLbl.text!, font: self.font!)
                    self.linkDescriptionLblHeight.constant = height
                    print(height)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
                    
                } else {
                    self.linkDescriptionLblHeight.constant = 1.0
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
                }
            },
            onError: { error in
                print("\(error)")
            }
        )

        

    }
    
    func updateViews()  {
        
        var totalHeight: CGFloat = 0
        
        for subView in self.contentView.subviews {
            
            if subView.tag == 5 && isMessageEmpty == false {
                //print(subView)
                //print(subView.frame.height)
                totalHeight += subView.frame.height
            } else if subView.tag == 6 && isLinkDescriptionLblEmpty == false {
                
                totalHeight += subView.frame.height
            } else if subView.tag != 5 {
                if subView.tag != 1 && subView.tag != 2 && subView.tag != 3 && subView.tag != 4 {
                    //print(subView)
                    //print(subView.frame.height)
                    totalHeight += subView.frame.height
                }
            }
        }
        self.contentViewHeight.constant = totalHeight + 50
        

    }
    
    override func viewDidLayoutSubviews() {
        


        
        

        

    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToActivityVC", sender: self)
    }
    
    func heightForView(_ label:UILabel, text: String, font:UIFont) -> CGFloat {
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }


}
