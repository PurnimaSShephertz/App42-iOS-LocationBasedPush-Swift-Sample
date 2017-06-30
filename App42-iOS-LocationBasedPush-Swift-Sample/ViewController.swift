//
//  ViewController.swift
//  App42-iOS-LocationBasedPush-Swift-Sample
//
//  Created by Purnima on 01/02/17.
//  Copyright © 2017 Shephertz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var responseTextView: UITextView!
    var docIDArray : NSMutableArray!
    var storageService = App42API.buildStorageService()
    var userName = ""
    var deviceToken = ""
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.usernameTextField.text = ""
        
        
        App42CampaignAPI.setConfigCacheTime(0)
        
        let inAppListner = InAppListener.init(viewController: self)
        App42CampaignAPI.initWith(inAppListner)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //     7a1c0598e5ea37866cff39b78a8fe60d732971dbß
    
    
    @IBAction func sendPushButtonClick(_ sender: Any) {
        
        if (self.usernameTextField.text != nil) {
            let eventservice : EventService = App42API.buildEventService() as! EventService
            eventservice.trackEvent(withName: self.usernameTextField.text, andProperties: Dictionary.init()) { (success, responseObj, exception) in
            
                let app42response = responseObj as! App42Response
                print("app42 response: \(app42response.isResponseSuccess)")
            }
        }
        
        
//        let dict = ["name" : "abcd"]
//        let eventservice : EventService = App42API.buildEventService() as! EventService
//        eventservice.trackEvent(withName: "FEEDBACK_CLICKED", andProperties: dict) { (success, responseObj, exception) in
//            
//            let app42response = responseObj as! App42Response
//            print("app42 response: \(app42response.isResponseSuccess)")
//        }
        
        
        
        
        
        
//        if(self.usernameTextField.isFirstResponder){
//            self.usernameTextField.resignFirstResponder()
//        }
//        
//        self.userName = self.usernameTextField.text!
//        self.userName = self.userName.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines)
//        self.userName = self.userName.replacingOccurrences(of: " ", with: "")
//        
//        if (userName.characters.count > 0){
//            self.sendPush(message: "Hello, Ur Friend has poked you!", _userName: userName)
//        }
//        else{
//            let alertController = UIAlertController(title: "Error", message: "Please, enter the user name", preferredStyle: UIAlertControllerStyle.alert)
//            
//            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){
//                (result : UIAlertAction) -> Void in
//                print("You pressed OK")
//            }
//            alertController.addAction(okAction)
//            self.present(alertController, animated: true, completion: nil)
//        }
    }

    @IBAction func registerDeviceButtonClick(_ sender: Any) {
        
        deviceToken = UserDefaults.standard.value(forKey: "DeviceToken") as! String

        
        if(self.usernameTextField.isFirstResponder){
            self.usernameTextField.resignFirstResponder()
        }
        
        
        self.userName = self.usernameTextField.text!
        self.userName = self.userName.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines)
        self.userName = self.userName.replacingOccurrences(of: " ", with: "")
        
        if self.userName.characters.count > 0 {
            //App42API.setLoggedInUser(userName)
            /***
             * Registering Device Token to App42 Cloud API
             */
            
            let pushObj : PushNotificationService = App42API.buildPushService() as! PushNotificationService
            pushObj.registerDeviceToken(self.deviceToken, withUser: App42API.getLoggedInUser(), completionBlock: { (success, responseObj, exception) in
                if success{
                    let push = responseObj as! PushNotification
                    self.responseTextView.text = push.strResponse
                }
                else{
                    self.responseTextView.text = exception?.reason
                    print("reason:-- \(exception?.reason)")
                }
            })
        }
        else{
            
            let alertController = UIAlertController(title: "Error", message: "Please, enter the user name", preferredStyle: UIAlertControllerStyle.alert)

            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                print("You pressed OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func unregisterButtonClick(_ sender: Any) {
        UIApplication.shared.unregisterForRemoteNotifications()
    }
    
    
    func sendPush(message : String, _userName toUser:String) {
        
        let dict = ["alert" : message, "sound" : "default", "badge" : "1"]
        
        let pushObj = App42API.buildPushService() as! PushNotificationService
        pushObj.sendPushMessage(toUser: toUser, withMessageDictionary: dict) { (success, responseObj, error) in
            
            if success{
                let push = responseObj as! PushNotification
                self.responseTextView.text = push.strResponse
            }
            else{
                self.responseTextView.text = error?.reason
                print("reason:-- \(error?.reason)")
            }
        }
        
    }
    
}

