//
//  ViewController.swift
//  ToMorning-ximinz
//
//  Created by Ximin Zhang on 2015-11-06.
//  Copyright (c) 2015 CMPT275-04. All rights reserved.
//

import UIKit
import AVFoundation
import HealthKit
class AlarmViewController: UIViewController {
    
    var sleepDate=NSDate()
    var alarmDate=NSDate(timeInterval: -90, sinceDate: NSDate())
    let formatter=NSDateFormatter()
    var musicTitle = "Summer"
    var musicPlayer = AVPlayer()
    var audioPlayer = AVAudioPlayer()
    let message="Please Wear Your iWatch & Enjoy Your Sleep!"
    var healthManager:HealthManager = HealthManager()
    var enabled=false
    var timerforalarm:NSTimer?
    var timerforclock:NSTimer?
    var alarmactive = false
    
    @IBOutlet weak var heartbutton: UIButton!
    @IBOutlet weak var analogClockView: AnalogClock!
    @IBOutlet weak var alarmLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // setAlarm(segue:UIStoryboardSegue)
    // Input: segue object which included the data coming from alarm setup UI
    // Return: Null
    // Discription: This functions takes the user setting date and translate it into "HH:MM AM/
    //              PM" format. Also set the user's slected music as our system alarm music source
    /////////////////////////////////////////////////////////////////////////////////////////////
    @IBAction func setAlarm(segue:UIStoryboardSegue){
        let source = segue.sourceViewController as! SetUpAlarmViewController
        self.alarmactive = source.alarmisset
        if(alarmactive){
            alarmDate = source.returnselectedDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "HH"
            if(formatter.stringFromDate(alarmDate).toInt()!<12){
                formatter.dateFormat="HH:mm"
                alarmLabel.text=formatter.stringFromDate(alarmDate)+"AM"
            }
            else{
                formatter.dateFormat="HH"
                var hour=formatter.stringFromDate(alarmDate).toInt()!-12
                if(hour==0){
                    hour=12
                }
                formatter.dateFormat="mm"
                alarmLabel.text=String(hour)+":"+formatter.stringFromDate(alarmDate)+"PM"
            }
            //retreive and set alarmlabel
        
            musicTitle=source.selectedMusicTitle()
            var path = NSBundle.mainBundle().URLForResource(musicTitle, withExtension: "mp3")
            var error:NSError?
            audioPlayer = AVAudioPlayer(contentsOfURL: path!, error: &error)
            if(error==nil){
                audioPlayer.prepareToPlay()
            }
            //initial music player
        
            messageLabel.text=message
            //set message label
            
            formatter.dateFormat="ss"
            let tempsec = formatter.stringFromDate(alarmDate).toInt()!
            alarmDate=alarmDate.dateByAddingTimeInterval(Double(-tempsec))
            //set alarm date

            if(healthManager.ifhealthkitavailable()){
                NSTimer.scheduledTimerWithTimeInterval(1800, target: self, selector: "initheartrate", userInfo: nil, repeats: false)
                if(healthManager.getLatestHeartRateInHalfHour() != nil){
                    self.heartbutton.hidden = false
                }
            }
            analogClockView.setNeedsDisplay()
        }
    }
    

    
    func initheartrate(){
        healthManager.setInitHeartRate()
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if let destination = segue.destinationViewController as? ReportsViewController{
//            destination.healthManager=self.healthManager
//        }
//    }
    /////////////////////////////////////////////////////////////////////////////////////////////
    // viewDidLoad()
    // Input: Null
    // Return: Null
    // Discription: This function checks the triggerAlarm() every 1 seconds and update 
    //              renewAnalogClock() UI in a 60 seconds bases. Also pre-loading the alarm music
    //              source.
    /////////////////////////////////////////////////////////////////////////////////////////////
    @IBOutlet weak var setclockbutton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        healthManager.authorizeHealthKit()
        if(healthManager.ifhealthkitavailable()){
            healthManager.setInitHeartRate()
        }
        alarmLabel.text = "--:--"
        var path = NSBundle.mainBundle().URLForResource(musicTitle, withExtension: "mp3")
        var error:NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: path!, error: &error)
        audioPlayer.prepareToPlay()
        messageLabel.text=""
        heartbutton.hidden = true
        
        //print("here3")
    }
    
    @IBOutlet weak var backgroundimageview: UIImageView!
    
    override func viewDidAppear(animated: Bool) {
        timerforalarm = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "triggerAlarm", userInfo: nil, repeats: true)
        if(analogClockView.layer.sublayers.count  != 0){
            for view in analogClockView.layer.sublayers{
                view.removeFromSuperlayer()
            }
        }
        self.analogClockView.setNeedsDisplay()
        //timerforclock = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "renewAnalogClock", userInfo: nil, repeats: true)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        timerforalarm!.invalidate()
        timerforalarm=nil

    }
    
    
    
    @IBAction func settingAlarm(sender: AnyObject) {
        self.performSegueWithIdentifier("Settings", sender: self)
    }



    ////////////////////////////////////////////////////////////////////////////////////////////
    // triggerAlarm()
    // Input: Null
    // Return: Null
    // Discription: This function compares the date and time between user setting and current
    //              time. If they matched, it will trigger the preloaded alarm music.
    ///////////////////////////////////////////////////////////////////////////////////////////
    func triggerAlarm(){
        if(alarmactive){
            formatter.dateFormat="HH:mm"
            if(formatter.stringFromDate(NSDate())==formatter.stringFromDate(alarmDate)){
                triggerAlert()
                return
            }
            if(healthManager.ifhealthkitavailable()){
                let earliestdate=alarmDate.dateByAddingTimeInterval(-1800)
                if(NSDate().earlierDate(earliestdate) == earliestdate && NSDate().laterDate(alarmDate) == alarmDate){
                    //print("here")
                    if(shouldWakeUp()){
                        triggerAlert()
                    }
                }
            }
        }
    }
    ////////////////////////////////////////////////////////
    // renewAnalogClock()
    // Input: Null
    // Return: Null
    // Discription: Refresh the entire analogClock UI
    ////////////////////////////////////////////////////////
//    func renewAnalogClock(){
//        for view in analogClockView.layer.sublayers{
//            view.removeFromSuperlayer()
//        }
//        self.analogClockView.setNeedsDisplay()
//    }
    
    @IBAction func cancel(sender: AnyObject) {
        alarmDate = NSDate(timeInterval: -90, sinceDate: NSDate())
        messageLabel.text=""
        alarmLabel.text="--:--"
        alarmactive=false
        heartbutton.hidden = true
    }


    func shouldWakeUp()->Bool{
        if let currheartrate = healthManager.getLatestHeartRateInHalfHour(){
            if let initrate = healthManager.getinitheartrate(){
                let diff = currheartrate - initrate
                //print("calculating diff,diff is \(diff)")
                if((diff>(-7.0)) && (diff<7.0)){
                    return true
                }
            }
        }
        return false
        
    }
    
    func triggerAlert(){
        alarmactive=false
        
        let alertController = UIAlertController(title: "Light Sleep Detected", message: "Time To Wake Up", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action:UIAlertAction!) in
            self.alarmLabel.text="--:--"
            self.audioPlayer.stop()
            self.messageLabel.text=""
        }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion:nil)
        audioPlayer.play()
        alarmDate = NSDate(timeInterval: -90, sinceDate: NSDate())
        heartbutton.hidden = true
    }
}

