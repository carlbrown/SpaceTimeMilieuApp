//
//  ViewController.swift
//  SpaceTimeMilieuApp
//
//  Created by Carl Brown on 3/6/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView?
    
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
        let initialLocation = CLLocation(latitude: 30.3672, longitude: -97.7431)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate,5000, 5000)
        self.mapView?.setRegion(coordinateRegion, animated: true)

    }
}

