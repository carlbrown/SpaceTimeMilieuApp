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
    
    private let initialLocation = Point(lat: 30.3672, latHemisphere: Point.LatitudeHemisphereEnum.north, long: -97.7431, longHemisphere: Point.LongitudeHemisphereEnum.west, datetime: Date(), timezone: "US/Central")
    private let finalLocation = Point(lat: 30.5083, latHemisphere: Point.LatitudeHemisphereEnum.north, long: -97.6789, longHemisphere: Point.LongitudeHemisphereEnum.west, datetime: Date(timeIntervalSinceNow: 3600), timezone: "US/Central")
    
    private let regionMargin: Double = 0.01
    private let initialViewPortMeters: CLLocationDistance = 5000
    
    private var mapDecorations: [Decoration] = [Decoration]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mapView?.delegate = self

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addDecoration))
        longPressRecognizer.minimumPressDuration = 2.0
        self.mapView?.addGestureRecognizer(longPressRecognizer)
        
        let tripleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(centerMap))
        tripleTapRecognizer.numberOfTapsRequired = 3
        self.mapView?.addGestureRecognizer(tripleTapRecognizer)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate,initialViewPortMeters, initialViewPortMeters)
        self.mapView?.setRegion(coordinateRegion, animated: true)
        fetchPoints(points: [initialLocation,finalLocation])
    }
    
    func centerMap() {
        if let (center, latDelta, longDelta) = Point.region(Decoration.points(mapDecorations)) {
            DispatchQueue.main.async {
                self.mapView?.setRegion(MKCoordinateRegionMake(center, MKCoordinateSpan(latitudeDelta: latDelta + self.regionMargin, longitudeDelta: longDelta + self.regionMargin)), animated: true)
            }
        }
    }
    
    func addDecoration(gestureRecognizer:UIGestureRecognizer) {
        if (!gestureRecognizer.isEnabled) {
            return
        }
        gestureRecognizer.isEnabled=false
        if let map = self.mapView {
            let touchPoint = gestureRecognizer.location(in: map)
            let newCoordinates = map.convert(touchPoint, toCoordinateFrom: map)
            let newPoint = Point(coordinate: newCoordinates, datetime: Date())
            fetchPoints(points: [newPoint]) {
                DispatchQueue.main.async {
                    gestureRecognizer.isEnabled=true
                }
            }
        }
    }
    
    func fetchPoints(points:[Point], completion: (() -> ())?=nil) {
        var request = URLRequest(url: URL(string:"https://ssldemo.linuxswift.com:8090/api")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try Point.encodeJSON(points: points)
            let task = URLSession.shared.dataTask(with: request) { fetchData,fetchResponse,fetchError in
                guard fetchError == nil else {
                    print("Got fetch Error: \(fetchError?.localizedDescription ?? "Error with no description")")
                    if let completion = completion {
                        completion()
                    }
                    return
                }
                guard let fetchData = fetchData else {
                    print("Nil fetched data with no error")
                    if let completion = completion {
                        completion()
                    }
                    return
                }
                do {
                    let decorations: [Decoration] = try Decoration.decodeJSON(data: fetchData)
                    
                    //if (getenv("DEBUG")) != nil { //debug
                    //OK to crash if debugging turned on
                    let jsonToPrint = String(data: fetchData, encoding: .utf8)
                    print("result: \(jsonToPrint!)")
                    //}
                    
                    for decoration in decorations {
                        if let point = decoration.point,
                            let map = self.mapView {
                            let newAnnotation = DecorationAnnotation(point: point, decoration: decoration)
                            DispatchQueue.main.async {
                                map.addAnnotation(newAnnotation)
                            }
                        }
                    }
                    self.mapDecorations.append(contentsOf: decorations)
                    self.centerMap()
                    if let completion = completion {
                        completion()
                    }
                } catch {
                    print("Could not parse remote JSON Payload \(error)! Giving up!")
                    if let completion = completion {
                        completion()
                    }
                }
            }
            task.resume()
        } catch {
            print("Could not create remote JSON Payload \(error)! Giving up!")
            if let completion = completion {
                completion()
            }
        }
    }
}

