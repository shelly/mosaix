//
//  NaiveImageSelection.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit
import Photos

struct NaiveSelectionConstants {
//    static let skipSize = 5 //Number of pixels to skip over when checking
}

enum NaiveSelectionError: Error {
    case InvalidSkipSize
    case RegionMismatch
}

class NaiveImageSelection: ImageSelection {
    var tpa: TenPointAveraging
    var numThreads : Int
    private var referenceImage : UIImage
    private var referencePixelData : CFData
    private var allPhotos : PHFetchResult<PHAsset>?
    private var imageManager : PHImageManager
    private var skipSize : Int
    
    required init(refImage: UIImage, timer: MosaicCreationTimer) {
        self.tpa = TenPointAveraging(timer: timer)
        self.referenceImage = refImage
        self.referencePixelData = self.referenceImage.cgImage!.dataProvider!.data!
        self.imageManager = PHImageManager()
        self.allPhotos = nil
        self.skipSize = 0
        self.numThreads = 1
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
                case .authorized:
                    let fetchOptions = PHFetchOptions()
                    self.allPhotos = PHAsset.fetchAssets(with: fetchOptions)
                case .denied, .restricted:
                    print("Library Access Denied!")
                case .notDetermined:
                    print("Library Access Not Determined!")
            }
        }
    }
    
    private func comparePoints(refPoint: CGPoint, otherImage: UIImage, otherPoint: CGPoint) -> Float {
        
        let otherPixelData = otherImage.cgImage!.dataProvider!.data
        
        let refData: UnsafePointer<UInt8> = CFDataGetBytePtr(self.referencePixelData)
        let othData: UnsafePointer<UInt8> = CFDataGetBytePtr(otherPixelData)
        
        let refPixelIndex : Int = ((Int(referenceImage.size.width) * Int(refPoint.y)) + Int(refPoint.x)) * 4
        let othPixelIndex : Int = ((Int(otherImage.size.width) * Int(otherPoint.y)) + Int(otherPoint.x)) * 4
        
        let redDiff = Int(refData[refPixelIndex]) - Int(othData[othPixelIndex])
        let greenDiff = Int(refData[refPixelIndex+1]) - Int(othData[othPixelIndex+1])
        let blueDiff = Int(refData[refPixelIndex+2]) - Int(othData[othPixelIndex+2])
        return Float(abs(redDiff) + abs(greenDiff) + abs(blueDiff)) / Float(255.0)
    }
    
    private func compareRegions(refRegion: CGRect, otherImage: UIImage, otherRegion: CGRect) throws -> Float {
        guard (refRegion.width == otherRegion.width && refRegion.height == otherRegion.height) else {
            throw NaiveSelectionError.RegionMismatch
        }
        guard (self.skipSize >= 0) else {
            throw NaiveSelectionError.InvalidSkipSize
        }
        var fit : Float = 0.0
        for deltaY in stride(from: 0, to: Int(refRegion.height) - 1, by: 1 + self.skipSize) {
            for deltaX in stride(from: 0, to: Int(refRegion.width) - 1, by: 1 + self.skipSize) {
                let refPoint = CGPoint(x:Int(refRegion.minX) + deltaX,y:Int(refRegion.minY) + deltaY)
                let otherPoint = CGPoint(x:Int(otherRegion.minX) + deltaX, y: Int(otherRegion.minY) + deltaY)
                fit += self.comparePoints(refPoint: refPoint, otherImage: otherImage, otherPoint: otherPoint)
            }
        }
        return fit
    }
    
    private func findBestMatch(row: Int, col: Int, refRegion: CGRect, onSelect : @escaping (ImageChoice) -> Void) {
        print("(\(row), \(col)) finding best match.")
        var bestMatch : ImageChoice? = nil
        allPhotos?.enumerateObjects({(asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if (asset.mediaType == .image) {
                let targetSize = CGSize(width: refRegion.width, height: refRegion.height)
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: PHImageContentMode.default, options: options,
                                               resultHandler: {(result, info) -> Void in
                                                if (result != nil) {
                                                    do {
                                                        let choiceRegion = CGRect(x: 0.0, y: 0.0, width: refRegion.width, height: refRegion.height)
                                                        let fit : Float = try self.compareRegions(refRegion: refRegion, otherImage: result!, otherRegion: choiceRegion)
                                                        if (bestMatch == nil || fit < bestMatch!.fit) {
                                                            bestMatch = ImageChoice(position: (row, col), image: result!, region: choiceRegion, fit: fit)
                                                        }
                                                    } catch {
                                                        print("Region mismatch!!!")
                                                    }
                                                }
                })
            }
        })
        onSelect(bestMatch!)
    }
    
    func preprocess(then complete: @escaping () -> Void) throws -> Void {
        complete()
    }
    
    func select(gridSizePoints: Int, numGridSpaces: Int, quality: Int, onSelect: @escaping (ImageChoice) -> Void) throws -> Void {
        if (allPhotos == nil) {
            throw ImageSelectionError.PreprocessingIncomplete
        }
        self.skipSize = MosaicCreationConstants.qualityMax - quality - MosaicCreationConstants.qualityMin
        let numRows : Int = Int(self.referenceImage.size.height) / gridSizePoints
        let numCols : Int = Int(self.referenceImage.size.width) / gridSizePoints
//        print("selecting with grid size \(gridSizePoints), \(numRows) rows, and \(numCols) columns.")

        for row in 0 ... numRows-1 {
            for col in 0 ... numCols-1 {
                self.findBestMatch(row: row, col: col, refRegion: CGRect(x: col*gridSizePoints, y: row * gridSizePoints, width: gridSizePoints, height: gridSizePoints), onSelect: onSelect)
            }
        }
    }
}
