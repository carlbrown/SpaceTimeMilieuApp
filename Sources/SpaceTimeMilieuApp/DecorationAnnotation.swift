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
    let sourceId: Int
    
    init(point:Point, decoration:Decoration, sourceID:Int=0) {
        self.point = point
        self.decoration = decoration
        self.coordinate = point.coordinate
        self.sourceId = sourceID
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
    
    let colorArray = [
        MKPinAnnotationView.redPinColor(),
        MKPinAnnotationView.purplePinColor(),
        MKPinAnnotationView.greenPinColor(),
        UIColor.blue,
        UIColor.yellow
    ]
    
    var pinTintColor: UIColor  {
        return colorArray[(sourceId % colorArray.count)]
    }

}
