//
//  App42PushManager.swift
//  App42-iOS-LocationBasedPush-Swift-Sample
//
//  Created by Purnima on 01/02/17.
//  Copyright © 2017 Shephertz. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import CoreTelephony


let APP42_GEOBASE         =  "app42_geoBase"
let APP42_ADDRESSBASE     =  "addressBase"
let APP42_COORDINATEBASE  =  "coordinateBase"
let APP42_COUNTRYCODE     =  "app42_countryCode"
let APP42_COUNTRYNAME     =  "app42_countryName"
let APP42_STATENAME       =  "app42_stateName"
let APP42_CITYNAME        =  "app42_cityName"
let APP42_DISTANCE        =  "app42_distance"

let APP42_PUSH_MESSAGE    =  "app42_message"
let APP42_LONGITUDE       =  "app42_lng"
let APP42_LATITUDE        =  "app42_lat"
let APP42_LOC_IDENTIFIER  =  "APP42_LOC_IDENTIFIER"
let APP42_FENCEDETAILS    =  "app42_fencedetails"

/**
 * Keys for Geo-Fence push payload
 */
let APP42_GEOFENCEID      = "app42_geoFenceId"
let APP42_GEOFENCEDATA    =  "_App42GeoFenceData"
let APP42_ENTRY           =  "app42_entry"
let APP42_EXIT            =  "app42_exit"

/**
 * Keys for Geo-Fence entry-exit response keys
 */

let APP42_ISVALID  = "isValid"

/**
 * Keys for multi-location push payload
 */
let APP42_MAPLOCATION     =  "app42_mapLocation"
let APP42_LAT             =  "lat"
let APP42_LNG             =  "lng"
let APP42_RADIUS          =  "radius"

/**
 * Keys for push campaign
 */
let APP42_GEOCAMPAIGN            = "_App42GeoCampaign"
let APP42_CAMPAIGNNAME           = "_App42CampaignName"
let APP42_GEOFENCECOORDINATES    = "_App42GeoFenceCoordinates"
let APP42_GEOTARGETCOORDINATES   =  "_App42GeoTargetCoordinates"


enum App42PushType : Int{
    case kAPP42GEOCAMPAIGN
    case kAPP42GEONORMAL
    case kAPP42GEOFENCE
    case kAPP42NONE
}


enum App42GeoType : Int{
    case kAPP42COORDINATE
    case kAPP42ADDRESS
    case kAPP42GEONONE
}

//typealias completionHandlers = [(UIBackgroundFetchResult) -> Void]
//typealias App42FetchCompletion = [(UIBackgroundFetchResult) -> Void]

class App42PushManager: NSObject, CLLocationManagerDelegate {

    var completionHandlers: [(UIBackgroundFetchResult) -> Void] = []

    var locManager : CLLocationManager! = CLLocationManager()
    static let sharedManager = App42PushManager()
    

    var pushMessageDict : NSDictionary? = NSDictionary()
    var app42GeoCampaign : NSDictionary? = NSDictionary()
    var bgTaskIdList : NSMutableArray? = NSMutableArray()
    var lastTaskId = UIBackgroundTaskIdentifier()
    var pushType : App42PushType!
    var geoType : App42GeoType!
    
    
    override init() {
        super.init()
        
        pushType = App42PushType.init(rawValue: 0)
        geoType = App42GeoType.init(rawValue: 0)
        
        bgTaskIdList = NSMutableArray.init(capacity: 0)
        lastTaskId = UIBackgroundTaskInvalid

        requestToAccessLocation()

    }
    
