//
//  ImagePostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/8/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit

class ImagePostVC: UIViewController {

    
    @IBOutlet weak var backBtn: UIBarButtonItem!
    
    
    @IBOutlet weak var imageIconView: MaterialView!
    @IBOutlet weak var imageHeaderView: MaterialView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("ImagePostVC")
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.title = "Image"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!,NSForegroundColorAttributeName: LIGHT_GREY]
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(LinkPostVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImagePostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        imageIconView.separatorColor = UIColor.clear
        imageHeaderView.separatorColor = UIColor.clear
        
    }
    
    func dismissKeyboard() {

        view.endEditing(true)
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }


}
