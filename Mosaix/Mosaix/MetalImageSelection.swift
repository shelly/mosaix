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
import GameplayKit

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
        let croppedImage : CGImage? = self.refCGImage.cropping(to: refRegion)
//        print("attempted to crop to \(refRegion) \t from \(self.refCGImage.width)x\(self.refCGImage.height)")
        if croppedImage != nil {
            self.tpa.processPhoto(image: croppedImage!, complete: {(refTPA) -> Void in
    //            print("(\(row), \(col)) -> \(refTPA!.gridAvg)")
                let (bestFit, bestDiff) = self.tpa.findNearestMatch(tpa: refTPA!)!
                
                let targetSize = CGSize(width: refRegion.width, height: refRegion.height)
                let options = PHImageRequestOptions()
                self.imageManager.requestImage(for: bestFit, targetSize: targetSize, contentMode: PHImageContentMode.default, options: options,
                                               resultHandler: {(result, info) -> Void in
                                                let choiceRegion = CGRect(x: 0, y: 0, width: Int(refRegion.width), height: Int(refRegion.height))
                                                let choice = ImageChoice(position: (row:row,col:col), image: result!, region: choiceRegion, fit: bestDiff)
                                                onSelect(choice)
                })
            })
        } else {
            print("ok that's bad news.")
        }
    }
    
    func select(gridSizePoints: Int, quality: Int, onSelect: @escaping (ImageChoice) -> Void) throws -> Void {
        //Pre-process library
        print("Pre-processing library...")
        try self.tpa.preprocess(complete: {() -> Void in
            print("Done pre-processing.")
            print("Finding best matches...")
            
            let numRows : Int = Int(self.referenceImage.size.height) / gridSizePoints
            let numCols : Int = Int(self.referenceImage.size.width) / gridSizePoints
//            print("\(numRows) rows and \(numCols) cols")
            let numThreads : Int = 32
            
            for threadId in 0 ..< numThreads {
                DispatchQueue.global(qos: .background).async {
                    for i in stride(from: threadId, to: numRows * numCols, by: numThreads) {
                        let row = i / numCols
                        let col = i % numCols
                        let x = col * gridSizePoints
                        let y = row * gridSizePoints
                        //Make sure that we cover the whole image and don't go over!
                        let rectWidth = min(Int(self.referenceImage.size.width) - x, gridSizePoints)
                        let rectHeight = min(Int(self.referenceImage.size.height) - y, gridSizePoints)
//                        print("row \(row), col \(col) -> (\(x), \(y), \(rectWidth), \(rectHeight))")
                        if (rectWidth > 0 && rectHeight > 0) {
                            self.findBestMatch(row: row, col: col, refRegion: CGRect(x: x, y: y, width: rectWidth, height: rectHeight),
                                               onSelect: {(choice: ImageChoice) -> Void in
                                                    DispatchQueue.main.async {
                                                        onSelect(choice)
                                                    }
                                                
                            })
                        }
                    }
                }
            }
            
        })
        
    }
}
