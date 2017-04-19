//
//  TenPointAveraging.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/18/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos


class RGBFloat {
    var r : CGFloat
    var g: CGFloat
    var b: CGFloat
    
    init(_ red : CGFloat, _ green : CGFloat, _ blue : CGFloat) {
        self.r = red
        self.g = green
        self.b = blue
    }
    
    static func -(left: RGBFloat, right: RGBFloat) -> CGFloat {
        return abs(left.r-right.r) + abs(left.g-right.g) + abs(left.b-right.b)
    }
}


struct TenPointAverageConstants {
    static let rows = 3
    static let cols = 3
}

class TenPointAverage {
    var totalAvg : RGBFloat = RGBFloat(0,0,0)
    var gridAvg : [[RGBFloat]] = Array(repeating: Array(repeating: RGBFloat(0,0,0), count: 3), count: 3)
    
    static func -(left: TenPointAverage, right: TenPointAverage) -> CGFloat {
        var diff : CGFloat = 0.0
        diff += left.totalAvg - right.totalAvg
        for row in 0..<TenPointAverageConstants.rows {
            for col in 0..<TenPointAverageConstants.cols {
                diff += left.gridAvg[row][col] - right.gridAvg[row][col]
            }
        }
        return diff
    }
}


class TenPointAveraging: LibraryPreprocessing {
    
    private var inProgress : Bool
    var averages : [PHAsset : TenPointAverage]
    private let imageManager : PHImageManager
    private var totalPhotos : Int
    private var photosComplete : Int
    
    init() {
        self.inProgress = false
        self.averages = [:] // empty dictionary
        self.imageManager = PHImageManager()
        self.totalPhotos = 0
        self.photosComplete = 0
    }
    
    func begin(complete: @escaping () -> Void) throws -> Void {
        guard (self.inProgress == false) else {
            throw LibraryPreprocessingError.PreprocessingInProgress
        }
        self.inProgress = true
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                self.processAllPhotos(fetchResult: PHAsset.fetchAssets(with: fetchOptions), complete: complete)
            case .denied, .restricted:
                print("Library Access Denied!")
            case .notDetermined:
                print("Library Access Not Determined!")
            }
        }
    }
    
 
    private func processAllPhotos(fetchResult: PHFetchResult<PHAsset>, complete: @escaping () -> Void) {
        self.totalPhotos = fetchResult.count
        self.photosComplete = 0
        fetchResult.enumerateObjects({(asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if (asset.mediaType == .image) {
                //Asynchronously grab image and save the values.
                self.imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: PHImageRequestOptions(),
                                               resultHandler: {(result, info) -> Void in
                                                if (result != nil) {
                                                    let image = result!
                                                    self.processPhoto(image: image.cgImage!, width: Int(image.size.width), height: Int(image.size.height), complete: {(tpa) -> Void in
                                                        self.averages[asset] = tpa
                                                        self.photosComplete += 1
                                                        if (self.photosComplete == self.totalPhotos) {
                                                            complete()
                                                        }
                                                    })
                                                }
                })
            }
        })
    }
    
    private func getAvgOverRegion(image: CIImage, region: CGRect) -> RGBFloat {
        let avgRegion = CIVector(cgRect: region)
        let avgFilter = CIFilter(name: "CIAreaAverage", withInputParameters: [
            kCIInputImageKey: image,
            kCIInputExtentKey: avgRegion
        ])
        let ctx = CIContext(options: nil)
        let cgImage = ctx.createCGImage(avgFilter!.outputImage!, from:avgFilter!.outputImage!.extent)!
        let data : UnsafePointer<UInt8> = CFDataGetBytePtr(cgImage.dataProvider!.data)
        let overallRGB = RGBFloat(CGFloat(data[0]), CGFloat(data[1]), CGFloat(data[2]))
        return overallRGB
    }
    
    func processPhoto(image: CGImage, width: Int, height: Int, complete: (TenPointAverage) -> Void) {
        //Computes the average
        print("processing photo.")
        let ciImage = CIImage(cgImage: image)
        let tpa = TenPointAverage()
        let colWidth = width / TenPointAverageConstants.cols
        let colHeight = height / TenPointAverageConstants.rows
        for col in 0..<TenPointAverageConstants.cols {
            for row in 0..<TenPointAverageConstants.rows {
                tpa.gridAvg[row][col] = self.getAvgOverRegion(image: ciImage, region: CGRect(x: col * colWidth, y: row * colHeight, width: colWidth, height: colHeight))
            }
        }
        tpa.totalAvg = self.getAvgOverRegion(image: ciImage, region: CGRect(x: 0, y: 0, width: width, height: height))
        complete(tpa)
    }
    
    func progress() -> Int {
        if (!self.inProgress) {return 0}
        return Int(100.0 * Float(self.photosComplete) / Float(self.totalPhotos))
    }
    
}
