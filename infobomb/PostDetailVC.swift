
import UIKit
import SwiftLinkPreview
import Alamofire

class PostDetailVC: UIViewController {

    @IBOutlet weak var mediaImg: UIImageView!
    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var messageLblHeight: NSLayoutConstraint!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var categoryOneImg: UIImageView!
    @IBOutlet weak var categoryTwoImg: UIImageView!
    
    var isMessageEmpty = true
    var isLinkDescriptionLblEmpty = true
    var request: Request?
    
    let slp = SwiftLinkPreview()
    let font = UIFont(name: "Helvetica", size: 12.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        //mediaImg.clipsToBounds = true

        //categoryOneImg.layer.cornerRadius = categoryOneImg.frame.size.width / 2
        //categoryOneImg.clipsToBounds = true
        
        //categoryTwoImg.layer.cornerRadius = categoryTwoImg.frame.size.width / 2
        //categoryTwoImg.clipsToBounds = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = UIColor.black
        let logo = UIImage(named: "detail.png")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        
        //categoryOneImg.layoutIfNeeded()
        //categoryTwoImg.layoutIfNeeded()
        //categoryOneImg.layer.cornerRadius = categoryOneImg.frame.size.width / 2
        //categoryOneImg.clipsToBounds = true
        
        //categoryTwoImg.layer.cornerRadius = categoryTwoImg.frame.size.width / 2
        //categoryTwoImg.clipsToBounds = true

        
        imageView.center = (imageView.superview?.center)!
        self.navigationItem.titleView = customView

        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        NotificationCenter.default.addObserver(self, selector: #selector(PostDetailVC.updateViews), name: NSNotification.Name(rawValue: "messageHeightUpdated"), object: nil)
        
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(PostDetailVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        
    }
    
    func notificationBtnPressed() {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        if (messageLbl != nil) && messageLbl.text! != "" {
            isMessageEmpty = false
            let height = heightForView(messageLbl, text: messageLbl.text!, font: font!)
            if messageLblHeight != nil {
                messageLblHeight.constant = height
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
        } else {
            if messageLblHeight != nil {
                messageLblHeight.constant = 1.0
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "messageHeightUpdated"), object: nil)
        }

    }
    
    func updateViews()  {
        
//        var totalHeight: CGFloat = 0
//        
//        for subView in self.contentView.subviews {
//            
//            if subView.tag == 5 && isMessageEmpty == false {
//                
//                totalHeight += subView.frame.height
//            } else if subView.tag == 6 && isLinkDescriptionLblEmpty == false {
//                
//                totalHeight += subView.frame.height
//            } else if subView.tag != 5 {
//                if subView.tag != 1 && subView.tag != 2 && subView.tag != 3 && subView.tag != 4 {
//                    
//                    totalHeight += subView.frame.height
//                }
//            }
//        }
//        self.contentViewHeight.constant = totalHeight + 15
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
