//
//  DecorationAnnotation.swift
//  SpaceTimeMilieuApp
//
//  Created by Carl Brown on 3/6/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import UIKit
import MapKit

class DecorationAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let point: Point
    let decoration: Decoration

    init(point:Point, decoration:Decoration) {
        self.point = point
        self.decoration = decoration
        self.coordinate = CLLocationCoordinate2DMake(point.latitudeDegrees, point.longitudeDegrees)
    }
    
    var title: String? {
        return decoration.title
    }

    var subtitle: String? {
        return decoration.description
    }

    func pinTintColor() -> UIColor  {
        return MKPinAnnotationView.redPinColor()
    }
    
    // annotation callout opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
        
        let mapItem = MKMapItem()
        mapItem.name = title
        
        return mapItem
    }

}
