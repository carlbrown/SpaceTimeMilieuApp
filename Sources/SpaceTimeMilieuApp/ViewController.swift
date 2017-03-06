//
//  ViewController.swift
//  SpaceTimeMilieuApp
//
//  Created by Carl Brown on 3/6/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView?
    let initialLocation = Point(lat: 30.3672, latHemisphere: Point.LatitudeHemisphereEnum.north, long: -97.7431, longHemisphere: Point.LongitudeHemisphereEnum.west, datetime: Date(), timezone: "US/Central")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mapView?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        let coordinateRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(initialLocation.latitudeDegrees, initialLocation.longitudeDegrees),5000, 5000)
//        self.mapView?.setRegion(coordinateRegion, animated: true)
        var request = URLRequest(url: URL(string:"https://ssldemo.linuxswift.com:8090/api")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject:initialLocation.toDictionary())
            let task = URLSession.shared.dataTask(with: request) { fetchData,fetchResponse,fetchError in
                guard fetchError == nil else {
                    print("Got fetch Error: \(fetchError?.localizedDescription ?? "Error with no description")")
                    return
                }
                guard let fetchData = fetchData else {
                    print("Nil fetched data with no error")
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: fetchData, options: .mutableContainers)
      
                    if (getenv("DEBUG")) != nil { //debug
                        //OK to crash if debugging turned on
                        let jsonForPrinting = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                        let jsonToPrint = String(data: jsonForPrinting, encoding: .utf8)
                        print("result: \(jsonToPrint!)")
                    }

                    if let fetchedDict = json as? [String: Any],
                    let pointDict = fetchedDict[Point.pointKey] as? [String: Any],
                        let point = Point(fromDict:pointDict),
                        let decorationDict = fetchedDict[Decoration.decorationKey] as? [String: Any],
                        let decoration = Decoration(fromDict: decorationDict),
                        let map = self.mapView {
                        let newAnnotation = DecorationAnnotation(point: point, decoration: decoration)
                        map.addAnnotation(newAnnotation)
                        let coordinateRegion = MKCoordinateRegionMakeWithDistance(newAnnotation.coordinate,5000, 5000)
                        self.mapView?.setRegion(coordinateRegion, animated: true)

                    }
                } catch {
                    print("Could not parse remote JSON Payload \(error)! Giving up!")
                }

            }
            task.resume()

        } catch {
            print("Could not create remote JSON Payload \(error)! Giving up!")
        }
        

    }
}

