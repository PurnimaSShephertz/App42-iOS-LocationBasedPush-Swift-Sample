//
//  AppDelegate.swift
//  App42-iOS-LocationBasedPush-Swift-Sample
//
//  Created by Purnima on 01/02/17.
//  Copyright © 2017 Shephertz. All rights reserved.
//

import UIKit
import UserNotifications



let APP42_API_KEY = "41ea3db30eb74241885e75681e273ed5e25e95ca8eca32848ff8f8648fda883a"//"2e0ecddf17fbf026262ad5ca91d95be3d45e9021c5978889a07bf179f771ffd7"
let APP42_SECRET_KEY = "8b9d4f02444bf0939886d723a8ffaa03c98378e060c01ba0977607f8d43d1698"//"370a3eaa6fa139de5e5745771364cbeb566a56f5afdad3ecb925dcf178859f0d"

let App42_Base_URL = "https://api.shephertz.com"
let APP42_Analytics_URL = "https://analytics.shephertz.com"

//let viewController = ViewController()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        App42API.setLoggedInUser("iOSUser")
        App42API.initialize(withAPIKey: APP42_API_KEY, andSecretKey: APP42_SECRET_KEY)
        App42API.enableApp42Trace(true)
        App42API.enableEventService(true)
        //App42API.enableAppAliveTracking(true)
        App42API.setBaseUrl(App42_Base_URL)
        App42API.setEventBaseUrl(APP42_Analytics_URL)
//        App42CacheManager.shared().setPolicy(App42CachePolicy(rawValue: 1))
       // App42API.setOfflineStorage(true)
        
        self.registerPush()

        DispatchQueue.main.async {
            _ = App42PushManager.sharedManager
        }
        


        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        var token = ""
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        print("device token:- \(token)")
        //registerUserForPushNotificationToApp42Cloud(deviceToken: token);
        
        UserDefaults.standard.setValue(token, forKey: "DeviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("error: \(error)")
        
    }
    
    
    
    // MARK: Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("will present : =\(notification.request.content.userInfo)")

        completionHandler(.alert);
//        completionHandler(UNNotificationPresentationOptionAlert)
    }

    
    // MARK: receive local notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
//        print("notification json: \(response.notification)")
        
        print("APPDELEGATE: didReceiveResponseWithCompletionHandler \(response.notification.request.content.userInfo)")
//
//        let userDict : Dictionary = response.notification.request.content.userInfo
//        print("user dict: \(userDict)")
//        
//        let customData = userDict["aps"]
//        print("custom data: \(customData)")
        
        
        
        
        
        
//        let app42PushManager = App42PushManager()
        
//        app42PushManager.handleGeoBasedPush(userInfo: response.notification.request.content.userInfo as NSDictionary, completionHandlers: completionHandler)
        
        completionHandler()
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("did receive remote notification \(userInfo)")
    }
    
    
    // MARK: receive remote notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("did receive remote notification completionHandler ",userInfo);
        
        let userDict : Dictionary = userInfo
//        print("user dict: \(userDict)")
        
        let customData = userDict["aps"]
        print("custom data: \(customData!)")
        
        let app42PushManager = App42PushManager.sharedManager
        
        
        app42PushManager.handleGeoBasedPush(userInfo: userInfo as NSDictionary, completionHandlers: completionHandler)
        
        completionHandler(.newData)
    }
    
    

    private func registerPush() {
        UNUserNotificationCenter.current().delegate = self
        
        // request permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) {
            (granted, error) in
            if (granted) {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
}

