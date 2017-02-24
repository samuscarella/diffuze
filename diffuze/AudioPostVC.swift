//
//  AudioPostVC.swift
//  infobomb
//
//  Created by Stephen Muscarella on 10/9/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Pulsator
import GeoFire
import FirebaseAuth

private var latitude = 0.0
private var longitude = 0.0

class AudioPostVC: UIViewController, UITextFieldDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var recordBtnView: UIView!
    @IBOutlet weak var chooseCategoriesBtn: MaterialButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var audioSlider: UISlider!
    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var audioWaveView: VideoContainerView!
    @IBOutlet weak var recordBtnMidView: UIView!
    @IBOutlet weak var recordBtnOuterView: UIView!
    @IBOutlet weak var tapBtnLbl: UILabel!
    @IBOutlet weak var recordBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var recordBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var savedTimeLbl: UILabel!
    @IBOutlet weak var restartBtn: UIButton!
    
    let pulsator = Pulsator()
    let geofireRef = UserService.ds.REF_USER_LOCATIONS
    let iD = UserService.ds.currentUserID
    
    var categories = [Category]()
    var locationService: LocationService!
    var currentLocation: [String:AnyObject] = [:]
    var geoFire: GeoFire!
    var timer: Timer?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var updater: CADisplayLink! = nil
    var videoLayer: AVPlayerLayer?
    var player: AVPlayer?
    var audioPlayer: AVAudioPlayer?
    var audioURL = NSURL(string: "")
    var item: AVPlayerItem?
    var linkObj: [String:AnyObject] = [:]
    var dot: UIView!
    var radarWatchObj: Dictionary<String,AnyObject>?
    var notificationService: NotificationService!
    var notifications = [NotificationCustom]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("AudioPostVC")
                
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        let customView = UIView()
        customView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        customView.backgroundColor = OCEAN_BLUE
        let logo = UIImage(named: "microphone.png")
        let imageView = UIImageView(image:logo)
        imageView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        customView.addSubview(imageView)
        customView.layer.cornerRadius = customView.frame.size.width / 2
        customView.clipsToBounds = true
        
        imageView.center = (imageView.superview?.center)!
        
        self.navigationItem.titleView = customView
        
        titleField.delegate = self
        titleField.alpha = 0.3
        titleField.attributedPlaceholder = NSAttributedString(string: "Title", attributes:[NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.italicSystemFont(ofSize: 24.0)])
        
        dot = UIView(frame: CGRect(x: 14, y: 16, width: 12, height: 12))
        dot.backgroundColor = UIColor.red
        dot.layer.cornerRadius = dot.frame.size.height / 2
        dot.isHidden = true
        dot.isUserInteractionEnabled = false
        dot.isExclusiveTouch = false
        dot.isHidden = true

        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "notification.png"), for: UIControlState())
        button.addTarget(self, action: #selector(AudioPostVC.notificationBtnPressed), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        button.addSubview(dot)
        let rightBarButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let yCenter = NSLayoutConstraint(item: recordBtnView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([yCenter])
        
        recordBtn.layer.cornerRadius = recordBtn.frame.size.width / 2
        recordBtnView.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
        recordBtnView.backgroundColor = SMOKY_BLACK
        recordBtnView.layer.borderColor = ANTI_FLASH_WHITE.cgColor
        recordBtnView.layer.borderWidth = 2
        recordBtnView.layer.cornerRadius = recordBtnView.frame.size.width / 2
        recordBtnMidView.frame = CGRect(x: 0, y: 0, width: 117, height: 117)
        recordBtnMidView.alpha = 0.4
        recordBtnMidView.layer.cornerRadius = recordBtnMidView.frame.size.width / 2
        recordBtnOuterView.frame = CGRect(x: 0, y: 0, width: 159, height: 159)
        recordBtnOuterView.layer.cornerRadius = recordBtnOuterView.frame.size.width / 2
        recordBtnOuterView.layer.borderWidth = 2
        recordBtnOuterView.layer.borderColor = POWDER_BLUE.cgColor
        recordBtnOuterView.backgroundColor = UIColor(red: 143.0 / 255.0, green: 191.0 / 255.0, blue: 224.0 / 255.0, alpha: 0.2)
        
        recordBtn.showsTouchWhenHighlighted = true
        pulsator.radius = 300.0
        pulsator.numPulse = 6
        pulsator.backgroundColor = OCEAN_BLUE.cgColor
        pulsator.animationDuration = 3.0
        pulsator.pulseInterval = 0
    
        recordBtnView.layer.superlayer?.insertSublayer(pulsator, below: recordBtnView.layer)
          audioSlider.minimumValue = 0
          audioSlider.maximumValue = 100
        titleField.isHidden = true
        
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        notificationService = NotificationService()
        notificationService.getNotifications()
        notificationService.watchRadar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotifications), name: NSNotification.Name(rawValue: "newFollowersNotification"), object: nil)
        
        locationService = LocationService()
        locationService.startTracking()
        locationService.addObserver(self, forKeyPath: "latitude", options: .new, context: &latitude)
        locationService.addObserver(self, forKeyPath: "longitude", options: .new, context: &longitude)
        
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.updateUserLocation), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.terminateAuthentication), name: NSNotification.Name(rawValue: "userSignedOut"), object: nil)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AudioPostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)

        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Recording session enabled.")
                    }
                }
            }
        } catch {
            print("Failed to Record")
        }
    }
    
    func popoverDismissed() {
        
        notificationService.getNotifications()
    }
    
    func updateNotifications(notification: NSNotification) {
        
        self.notifications = []
        let incomingNotifications = notification.object as! [NotificationCustom]
        self.notifications = incomingNotifications
        var newNotifications = false
        for n in notifications {
            if n.read == false {
                newNotifications = true
                dot.isHidden = false
                break
            }
        }
        if !newNotifications {
            dot.isHidden = true
        }
        print("Updated Notifications From Followers: \(self.notifications)")
    }
    
    func notificationBtnPressed() {
        
        let notificationVC = self.storyboard?.instantiateViewController(withIdentifier: "NotificationVC") as! NotificationVC
        notificationVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        notificationVC.notifications = self.notifications
        present(notificationVC, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        titleField.textColor = UIColor.white
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: titleField.frame.height - 1, width: titleField.frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.white.cgColor
//        titleField.layer.addSublayer(bottomLine)

        pulsator.position = recordBtnView.layer.position
    }

    
    override func viewDidAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(AudioPostVC.playerItemDidReachEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &latitude {
            latitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["latitude"] = latitude as AnyObject?
        }
        if context == &longitude {
            longitude = Double(change![NSKeyValueChangeKey.newKey]! as! NSNumber)
            currentLocation["longitude"] = longitude as AnyObject?
        }
    }
    
    func updateUserLocation() {
        
        if currentLocation["latitude"] != nil && currentLocation["longitude"] != nil {
            
            geoFire.setLocation(CLLocation(latitude: (currentLocation["latitude"] as? CLLocationDegrees)!, longitude: (currentLocation["longitude"] as? CLLocationDegrees)!), forKey: iD)
            
            if UserService.ds.REF_USER_CURRENT != nil {
                let longRef = UserService.ds.REF_USER_CURRENT?.child("longitude")
                let latRef = UserService.ds.REF_USER_CURRENT?.child("latitude")
                
                longRef?.setValue(currentLocation["longitude"])
                latRef?.setValue(currentLocation["latitude"])
            }
            print(currentLocation)
        }
    }
    
    func terminateAuthentication() {
        
        do {
            try FIRAuth.auth()!.signOut()
            self.performSegue(withIdentifier: "unwindToLoginVC", sender: self)
        } catch let err as NSError {
            print(err)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        locationService.removeObserver(self, forKeyPath: "latitude", context: &latitude)
        locationService.removeObserver(self, forKeyPath: "longitude", context: &longitude)
    }
    
    @IBAction func recordBtnPressed(_ sender: AnyObject) {
        
        if audioRecorder == nil {
            
            startRecordingAnimations()

        } else if audioRecorder.isRecording {
            
            stopRecordingAnimationsAndSave()
            
        } else {
            
            updater.invalidate()
            audioRecorder = nil
            audioPlayer = nil
            audioSlider.isHidden = true
            startRecordingAnimations()
            linkObj["audio"] = nil
            self.recordBtnMidView.layer.borderWidth = 0
        }
    }
    
    func startRecordingAnimations() {
        
        playBtn.isHidden = true
        audioSlider.isHidden = true
        savedTimeLbl.isHidden = true
        restartBtn.isHidden = true
        tapBtnLbl.isHidden = true
        titleField.isHidden = true
        timeLbl.isHidden = false
        startRecording()
        pulsator.start()
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowAnimatedContent, animations: {
            
            self.recordBtnHeight.constant = 42
            self.recordBtnWidth.constant = 42
            self.recordBtn.frame.size.width = 42
            self.recordBtn.frame.size.height = 42
            self.recordBtn.layer.cornerRadius = 6
            
        }, completion: { finished in
                
        })
    }
    
    func stopRecordingAnimationsAndSave() {
        
        audioRecorder.stop()
        pulsator.stop()
        stopVideo()
        audioSlider.value = 0
        timeLbl.isHidden = true
        audioSlider.isHidden = false
        playBtn.isHidden = false
        restartBtn.isHidden = false
        savedTimeLbl.isHidden = false
        titleField.isHidden = false
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: audioRecorder.url)
            updateSliderWithAudio()
            audioPlayer?.delegate = self
            let dFormat = "%02d"
            let min: Int = Int((Double((audioPlayer?.duration)!) - (audioPlayer?.currentTime)!) / 60)
            let sec: Int = Int((Double((audioPlayer?.duration)!) - (audioPlayer?.currentTime)!).truncatingRemainder(dividingBy: 60.0))
            let string = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
            savedTimeLbl.text = string
        } catch let err as NSError {
            print(err.debugDescription)
        }

        if let audioURL = audioRecorder.url as NSURL? {
            let data = NSData(contentsOf: audioURL as URL)
            linkObj["audio"] = data
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowAnimatedContent, animations: {
            
            self.recordBtnHeight.constant = 69
            self.recordBtnWidth.constant = 69
            self.recordBtn.frame.size.width = 69
            self.recordBtn.frame.size.height = 69
            self.recordBtn.layer.cornerRadius = self.recordBtn.frame.size.width / 2
            self.recordBtnMidView.layer.borderColor = POWDER_BLUE.cgColor
            self.recordBtnMidView.layer.borderWidth = 2
            
        }, completion: { finished in
                
        })

    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {

        titleField.alpha = 1.0
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            titleField.alpha = 0.3
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if(string == "\n") {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func playerItemDidReachEnd(notification: NSNotification) {
        self.player?.seek(to: kCMTimeZero)
        self.player?.play()
    }

    func playVideo() {
    
        let path = Bundle.main.path(forResource: "wave", ofType: "mov")!
    
        let videoUrl = NSURL(fileURLWithPath: path)
        player = AVPlayer(url: videoUrl as URL)
        videoLayer = AVPlayerLayer(player: player)
        videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoLayer?.frame = audioWaveView.bounds
        videoLayer?.isHidden = false
        audioWaveView.layer.addSublayer(videoLayer!)
        player?.play()

    }
    
    func stopVideo() {
        player = nil
        videoLayer?.isHidden = true
    }
    
    func startRecording() {
        
        let uniqueString = NSUUID().uuidString
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(uniqueString).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            playVideo()
            Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(AudioPostVC.updateTimeLbl(timer:)), userInfo: nil, repeats: true)
            
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    @IBAction func restartBtnPressed(_ sender: AnyObject) {
        
        audioPlayer?.stop()
        let playImage = UIImage(named: "play-button")
        playBtn.setImage(playImage, for: .normal)
        updater.invalidate()
        audioSlider.value = 1
        recordBtn.isUserInteractionEnabled = true
        audioPlayer?.currentTime = 0
        updateDuration()
    }
    
    func updateTimeLbl(timer: Timer) {
        if audioRecorder == nil {
            return
        }
        if audioRecorder.isRecording {
            let dFormat = "%02d"
            let min: Int = Int(audioRecorder.currentTime / 60)
            let sec: Int = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60.0))
            let string = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
            timeLbl.text = string
        }
    }
    
    func updateDuration() {
        let dFormat = "%02d"
        let min: Int = Int((Double((audioPlayer?.duration)!) - (audioPlayer?.currentTime)!) / 60)
        let sec: Int = Int((Double((audioPlayer?.duration)!) - (audioPlayer?.currentTime)!).truncatingRemainder(dividingBy: 60.0))
        let string = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
        savedTimeLbl.text = string

    }
    
    func updateDurationLbl(timer: Timer) {
        if audioPlayer == nil {
            return
        }
        if (audioPlayer?.isPlaying)! {
            updateDuration()
        }
    }

    
    func trackAudio() {
        if audioPlayer != nil {
            let normalizedTime = Float((audioPlayer?.currentTime)! * 100.0 / (audioPlayer?.duration)!)
            audioSlider.value = normalizedTime
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    

    @IBAction func playbackAudioBtnPressed(_ sender: AnyObject) {
        
       if (audioPlayer?.isPlaying)! {
        
                recordBtn.isUserInteractionEnabled = true
                audioPlayer?.pause()
                let playImage = UIImage(named: "play-button")
                playBtn.setImage(playImage, for: .normal)
        } else if audioPlayer != nil && !(audioPlayer?.isPlaying)! {
        
            playAudio()
            updateSliderWithAudio()
            recordBtn.isUserInteractionEnabled = false
            Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(AudioPostVC.updateDurationLbl(timer:)), userInfo: nil, repeats: true)
        }

    }
    
    
    func playAudio() {
        audioPlayer?.play()
        let pauseImage = UIImage(named: "pause-button")
        playBtn.setImage(pauseImage, for: .normal)
    }
 
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        let playImage = UIImage(named: "play-button")
        playBtn.setImage(playImage, for: .normal)
        updater.invalidate()
        audioSlider.value = 1
        recordBtn.isUserInteractionEnabled = true
        updateDuration()

    }
    
    func updateSliderWithAudio() {
        updater = CADisplayLink(target: self, selector: #selector(AudioPostVC.trackAudio))
        updater.frameInterval = 1
        updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == AUDIO_POST_VC {
            if linkObj["audio"] == nil || audioRecorder.isRecording || (audioPlayer?.isPlaying)! || titleField.text == "" {
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if (segue.identifier == AUDIO_POST_VC) {
            
            if linkObj["audio"] != nil {
                linkObj["title"] = titleField.text as AnyObject?
                let nav = segue.destination as! UINavigationController;
                let categoryView = nav.topViewController as! CategoryVC
                categoryView.previousVC = AUDIO_POST_VC
                categoryView.linkObj = linkObj
            }
        }
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        dismissKeyboard()
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }
    
    @IBAction func unwindToAudioPost(_ segue: UIStoryboardSegue) {
        
    }

}
