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

struct MetalSelectionConstants {
    //    static let skipSize = 5 //Number of pixels to skip over when checking
}

enum MetalSelectionError: Error {
    case InvalidSkipSize
    case RegionMismatch
}

class MetalImageSelection: ImageSelection {
    private var referenceImage : UIImage
    private var allPhotos : PHFetchResult<PHAsset>?
    private var imageManager : PHImageManager
    private var skipSize : Int
    private var tpa : TenPointAveraging
    
    required init(refImage: UIImage) {
        self.referenceImage = refImage
        self.imageManager = PHImageManager()
        self.allPhotos = nil
        self.skipSize = 0
        self.tpa = TenPointAveraging()
    }
    

    
    private func compareRegions(refRegion: CGRect, otherImage: UIImage, otherRegion: CGRect) throws -> CGFloat {
        guard (refRegion.width == otherRegion.width && refRegion.height == otherRegion.height) else {
            throw NaiveSelectionError.RegionMismatch
        }
        guard (self.skipSize >= 0) else {
            throw NaiveSelectionError.InvalidSkipSize
        }
        var fit : CGFloat = 0.0
//        for deltaY in stride(from: 0, to: refRegion.height - 1, by: 1 + self.skipSize) {
//            for deltaX in stride(from: 0, to: refRegion.width - 1, by: 1 + self.skipSize) {
//                let refPoint = CGPoint(x:Int(refRegion.topLeft.x) + deltaX,y:Int(refRegion.topLeft.y) + deltaY)
//                let otherPoint = CGPoint(x:Int(otherRegion.topLeft.x) + deltaX, y: Int(otherRegion.topLeft.y) + deltaY)
//                fit += self.comparePoints(refPoint: refPoint, otherImage: otherImage, otherPoint: otherPoint)
//            }
//        }
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
                                                        let choiceRegion = CGRect(x: 0, y: 0, width: Int(refRegion.width), height: Int(refRegion.height))
                                                        let fit : CGFloat = try self.compareRegions(refRegion: refRegion, otherImage: result!, otherRegion: choiceRegion)
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
    
    func select(gridSizePoints: Int, quality: Int, onSelect: @escaping (ImageChoice) -> Void) throws -> Void {
        //Pre-process library
        print("Pre-processing library...")
        try self.tpa.begin(complete: {() -> Void in
            print("Done pre-processing.")
            print("Finding best matches...")
            
            let numRows : Int = Int(self.referenceImage.size.height) / gridSizePoints
            let numCols : Int = Int(self.referenceImage.size.width) / gridSizePoints
            
            for row in 0 ... numRows-1 {
                for col in 0 ... numCols-1 {
                    self.findBestMatch(row: row, col: col, refRegion: CGRect(x: col * gridSizePoints, y: row * gridSizePoints, width: gridSizePoints, height: gridSizePoints), onSelect: onSelect)
                }
            }
            
        })
        
    }
}
