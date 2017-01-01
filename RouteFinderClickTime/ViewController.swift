//
//  ViewController.swift
//  FindRouteClickTime
//
//  Created by Samuel Chu on 12/30/16.
//  Copyright © 2016 Samuel Chu. All rights reserved.
//


import SwiftyJSON
import UIKit
import GoogleMaps
import GooglePlaces





protocol directionsTableViewControllerDelegate{
    func addDirections(directions : [String])
}

//clicktime : 37.785644, -122.397120
extension String {
    var html2AttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}


class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate{
    
    @IBOutlet weak var shopAddress: UITextField!
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    var tableDelegate : directionsTableViewControllerDelegate!
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if currentLocation != nil{
            return
        }
        if let location = locations.first {
            currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func getURL(mode : String, lat : Double, long : Double) -> URL{
        if(shopAddress.text == ""){
            return URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(lat),\(long)&destination=37.785644,-122.397120&mode=\(mode)&key=AIzaSyDSNeYvyIef7ddRoRdE5s2l1Noif4TsQjU")!
        }
        
        let address = shopAddress.text!.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
        print(address)
        return URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(lat),\(long)&destination=37.785644,-122.397120&mode=\(mode)&waypoints=\(address)&key=AIzaSyDSNeYvyIef7ddRoRdE5s2l1Noif4TsQjU")!
    }
    
    func getURLsTransit(lat: Double, long: Double) -> [URL]{
        var urls : [URL] = []
        
        let address = shopAddress.text!.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
        
        urls += [URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(lat),\(long)&destination=\(address)&mode=transit&key=AIzaSyDSNeYvyIef7ddRoRdE5s2l1Noif4TsQjU")!]
        urls += [URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(address)&destination=37.785644,-122.397120&mode=transit&key=AIzaSyDSNeYvyIef7ddRoRdE5s2l1Noif4TsQjU")!]
        
        return urls
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        locationManager.requestAlwaysAuthorization()
        
        locationManager.requestLocation()
        // Do any additional setup after loading the view, typically from a nib.
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        self.shopAddress.delegate = self
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDirectionsTransit(queryResults:JSON) -> [String] {
        var directions : [String] = []
        let legs = queryResults["routes"][0]["legs"].arrayValue
        
        for step in legs[0]["steps"].arrayValue{
            let direction = step["html_instructions"].stringValue.html2String
            let distance = step["distance"]["text"].stringValue
            
            if step["transit_details"].exists(){
                var transitName = step["transit_details"]["line"]["short_name"].stringValue
                if(transitName == "") {transitName = step["transit_details"]["line"]["name"].stringValue}
                directions += ["\(direction)\n\tTake the \(transitName) - \(distance)\n"]
            }
            else{
                directions += ["\(direction)\n\t\(distance)\n"]
            }
        }
        return directions
        
    }
    
    //must do separately because no more than two waypoints can be used in transit queries
    func populateDirectionsTableTransit(){
        
        let lat = (currentLocation?.coordinate.latitude)! as Double
        let long = (currentLocation?.coordinate.longitude)! as Double
        
        let queryURLs = getURLsTransit(lat: lat, long: long)
        print(queryURLs)
        let task = URLSession.shared.dataTask(with: queryURLs[0], completionHandler: {(data, HTTPStatusCode, error) -> Void in
            let statusCode = (HTTPStatusCode as! HTTPURLResponse).statusCode
            if statusCode == 200 && error == nil {
                
                let queryResults = JSON(data: data!)
                
                let legs = queryResults["routes"][0]["legs"][0]
                let distance = legs["distance"]["text"].stringValue
                let duration = legs["duration"]["text"].stringValue
                
                
                var directions : [String] = ["Directions to coffee/donut shop:\n\tDistance: \(distance), Duration: \(duration)"]
                directions += self.getDirectionsTransit(queryResults: queryResults)
                
                let task = URLSession.shared.dataTask(with: queryURLs[1], completionHandler: {(data, HTTPStatusCode, error) -> Void in
                    let statusCode = (HTTPStatusCode as! HTTPURLResponse).statusCode
                    if statusCode == 200 && error == nil {
                        
                        
                        let queryResults = JSON(data: data!)
                        
                        let legs = queryResults["routes"][0]["legs"][0]
                        let distance = legs["distance"]["text"].stringValue
                        let duration = legs["duration"]["text"].stringValue

                        directions += ["", "Directions from coffee/donut shop to ClickTime office:\n\tDistance: \(distance), Duration: \(duration)"]
                        directions += self.getDirectionsTransit(queryResults: queryResults)
                        self.tableDelegate.addDirections(directions: directions)
                    }
                        
                    else {
                        print("Error with query")
                    }
                    
                })
                
                task.resume()
                
                
            }
                
            else {
                print("Error with query")
            }
            
        })
        
        task.resume()
        
        
        
        
    }
    
    func populateDirectionsTable(mode : String){
        
        //example query : https://maps.googleapis.com/maps/api/directions/json?origin=34.4374304311671,-119.89460273657&destination=37.785644,-122.397120&mode=bicycling&waypoints=6530%20Seville%20Rd%20Isla%20Vista%20CA%2093117&key=AIzaSyDSNeYvyIef7ddRoRdE5s2l1Noif4TsQjU
        
        //viewed results in json viewer to find directions
        
        
        let lat = (currentLocation?.coordinate.latitude)! as Double
        let long = (currentLocation?.coordinate.longitude)! as Double
        
        let queryURL = getURL(mode: mode, lat: lat, long: long)
        print(queryURL)
        
        let task = URLSession.shared.dataTask(with: queryURL, completionHandler: {(data, HTTPStatusCode, error) -> Void in
            let statusCode = (HTTPStatusCode as! HTTPURLResponse).statusCode
            if statusCode == 200 && error == nil {
                
                
                let queryResults = JSON(data: data!)
                let legs = queryResults["routes"][0]["legs"].arrayValue
                var directions : [String] = ["Directions to coffee/donut shop:\n\tDistance: \(legs[0]["distance"]["text"].stringValue), Duration: \(legs[0]["duration"]["text"].stringValue)"]
                
                
                for step in legs[0]["steps"].arrayValue{
                    let direction = step["html_instructions"].stringValue.html2String
                    let distance = step["distance"]["text"].stringValue
                    directions += ["\(direction)\n\tContinue for \(distance)\n"]
                }
                
                directions += ["", "Directions from coffee/donut shop to ClickTime office:\n\tDistance: \(legs[1]["distance"]["text"].stringValue), Duration: \(legs[1]["duration"]["text"].stringValue)"]
                
                
                for step in legs[1]["steps"].arrayValue{
                    let direction = step["html_instructions"].stringValue.html2String
                    let distance = step["distance"]["text"].stringValue
                    directions += ["\(direction)\n\tContinue for \(distance)\n"]
                }
                
                self.tableDelegate.addDirections(directions: directions)
            }
                
            else {
                print("Error with query")
            }
            
        })
        
        task.resume()
    }
    
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if (shopAddress.text == "") {return false}
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        tableDelegate = segue.destination as! directionsTableViewControllerDelegate
        
        
        if segue.identifier == "WalkingSegue" {
            populateDirectionsTable(mode: "walking")
            
        }
            
        else if segue.identifier == "BikingSegue" {
            populateDirectionsTable(mode: "bicycling")
        }
            
        else if segue.identifier == "TransitSegue" {
            populateDirectionsTableTransit()
        }
        
    }
    
}

