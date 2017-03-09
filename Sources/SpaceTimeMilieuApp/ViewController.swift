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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView?
    
    private let initialLocation = Point(lat: 30.3672, latHemisphere: Point.LatitudeHemisphereEnum.north, long: -97.7431, longHemisphere: Point.LongitudeHemisphereEnum.west, datetime: Date(), timezone: "US/Central")
    private let finalLocation = Point(lat: 30.5083, latHemisphere: Point.LatitudeHemisphereEnum.north, long: -97.6789, longHemisphere: Point.LongitudeHemisphereEnum.west, datetime: Date(timeIntervalSinceNow: 3600), timezone: "US/Central")
    
    private let regionMargin: Double = 0.01
    private let initialViewPortMeters: CLLocationDistance = 5000
    
    private var mapDecorations: [Decoration] = [Decoration]()
    private var sourceArray = [String]()
    
    private let manager = CLLocationManager()
    
    private let decorationUpdateQueue =
        DispatchQueue(
            label: "decorationUpdateQueue",
            attributes: .concurrent)
    
    private var pinDroppedAtCurrentLocation = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mapView?.delegate = self
        self.manager.delegate = self

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
    
    @IBAction func centerOnCurrentLocation(_ sender: Any) {
        if (pinDroppedAtCurrentLocation) {
            if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse) {
                if let location = self.manager.location {
                    let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,initialViewPortMeters, initialViewPortMeters)
                    self.mapView?.setRegion(coordinateRegion, animated: true)
                }
            }
            return
        }
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse:
            manager.requestLocation()
            
        default:
            print("could not get location")
        }
        
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse) {
            if let location = self.manager.location {
                let centerPoint = Point(coordinate: location.coordinate, datetime: Date())
                self.fetchPoints(points: [centerPoint]) {
                    self.pinDroppedAtCurrentLocation=true
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    func centerMap() {
        if let (center, latDelta, longDelta) = Point.region(Decoration.points(self.mapDecorations)) {
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
                            self.decorationUpdateQueue.async(flags: .barrier) {
                                if (!self.sourceArray.contains(decoration.source)) {
                                    self.sourceArray.append(decoration.source)
                                }
                                let newAnnotation = DecorationAnnotation(point: point, decoration: decoration, sourceID: self.sourceArray.index(of: decoration.source) ?? 0)
                                DispatchQueue.main.async {
                                    map.addAnnotation(newAnnotation)
                                }
                            }
                        }
                    }
                    self.decorationUpdateQueue.async(flags: .barrier) {
                        self.mapDecorations.append(contentsOf: decorations)
                        self.centerMap()
                    }
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DecorationAnnotation {
            let identifier = "decorationPin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                //view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            
            view.pinTintColor = annotation.pinTintColor
            return view
        }
        return nil
    }
}

