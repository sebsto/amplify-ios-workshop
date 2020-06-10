/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helpers for loading images and data.
*/

import UIKit
import SwiftUI
import CoreLocation

// this is just used for the previews. At runtime, data are now taken from UserData and loaded through AppDelegate
let landmarkData: [Landmark] = load("landmarkData.json")

func load<T: Decodable>(_ filename: String, as type: T.Type = T.self) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

// allow to create image with uniform color
// https://gist.github.com/isoiphone/031da3656d69c0d85805
extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// manage iage cache and download
final class ImageStore {
    typealias _ImageDictionary = [String: Image]
    
    fileprivate let placeholderName = "PLACEHOLDER"
    fileprivate var images: _ImageDictionary
    static var scale = 2
    
    static var shared = ImageStore()

    init() {
        images = [:]
        images[self.placeholderName] = Image(uiImage: UIImage.imageWithColor(color: UIColor.white, size: CGSize(width:300, height: 300)))
    }
    
    func image(name: String, landmark: Landmark) -> Image {
        var result : Image?
        if let img = images[name] {
            result = img
        } else {
            
            DispatchQueue.main.async {
                // trigger asynchronous download
                let app = UIApplication.shared.delegate as! AppDelegate
                _ = app.image(name) { (data) in
                    
                    guard
                        let i = UIImage(data: data)
                    else {
                        fatalError("Couldn't convert image data \(name)")
                    }
                    let img = Image(i.cgImage!, scale: CGFloat(ImageStore.scale), label: Text(verbatim: name))
                    
                    // update UI on the main thread
                    DispatchQueue.main.async {
                        // update landmark object, this will trigger the UI refresh because image is Published
                        // and Landmark is Observable in LandmarkRow UI component
                        landmark.image = img
                    }
                }
            }
            result = self.placeholder()
        }
        return result!
    }
    
    func placeholder() -> Image {
        if let img = images[self.placeholderName] {
            return img
        } else {
            fatalError("Image cache is incorrectly initialized")
        }
    }

    func addImage(name: String, image : Image) {
        images[name] = image
    }
}
