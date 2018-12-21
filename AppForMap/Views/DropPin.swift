//
//  DropPin.swift
//  AppForMap
//
//  Created by Ahmed on 9/25/1397 AP.
//  Copyright © 1397 Ahmed. All rights reserved.
//

import UIKit
import  MapKit

class DropPin: NSObject , MKAnnotation{

    var coordinate: CLLocationCoordinate2D
    var indetifier : String

    init(coordinate : CLLocationCoordinate2D , indentifier : String){
        self.coordinate = coordinate
        self.indetifier = indentifier
        
    }
    
}
