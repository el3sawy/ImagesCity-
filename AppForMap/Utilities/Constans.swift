//
//  Constans.swift
//  AppForMap
//
//  Created by Ahmed on 9/28/1397 AP.
//  Copyright © 1397 Ahmed. All rights reserved.
//

import Foundation
import Foundation

let apiKey = "b2d5544066fe3f86197bbf658e2b38c0"

func flickrUrl(forApiKey key: String, withAnnotation annotation: DropPin, andNumberOfPhotos number: Int) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}
