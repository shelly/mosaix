//
//  TenPointAveraging.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/18/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos


typealias RGBFloat = (r : CGFloat, g: CGFloat, b: CGFloat)
struct TenPointAverage {
    var totalAvg : RGBFloat = (0,0,0)
    var gridAvg : [[RGBFloat]] = Array(repeating: Array(repeating: RGBFloat(0,0,0), count: 3), count: 3)
}

struct TenPointAverageConstants {
    static let rows = 3
    static let cols = 3
}


class TenPointAveraging: LibraryPreprocessing {
    
    private var inProgress : Bool
    private var averages : [UIImage : TenPointAverage]
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
                                                    self.processPhoto(image: result!, complete: complete)
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
        print("overall RGB values for region: \(overallRGB)")
        return overallRGB
    }
    
    private func processPhoto(image: UIImage, complete: () -> Void) {
        //Computes the average
        let ciImage : CIImage = CIImage(image: image)!
        var tpa = TenPointAverage()
        let width = Int(image.size.width) / TenPointAverageConstants.cols
        let height = Int(image.size.height) / TenPointAverageConstants.rows
        for col in 0..<TenPointAverageConstants.cols {
            for row in 0..<TenPointAverageConstants.rows {
                tpa.gridAvg[row][col] = self.getAvgOverRegion(image: ciImage, region: CGRect(x: col * width, y: row * height, width: width, height: height))
            }
        }
        tpa.totalAvg = self.getAvgOverRegion(image: ciImage, region: ciImage.extent)
        self.averages[image] = tpa
        self.photosComplete += 1
        if (self.photosComplete == self.totalPhotos) {
            complete()
        }
    }
    
    func progress() -> Int {
        if (!self.inProgress) {return 0}
        return Int(100.0 * Float(self.photosComplete) / Float(self.totalPhotos))
    }
    
}