    func requestToAccessLocation() {
        print(#function)
        
        if !(locManager != nil){
            print("Creating location manager")
            locManager = CLLocationManager()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                print("Location manager created!!!")
                self.locManager.delegate = self

                self.locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                self.locManager.distanceFilter = kCLDistanceFilterNone
                self.locManager.requestAlwaysAuthorization()

                if self.locManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)){
                    self.locManager.requestWhenInUseAuthorization()
                }
                
                if (UIDevice.current.systemVersion as NSString).floatValue >= 9{
                    self.locManager.allowsBackgroundLocationUpdates = true
                }

            }
        }
    }
    
    
    func handleGeoBasedPush(userInfo : NSDictionary, completionHandlers : @escaping(UIBackgroundFetchResult) -> Void) {
    
        print("userinfo---: %@", userInfo);
        
        var geoBaseType : String? = nil
        getCampaignType(userInfo: userInfo)
        
        if pushType == App42PushType.kAPP42GEOCAMPAIGN{
            let geoCampInfo : String = userInfo.object(forKey: APP42_GEOCAMPAIGN) as! String
            let geoCampInfoData = geoCampInfo.data(using: .utf8)
            
            do{
                let geoCampDict = try JSONSerialization.jsonObject(with: geoCampInfoData!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                app42GeoCampaign = geoCampDict
                geoBaseType = app42GeoCampaign?.object(forKey: APP42_GEOBASE) as? String
            }
            catch{
                print("JSON Processing Failed")
            }
        }
        else if pushType == App42PushType.kAPP42GEOFENCE{
            startGeoFenceMonitoring(fenceInfo: userInfo)
        }
        else{
            geoBaseType = userInfo.object(forKey: APP42_GEOBASE) as? String
        }
        
        if geoBaseType != nil{
            getGeoBaseType(geoBaseType: geoBaseType!)
        }
     
        if (geoBaseType != nil){
            pushMessageDict = userInfo
            
            if(geoBaseType == APP42_ADDRESSBASE){
                
                var pushCountry : String? = pushMessageDict?.object(forKey: APP42_COUNTRYCODE) as! String?
                pushCountry = pushCountry?.uppercased()
                pushCountry = pushCountry?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                var pushState : String? = pushMessageDict?.object(forKey: APP42_STATENAME) as! String?
                pushState = pushState?.uppercased()
                pushState = pushState?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                var pushCity : String? = pushMessageDict?.object(forKey: APP42_CITYNAME) as! String? 
                pushCity = pushCity?.uppercased()
                pushCity = pushCity?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if pushCountry == nil {
                    
                }
                else if pushState == nil || pushCity == nil {
                    
                    let isShowPushNotification = isCountryCodeExist(pushCountryCode: pushCountry!)
                    
                    if isShowPushNotification{
                        let pushMessage = pushMessageDict?.object(forKey: APP42_PUSH_MESSAGE) as! String
                        scheduleNotificationWithMessage(pushMessage: pushMessage)
                    }
                    
                }
                else{
                    
                    let test = beginNewBackgroundTask()
                    print("test : \(test)")
                    locManager.delegate = self
                    
                    
                    if !CLLocationManager.locationServicesEnabled() || CLLocationManager.authorizationStatus() == .denied{
                        
                    }else{
                        locManager.startUpdatingLocation()
                    }
                    
                }
                
            }
            else{
             
                let test = beginNewBackgroundTask()
                print("test : \(test)")
                locManager.delegate = self
                
                
                if !CLLocationManager.locationServicesEnabled() || CLLocationManager.authorizationStatus() == .denied{
                    
                }else{
                    locManager.startUpdatingLocation()
                }
                
            }
            
            
            
        }
    }
    
   
    func getCampaignType(userInfo : NSDictionary) {
        
        let geoCampInfo = userInfo.object(forKey: APP42_GEOCAMPAIGN)
        let geoFenceInfo = userInfo.object(forKey: APP42_GEOFENCECOORDINATES)
        
        if (geoCampInfo != nil){
            pushType = App42PushType.kAPP42GEOCAMPAIGN
        }
        else if (geoFenceInfo != nil){
            pushType = App42PushType.kAPP42GEOFENCE
        }
        else{
            pushType = App42PushType.kAPP42GEONORMAL
        }
        
    }
    
    
    func getGeoBaseType(geoBaseType : String) {
        
        if geoBaseType == APP42_COORDINATEBASE{
            geoType = App42GeoType.kAPP42COORDINATE
        }
        else if geoBaseType == APP42_ADDRESSBASE{
            geoType = App42GeoType.kAPP42ADDRESS
        }
        else{
            geoType = App42GeoType.kAPP42GEONONE
        }
    }
    
    func startGeoFenceMonitoring(fenceInfo : NSDictionary) {
        
        let fenceCoordinatesStr = fenceInfo.object(forKey: APP42_GEOFENCECOORDINATES)
//        print("fence coordinates str class type: \(object_getClass(fenceCoordinatesStr)) \n str: \(fenceCoordinatesStr)")
        let fenceStr = fenceCoordinatesStr as! String
        let fenceCoordinateStrData = fenceStr.data(using: .utf8)
        var fetchCoordinates : Array<Any>!
        do{
            fetchCoordinates = try JSONSerialization.jsonObject(with: fenceCoordinateStrData!, options: []) as! Array
            
        }
        catch{
            
        }
        
//        print("fence co: \(fetchCoordinates)")
        
        let fenceDataStr : String = fenceInfo.object(forKey: APP42_GEOFENCEDATA) as! String
        var fenceData : NSDictionary = NSDictionary()
        do{
            fenceData = try JSONSerialization.jsonObject(with: fenceDataStr.data(using: .utf8)!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
        }
        catch{
            
        }
        
//        print("fence data: \(fenceData)")
        
        for i in 0 ..< fetchCoordinates.count{
            var center = CLLocationCoordinate2D()
            
            if let corDict = fetchCoordinates[i] as? [String : AnyObject]{
                
                center.latitude = corDict[APP42_LATITUDE] as! CLLocationDegrees
                center.longitude = corDict[APP42_LONGITUDE] as! CLLocationDegrees
                
                var radius = CLLocationDistance()
                radius = corDict[APP42_DISTANCE] as! CLLocationDistance * 1000
                
//                print("fence id---- \(corDict[APP42_GEOFENCEID])")
                let fenceId = "\(fenceData.object(forKey: APP42_CAMPAIGNNAME)!)$$$\(corDict[APP42_GEOFENCEID]!)"
                
                
                // Initialize Region to Monitor
                let region = CLCircularRegion(center: center, radius: radius, identifier: fenceId)
                region.notifyOnEntry = fenceData[APP42_ENTRY] as! Bool
                region.notifyOnExit = fenceData[APP42_EXIT] as! Bool
                
                
                //Save fence data for future use
                addFenceDetails(campaignName: fenceData.object(forKey: APP42_CAMPAIGNNAME)! as! String, forFence: fenceId)
                
                // Start Monitoring Region
                locManager.startMonitoring(for: region)
                print("end")

            }
            
        }
        
    }
    
    
    
    func stopMonitoringForFenceWithID(regi : CLRegion) {
        
    }
  
    
    func addFenceDetails(campaignName : String, forFence fenceId : String) {
        
//        print("campaign name: \(campaignName), fenceid: \(fenceId)")
        
        if var fenceDetails : NSMutableDictionary = UserDefaults.standard.object(forKey: APP42_FENCEDETAILS) as? NSMutableDictionary{
            
            fenceDetails = fenceDetails.mutableCopy() as! NSMutableDictionary
//            print("fenceDetails: \(fenceDetails)")
            
            if fenceDetails.count != 0 {
                fenceDetails.setValue(campaignName, forKey: fenceId)
                UserDefaults.standard.set(fenceDetails, forKey: APP42_FENCEDETAILS)
            }
            else {
                let fenceDeatilsDict = NSDictionary.init(object: campaignName, forKey: fenceId as NSCopying);
                UserDefaults.standard.set(fenceDeatilsDict, forKey: APP42_FENCEDETAILS)
            }
        }else{
            let fenceDeatilsDict = NSDictionary.init(object: campaignName, forKey: fenceId as NSCopying);
            UserDefaults.standard.set(fenceDeatilsDict, forKey: APP42_FENCEDETAILS)
        }
        
    }
    
    func getFenceDetails(fenceId : String) -> String {
        let fenceDetails = UserDefaults.standard.object(forKey: APP42_FENCEDETAILS) as! NSMutableDictionary
        return fenceDetails.object(forKey: fenceId) as! String
    }
    
    
    func startShowingNotifications() {
        
    }
    
    
    
    // MARK: Location Manager Delegates
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedAlways {
            print(#function)
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    // do stuff
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(".....didUpdateLocations called")
        locManager.stopUpdatingLocation()
        locManager.delegate = nil
        let newLoaction : CLLocation = locations.last!
        
        if geoType == App42GeoType.kAPP42COORDINATE{
            
            if isEligibleForNotificationWithCoordinate(newLoaction: newLoaction){
                print("..... in the region")
                scheduleNotificationWithMessage(pushMessage: pushMessageDict?.object(forKey: APP42_PUSH_MESSAGE) as! String)
            }
            else{
                print(".....Not in the region")
            }
            
            endAllBackgroundTasks()
        }
        else if geoType == App42GeoType.kAPP42ADDRESS{
            showNotificationIfEligibleWithAddress(newLocation: newLoaction)
        }
        else{
            endAllBackgroundTasks()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print(#function)
        locManager.stopUpdatingLocation()
        locManager.delegate = nil
        endAllBackgroundTasks()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        print(#function)
        
        scheduleNotificationWithMessage(pushMessage: "Entered the region...\(region.identifier)")
        sendGeoFencingPush(region: region, forEvent: "entry")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print(#function)
        scheduleNotificationWithMessage(pushMessage: "Exiting the region...\(region.identifier)")
        sendGeoFencingPush(region: region, forEvent: "exit")
    }
    
    
    
    func sendGeoFencingPush(region : CLRegion, forEvent event : String) {
        let campaignName = getFenceDetails(fenceId: region.identifier)
        let fenceId = region.identifier.components(separatedBy: "$$$").last
        
        let eventService = App42API.buildEventService() as? EventService
        let geoProps = NSDictionary.init()// NSMutableDictionary.init(objects: fenceId, campaignName, event, forKeys: "CamaignName", "FenceId", "Event")
        geoProps.setValue(fenceId, forKey: "campaignName")
        geoProps.setValue(campaignName, forKey: "campaignName")
        geoProps.setValue(event, forKey: "event")
        
        let dict : NSDictionary? = [:]
        
        let userData = geoProps as NSDictionary? as? [AnyHashable: Any] ?? [:]
        
        
        //-(void)sendGeoFencingPush:(NSDictionary*)userProps geoProps:(NSDictionary*)geoProps completionBlock:(App42ResponseBlock)completionBlock
        
        eventService?.sendGeoFencingPush(dict as! [AnyHashable : Any]! , geoProps: userData, completionBlock: { (suceess, responseObj, exception) in
            
            if suceess{
                print("Fence tracked successfully")
                let isValid = self.isFenceValid(responseDict: responseObj ?? "")
                if !isValid{
                    print("Invalid Fence...stopping it")
                    self.locManager.stopMonitoring(for: region)
                }
            }
            else{
                print("Exception: \(exception?.reason)")
            }
        })
        
    }

    
    
    
    func isFenceValid(responseDict : Any) -> Bool {
        var isValid = false
        let app42Response = responseDict as! App42Response
        do{
            let response = try JSONSerialization.jsonObject(with: app42Response.strResponse.data(using: .utf8)!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            var res = response.object(forKey: "app42") as! NSDictionary
            res = res.object(forKey: "response") as! NSDictionary

            isValid = res.object(forKey: "APP42_ISVALID") as! Bool
            
            return isValid
        }catch{
            print("error")
        }
    
        return isValid
    }
    
    
    // MARK: -- Others
    func isApp42GeoBasedPush(userInfo : NSDictionary) -> Bool {
        
        var isGeoBasedPush = false
        let geoBaseType = userInfo.object(forKey: APP42_GEOBASE)
        
        if geoBaseType != nil{
            isGeoBasedPush = true
        }
        return isGeoBasedPush
    }
    
    func isEligibleForNotificationWithCoordinate(newLoaction : CLLocation) -> Bool {
        
        var isInTheRegion = false
        var multiLocations : String? = nil
        var regions : [Any] = []
        
        if pushType == App42PushType.kAPP42GEOCAMPAIGN{
            regions = app42GeoCampaign?.object(forKey: APP42_GEOTARGETCOORDINATES) as! Array
        }
        else{
            multiLocations = pushMessageDict?.object(forKey: APP42_MAPLOCATION) as! String?
            if multiLocations != nil{
                
                
                if let data = multiLocations!.data(using: String.Encoding.utf8) {
                    do {
                        regions = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! Array
                        print("regions: \(regions)")
                    } catch {
                        print("error.localozed:")
                    }
                }
            }
        }
        
        var i = 0;
        if !regions.isEmpty{
            
            
            while i < regions.count {
                
                let regionCoordinates : [String : Double] = regions[i] as! [String : Double]
                
                var center = CLLocationCoordinate2D()


                if((regionCoordinates[APP42_LNG]) != nil){
                    center.latitude = regionCoordinates[APP42_LAT]!
                    center.longitude = regionCoordinates[APP42_LNG]!
                }
                else{
                    center.latitude = regionCoordinates[APP42_LATITUDE]!
                    center.longitude = regionCoordinates[APP42_LONGITUDE]!
                }
                
                var radius : CLLocationDistance!// = regionCoordinates[APP42_RADIUS]! * 1000
                
                if pushType == App42PushType.kAPP42GEOCAMPAIGN{
                    radius = regionCoordinates[APP42_DISTANCE]! * 1000
                }
                else{
                    radius = regionCoordinates[APP42_RADIUS]! * 1000
                }
                
                let region = CLCircularRegion.init(center: center, radius: radius, identifier: "App42Fence")
                isInTheRegion = region.contains(newLoaction.coordinate)
                
                if isInTheRegion{
                    break;
                }
                
                i += 1
            }
        }
        else if pushType == App42PushType.kAPP42GEOCAMPAIGN{
            var center = CLLocationCoordinate2D()
            center.longitude = (app42GeoCampaign?.object(forKey: APP42_LONGITUDE) as! NSString).doubleValue
            center.latitude = (app42GeoCampaign?.object(forKey: APP42_LATITUDE) as! NSString).doubleValue
            
            var radius = CLLocationDistance()
            radius = (app42GeoCampaign?.object(forKey: APP42_DISTANCE) as! NSString).doubleValue * 1000
            
            let region = CLCircularRegion.init(center: center, radius: radius, identifier: "App42Fence")
            isInTheRegion = region.contains(newLoaction.coordinate)
        }
        else{
            var center = CLLocationCoordinate2D()
            
            center.longitude = (pushMessageDict?.object(forKey: APP42_LONGITUDE) as! NSString).doubleValue
            center.latitude = (pushMessageDict?.object(forKey: APP42_LATITUDE) as! NSString).doubleValue
            
            var radius = CLLocationDistance()
            radius = (pushMessageDict?.object(forKey: APP42_DISTANCE) as! NSString).doubleValue * 1000
            
            let region = CLCircularRegion.init(center: center, radius: radius, identifier: "App42Fence")
            isInTheRegion = region.contains(newLoaction.coordinate);
        }
        
        return isInTheRegion
    }
    
    func getValueOfRegions(dictionary:[String:Double],key:String)-> Double?{
        return dictionary[key]!
    }
    
  
    func showNotificationIfEligibleWithAddress(newLocation : CLLocation) {
        
        let geoCoder : CLGeocoder = CLGeocoder()
        
        
        geoCoder.reverseGeocodeLocation(newLocation, completionHandler: { placemarks, error in
            
            let placemark1 = placemarks?.last
            print("country name: \(placemark1?.country) \n city name: \(placemark1?.locality)")
            
            
            if error == nil && (placemarks?.count)! > 0{
                
                var isEligible = false
                let placemark = placemarks?.last
                
                
                let state : String? = placemark?.administrativeArea?.uppercased()
//                let countryName = placemark?.country?.uppercased()
                let countryCode = placemark?.isoCountryCode?.uppercased()
                let city = placemark?.locality?.uppercased()
                
                print("self.pushMessageDict: \(self.pushMessageDict)")
                
                var stateForPush : String? = self.pushMessageDict?.object(forKey: APP42_STATENAME) as? String
                stateForPush = stateForPush!.uppercased()
                //Crashed
//                var countryNameForPush : String? = self.pushMessageDict?.object(forKey: APP42_COUNTRYNAME) as? String
//                print("countryNameForPush: \(countryNameForPush)")
//                countryNameForPush = countryNameForPush!.uppercased()
                
                var countryCodeForPush : String? = self.pushMessageDict?.object(forKey: APP42_COUNTRYCODE) as? String
                print("countryCodeForPush: \(countryCodeForPush)")
                countryCodeForPush = countryCodeForPush!.uppercased()
                
                var cityForPush : String? = self.pushMessageDict?.object(forKey: APP42_CITYNAME) as? String
                print("cityForPush: \(cityForPush)")
                cityForPush = cityForPush!.uppercased()
                
                if ((countryCodeForPush != nil) && (countryCodeForPush == countryCode)){
                   
                    if stateForPush != nil && (stateForPush == state){
                        
                        if cityForPush != nil && (cityForPush == city){
                            isEligible = true
                        }
                        else if !(cityForPush != nil){
                            isEligible = true
                        }
                    }
                    else if !(stateForPush != nil){
                        isEligible = true
                    }
                }
                
                
                if (isEligible)
                {
                    self.scheduleNotificationWithMessage(pushMessage: self.pushMessageDict?.object(forKey: APP42_PUSH_MESSAGE) as! String)
                }
                else
                {
                    NSLog("\(#function).....Not in the region");
                }
                
            }
            else{
                print("error: \(error.debugDescription)")
            }
            self.endAllBackgroundTasks()
            
        })
        
    }
    
    
    func scheduleNotificationWithMessage(pushMessage : String) {
        
        print(#function)
        
        let localNotificationContent = UNMutableNotificationContent()
        localNotificationContent.body = pushMessage
        localNotificationContent.sound = UNNotificationSound.default()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "localNotification.", content: localNotificationContent, trigger: trigger)
        
        // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if (error != nil){
                print("error: \(String(describing: error?.localizedDescription))")

            }else{
                print("added NotificationRequest suceessfully!")
            }
        }
    }
    
    func scheduleLocationBasedNotification(pushMessage: String, lat : CLLocationDegrees, long : CLLocationDegrees, radius : CLLocationDistance) {
        print(#function)
        
        let locArea = CLLocationCoordinate2DMake(lat, long)
        let locRegion = CLCircularRegion.init(center: locArea, radius: radius, identifier: pushMessage)
        locRegion.notifyOnExit = true
        locRegion.notifyOnEntry = true
        
        let localNotificationTrigger = UNLocationNotificationTrigger.init(region: locRegion, repeats: false)
        
        
        let localNotificationContent = UNMutableNotificationContent()
        localNotificationContent.body = pushMessage
        localNotificationContent.sound = UNNotificationSound.default()
        
        let notificationRequest = UNNotificationRequest(identifier: "one", content: localNotificationContent, trigger: localNotificationTrigger)
        
        let scheduleNoti = UNUserNotificationCenter.current()
        scheduleNoti.add(notificationRequest) { (error) in
            if (error != nil){
                print("added location based NotificationRequest suceessfully!")
            }else{
                print("error: \(String(describing: error))")
            }
        }
        
//        CLLocationCoordinate2D officeArea = CLLocationCoordinate2DMake(12.970540,80.251060);
//        CLCircularRegion* officeRegion = [[CLCircularRegion alloc] initWithCenter:officeArea
//            radius:10 identifier:@"My Office Bay"];
//        
//        officeRegion.notifyOnEntry = YES;
//        officeRegion.notifyOnExit = YES;
//        UNLocationNotificationTrigger* locationTrigger = [UNLocationNotificationTrigger
//        triggerWithRegion:officeRegion repeats:YES];
        
        
        
        
//        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"com.mcoe.notificationcategory.timerbased"
//        
//        content:notificationcontent trigger:timerbasedtrigger];
//        
//        [_notiCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//        
//        if (!error) {
//        
//        NSLog(@"added timer based NotificationRequest suceessfully!");
//        }
//        }];
        
    }

    
    // MARK:- ------Background task management------
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
        
        let application = UIApplication.shared
        if application.applicationState != UIApplicationState.background{
            return UIBackgroundTaskInvalid
        }
        
        var bgTaskId : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        
        if application.responds(to: #selector(application.beginBackgroundTask(expirationHandler:))){
            
            bgTaskId = application.beginBackgroundTask(expirationHandler: { 
                print("background task \(bgTaskId) expired")
            })
            
            if lastTaskId == UIBackgroundTaskInvalid{
                lastTaskId = bgTaskId
                print("started master task \(lastTaskId)")
            }
            else{
                print("started background task \(bgTaskId)")
                bgTaskIdList?.add(bgTaskId)
                print("bgTaskIdList = \(bgTaskIdList)")
                endBackgroundTasks()
            }
        }
        return bgTaskId
    }
    
    
    func endBackgroundTasks() {
        endBGTasksFromList(isEndAll: false)
    }
    
    func endAllBackgroundTasks() {
     
        endBGTasksFromList(isEndAll: true)
    }

    
    func endBGTasksFromList(isEndAll : Bool) {
        
        //mark end of each of our background task
        let application = UIApplication.shared
        
        let count = bgTaskIdList!.count
        
        for i in (isEndAll ? 0 : 1) ..< count {
            let bgTaskId = bgTaskIdList?.object(at: i) as! UIBackgroundTaskIdentifier
            print("ending background task with id \(bgTaskId)")
            application.endBackgroundTask(bgTaskId)
            bgTaskIdList?.remove(0)
        }
        
        if (bgTaskIdList?.count)! > 0 {
            print("kept background task id \(bgTaskIdList?.object(at: 0))")
        }
        
        if isEndAll{
            print("no more background tasks running")
            application.endBackgroundTask(lastTaskId)
            lastTaskId = UIBackgroundTaskInvalid
        }
        else{
            print("kept master background task id \(lastTaskId)")
        }
    }
    
    
    func isCountryCodeExist(pushCountryCode : String) -> Bool {
        var isValid = false
        
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        var userCountryCode : String? = carrier?.isoCountryCode
        userCountryCode = userCountryCode?.uppercased()
        
        if userCountryCode != nil && userCountryCode == pushCountryCode {
            isValid = true
        }
        
        return isValid
    }

}
