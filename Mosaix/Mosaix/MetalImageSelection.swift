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
    private var refCGImage : CGImage
    private var allPhotos : PHFetchResult<PHAsset>?
    private var imageManager : PHImageManager
    private var skipSize : Int
    private var tpa : TenPointAveraging
    
    required init(refImage: UIImage) {
        self.referenceImage = refImage
        self.refCGImage = refImage.cgImage!
        self.imageManager = PHImageManager()
        self.allPhotos = nil
        self.skipSize = 0
        self.tpa = TenPointAveraging()
    }
    
    private func findBestMatch(row: Int, col: Int, refRegion: CGRect, onSelect : @escaping (ImageChoice) -> Void) {
        print("(\(row), \(col)) finding best match.")
        let croppedImage : CGImage = self.refCGImage.cropping(to: refRegion)!
        self.tpa.processPhoto(image: croppedImage, width: Int(refRegion.width), height: Int(refRegion.height), complete: {(refTPA) -> Void in
            var bestFit : PHAsset? = nil
            var bestDiff : CGFloat = 0.0
            for (asset, assetTPA) in self.tpa.averages {
                let diff = assetTPA - refTPA
                if (bestFit == nil || diff < bestDiff) {
                    bestFit = asset
                    bestDiff = diff
                }
            }
            let targetSize = CGSize(width: refRegion.width, height: refRegion.height)
            let options = PHImageRequestOptions()
            self.imageManager.requestImage(for: bestFit!, targetSize: targetSize, contentMode: PHImageContentMode.default, options: options,
                                           resultHandler: {(result, info) -> Void in
                                            let choiceRegion = CGRect(x: 0, y: 0, width: Int(refRegion.width), height: Int(refRegion.height))
                                            let choice = ImageChoice(position: (row:row,col:col), image: result!, region: choiceRegion, fit: bestDiff)
                                            onSelect(choice)
            })
        })
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
