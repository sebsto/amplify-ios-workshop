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

func load<T: Decodable>(_ filename: String) -> T {
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

// Create an image from Data :
// Data -> UIImage -> Image
extension Image {
    init(fromData data:Data, scale: Int, name:String) {
        guard let uiImage = UIImage(data: data) else {
            fatalError("Couldn't convert image data \(name)")
        }
        self = Image(uiImage.cgImage!, scale: CGFloat(scale), label: Text(verbatim: name))

    }
}

// manage image cache and download
final class ImageStore {
        
    // our image cache
    private var images: [String: Image]
    private let placeholderName = "PLACEHOLDER"
    private let imageScale = 2
    
    // singleton (because of the cache)
    static var shared = ImageStore()

    init() {
        
        // initially empty cache
        images = [:]
        
        // create a place holder image
        images[self.placeholderName] = Image(uiImage: UIImage.imageWithColor(color: UIColor.lightGray, size: CGSize(width:300, height: 300)))
    }
    
    // retrieve an image.
    // first check the cache, otherwise trigger an asynchronous download and return a placeholder
    func image(name: String, landmark: Landmark) -> Image {
        var result : Image?
        
        if let img = images[name] {

            print("Image \(name) found in cache")
            // return cached image when we have it
            result = img
            
        } else {

            // trigger an asynchronous download
            // result will be store in landmark.image and that will trigger an UI refresh
            Task { await asyncDownloadImage(name, landmark) }
            
            // and return a placeholder while waiting for the result
            result = self.placeholder()

        }
        return result!
    }
    
    // asynchronously download the image
    @MainActor // to be sure to execute the UI update on the main thread
    private func asyncDownloadImage(_ name: String, _ landmark: Landmark) {
        
        // trigger asynchronous download
        Task {
            guard let app = AppDelegate.instance else {
                fatalError("AppDelegate is not initilized correctly")
            }
            
            // download the image from our API 
            let data = await app.downloadImage(name)
            
            // convert to an image : Data -> UIImage -> Image
            let img = Image(fromData: data, scale: imageScale, name: name)
            
            // store image in cache
            addImage(name: name, image: img)
            
            // update landmark object, this will trigger the UI refresh because image is Published
            // and Landmark is Observable in LandmarkRow UI component
            landmark.image = img
        }
    }
    
    // return the placeholder image from the cache
    func placeholder() -> Image {
        if let img = images[self.placeholderName] {
            return img
        } else {
            fatalError("Image cache is incorrectly initialized")
        }
    }

    // add image to the cache
    func addImage(name: String, image : Image) {
        images[name] = image
    }
}

