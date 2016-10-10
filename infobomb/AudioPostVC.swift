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

class AudioPostVC: UIViewController, UITextViewDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var chooseCategoriesBtn: MaterialButton!
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var clickRecordLbl: UILabel!
    @IBOutlet weak var restartAndStopBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var audioSlider: UISlider!
    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var postTypeView: MaterialView!
    @IBOutlet weak var postTypeHeader: MaterialView!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var audioWaveView: VideoContainerView!
    
    var item: AVPlayerItem?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var updater: CADisplayLink! = nil
    var videoLayer: AVPlayerLayer?
    var player: AVPlayer?
    var audioPlayer: AVAudioPlayer?
    var audioURL = NSURL(string: "")
    var linkObj: [String:AnyObject] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        print("AudioPostVC")
        //Subclass navigation bar after app is finished and all other non DRY
        let image = UIImage(named: "metal-bg.jpg")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 15, 0, 15), resizingMode: UIImageResizingMode.stretch)
        self.title = "Audio"
        self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "TOSCA ZERO", size: 30)!,NSForegroundColorAttributeName: LIGHT_GREY]
        
        NotificationCenter.default.addObserver(self, selector: #selector(AudioPostVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AudioPostVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        
        postTypeView.separatorColor = UIColor.clear
        postTypeHeader.separatorColor = UIColor.clear
        hideButtons()
        audioSlider.minimumValue = 0
        audioSlider.maximumValue = 100
        audioSlider.isUserInteractionEnabled = false
        
        textField.delegate = self

        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AudioPostVC.dismissKeyboard))
        view.addGestureRecognizer(tap)

        applyPlaceholderStyle(aTextview: textField!, placeholderText: PLACEHOLDER_TEXT)

        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.recordBtn.isHidden = false
                    }
                }
            }
        } catch {
            print("Failed to Record")
        }


    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(AudioPostVC.playerItemDidReachEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
        func keyboardWillShow(_ notification: Notification) {
    
            if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                if view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                }
                else {
    
                }
            }
    
        }
    
        func keyboardWillHide(_ notification: Notification) {
            if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                if view.frame.origin.y != 0 {
                    self.view.frame.origin.y += keyboardSize.height
                }
                else {
                    
                }
            }
        }
    

    func playerItemDidReachEnd(notification: NSNotification) {
        self.player?.seek(to: kCMTimeZero)
        self.player?.play()
    }

   func  playVideo() {
    
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
    
    func applyPlaceholderStyle(aTextview: UITextView, placeholderText: String)
    {
        // make it look (initially) like a placeholder
        aTextview.textColor = UIColor.lightGray
        aTextview.text = placeholderText
        aTextview.textAlignment = .center
    }
    
    func applyNonPlaceholderStyle(aTextview: UITextView)
    {
        // make it look like normal text instead of a placeholder
        aTextview.textColor = UIColor.darkText
        aTextview.alpha = 1.0
        aTextview.textAlignment = .left
    }
    
    
    func textViewShouldBeginEditing(_ aTextView: UITextView) -> Bool {
        if aTextView == textField && aTextView.text == PLACEHOLDER_TEXT
        {
            // move cursor to start
            moveCursorToStart(aTextView: aTextView)
        }
        return true
    }
    
    func moveCursorToStart(aTextView: UITextView)
    {
        DispatchQueue.main.async {
            aTextView.selectedRange = NSMakeRange(0, 0);
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // remove the placeholder text when they start typing
        // first, see if the field is empty
        // if it's not empty, then the text should be black and not italic
        // BUT, we also need to remove the placeholder text if that's the only text
        // if it is empty, then the text should be the placeholder
        let newLength = textView.text.utf16.count + text.utf16.count - range.length
        if newLength > 0 // have text, so don't show the placeholder
        {
            // check if the only text is the placeholder and remove it if needed
            // unless they've hit the delete button with the placeholder displayed
            if textView == textField && textView.text == PLACEHOLDER_TEXT
            {
                if text.utf16.count == 0 // they hit the back button
                {
                    return false // ignore it
                }
                applyNonPlaceholderStyle(aTextview: textView)
                textField.text = ""
            }
            return true
        }
        else  // no text, so show the placeholder
        {
            applyPlaceholderStyle(aTextview: textView, placeholderText: PLACEHOLDER_TEXT)
            moveCursorToStart(aTextView: textView)
            return false
        }
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
            Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(AudioPostVC.updateTimeLbl(timer:)), userInfo: nil, repeats: true)
            
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    func updateTimeLbl(timer: Timer) {
        if audioRecorder == nil {
            return
        }
        if audioRecorder.isRecording {
            let dFormat = "%02d"
            let min:Int = Int(audioRecorder.currentTime / 60)
            let sec:Int = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60.0))
//            let milSec:Int = Int(Double(audioRecorder.currentTime * 1000).truncatingRemainder(dividingBy: 1000.0))
//            let milSecString = String(milSec)
//            let truncated = milSecString.substring(to: milSecString.index(before: milSecString.endIndex))
//            let milSecInt = Int((Double(truncated)! * 100).truncatingRemainder(dividingBy: 100.0))
            let string = "\(String(format: dFormat, min)).\(String(format: dFormat, sec))"
            timeLbl.text = string
        }
    }
    
    func resumeRecording() {
        audioRecorder.record()
    }
    
    func trackAudio() {
        let normalizedTime = Float((audioPlayer?.currentTime)! * 100.0 / (audioPlayer?.duration)!)
        audioSlider.value = normalizedTime
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
//        audioRecorder = nil
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    @IBAction func restartBtnPressed(_ sender: AnyObject) {
        if restartAndStopBtn.currentImage == UIImage(named: "stop") {
            audioPlayer?.stop()
            updater.invalidate()
            audioSlider.value = 1
            playBtn.isUserInteractionEnabled = true
            playBtn.alpha = 1
            recordBtn.isUserInteractionEnabled = true
            recordBtn.alpha = 1
            restartAndStopBtn.setImage(UIImage(named: "icon"), for: .normal)
        } else {
            audioURL = nil
            linkObj["audio"] = nil
            clickRecordLbl.isHidden = false
            audioRecorder = nil
            hideButtons()
            timeLbl.text = "00.00"
        }
    }
    
    @IBAction func playbackAudioBtnPressed(_ sender: AnyObject) {
        
        
                if audioRecorder != nil {
                    do {
                        audioRecorder.stop()
                        
                        updater = CADisplayLink(target: self, selector: #selector(AudioPostVC.trackAudio))
                        updater.frameInterval = 1
                        updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
                        
                       try audioPlayer = AVAudioPlayer(contentsOf: audioRecorder.url)
                        audioPlayer?.delegate = self

                        audioPlayer?.play()
                        recordBtn.isUserInteractionEnabled = false
                        recordBtn.alpha = 0.2
                        restartAndStopBtn.setImage(UIImage(named: "stop"), for: .normal)
                        playBtn.isUserInteractionEnabled = false
                        playBtn.alpha = 0.2
                    } catch let err as NSError {
                        print(err.debugDescription)
                    }
   
                } else {
                    print("Audio recorder is nil")
                }

    }
    
    @IBAction func recordBtn(_ sender: AnyObject) {
        
        if audioRecorder == nil {
            clickRecordLbl.isHidden = true
            startRecording()
            recordBtn.setImage(UIImage(named: "stop-recording"), for: .normal)
        } else if audioRecorder.isRecording {
            if let audioURL = audioRecorder.url as NSURL? {
                linkObj["audio"] = audioURL
            }
            chooseCategoriesBtn.isUserInteractionEnabled = true
            clickRecordLbl.isHidden = true
            pauseRecording()
            recordBtn.setImage(UIImage(named: "rec"), for: .normal)
            audioSlider.value = 1
            showButtons()
            stopVideo()
//            finishRecording(success: true)
        } else {
            clickRecordLbl.isHidden = true
            resumeRecording()
            chooseCategoriesBtn.isUserInteractionEnabled = false
            recordBtn.setImage(UIImage(named: "stop-recording"), for: .normal)
            playVideo()
            hideButtons()
        }
    }
    
    func showButtons() {
        audioSlider.isHidden = false
        playBtn.alpha = 1
        playBtn.isUserInteractionEnabled = true
        restartAndStopBtn.alpha = 1
        restartAndStopBtn.isUserInteractionEnabled = true
    }
    
    func hideButtons() {
        audioSlider.isHidden = true
        playBtn.alpha = 0.2
        playBtn.isUserInteractionEnabled = false
        restartAndStopBtn.alpha = 0.2
        restartAndStopBtn.isUserInteractionEnabled = false
    }
    
    func pauseRecording() {
        if audioRecorder != nil {
            audioRecorder.pause()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        restartAndStopBtn.setImage(UIImage(named: "icon"), for: .normal)
        playBtn.isUserInteractionEnabled = true
        updater.invalidate()
        audioSlider.value = 1
        playBtn.alpha = 1
        recordBtn.isUserInteractionEnabled = true
        recordBtn.alpha = 1

    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == AUDIO_POST_VC {
            if linkObj["audio"] == nil {
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
                let nav = segue.destination as! UINavigationController;
                let categoryView = nav.topViewController as! CategoryVC
                categoryView.previousVC = AUDIO_POST_VC
                categoryView.linkObj = linkObj
            }
        }
    }

    @IBAction func updateAudioSlider(_ sender: AnyObject) {
        
//        audioRecorder.currentTime =
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "unwindToNewPost", sender: self)
    }
    
    @IBAction func unwindToAudioPost(_ segue: UIStoryboardSegue) {
        
    }

}
