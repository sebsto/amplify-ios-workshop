/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model for an individual landmark.
*/

import SwiftUI
import CoreLocation

struct Landmark: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    fileprivate var imageName: String
    fileprivate var coordinates: Coordinates
    var state: String
    var park: String
    var category: Category
    var isFavorite: Bool

    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude)
    }

    enum Category: String, CaseIterable, Codable, Hashable {
        case featured = "Featured"
        case lakes = "Lakes"
        case rivers = "Rivers"
        case mountains = "Mountains"
    }
    
    fileprivate var isImageLoaded : Bool = false
    func hasImage(_ name: String) -> Bool { return name == imageName }
}

extension Landmark {
    var image: Image {
        set { isImageLoaded = true }
        get {
            if isImageLoaded {
               // return image from ImageStore
               return ImageStore.shared.image(name: self.imageName)
           } else {
               // trigger asynchronous download
               let app = UIApplication.shared.delegate as! AppDelegate
               _ = app.image(imageName)
               
                // return placeholder
               return ImageStore.shared.placeholder()
            }
        }
    }
}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}

// assume all fields are non null.
// real life project must spend more time thinking about null values and
// maybe convert the above code (original Landmark class) to optionals
// I am not doing it for this workshop as this would imply too many changes in UI code
// MARK: - TODO

extension Landmark {
    init(from : LandmarkData) {
        
        guard let i = Int(from.id) else {
            preconditionFailure("Can not create Landmark, Invalid ID : \(from.id) (expected Int)")
        }
        
        id = i
        name = from.name
        imageName = from.imageName!
        coordinates = Coordinates(latitude: from.coordinates!.latitude!, longitude: from.coordinates!.longitude!)
        state = from.state!
        park = from.park!
        category = Category(rawValue: from.category!)!
        isFavorite = from.isFavorite!

    }
}

