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
        self.coordinate = point.coordinate
    }
    
    var title: String? {
        return decoration.title
    }

    var subtitle: String? {
        if let details = decoration.details {
            return "\(details)\n\(point.datetime.description(with: NSLocale.current))"
        }
        return "\(point.datetime.description(with: NSLocale.current))"
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
