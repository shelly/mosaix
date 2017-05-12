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

enum MetalProcessingState {
    case NotStarted
    case Preprocessing
    case PreprocessingComplete
}

enum MetalSelectionError: Error {
    case InvalidSkipSize
    case RegionMismatch
    case InvalidProcessingState
}

class MetalImageSelection: ImageSelection {
    private var state: MetalProcessingState
    var referenceImage : UIImage
    var refCGImage : CGImage
    private var allPhotos : PHFetchResult<PHAsset>?
    private var imageManager : PHImageManager
    private var skipSize : Int
    var tpa : TenPointAveraging
    var numThreads : Int
    private var timer: MosaicCreationTimer
    
    required init(refImage: UIImage, timer: MosaicCreationTimer) {
        self.state = .NotStarted
        self.referenceImage = refImage
        self.refCGImage = refImage.cgImageWithOrientation()
        self.imageManager = PHImageManager()
        self.allPhotos = nil
        self.skipSize = 0
        self.tpa = TenPointAveraging(timer: timer)
        self.timer = timer
        self.numThreads = 4
    }
    
    private func findBestMatch(row: Int, col: Int, squareIndex: Int, refRegion: CGRect, tpaPoints: [UInt32], onSelect : @escaping (ImageChoice) -> Void) {
        var step : ((String) -> Void)? = nil
        if (row == 0 && col == 0) {
            step = self.timer.task("Finding Best Match (\(row), \(col))")
        }
        let refTPA = TenPointAverage()
        let baseTPAIndex = 3 * TenPointAverageConstants.numCells * squareIndex
        for i in 0 ..< TenPointAverageConstants.numCells {
            refTPA.gridAvg[i/3][i%3] = RGBFloat(CGFloat(tpaPoints[baseTPAIndex + 3*i]),
                                                CGFloat(tpaPoints[baseTPAIndex + 3*i + 1]),
                                                CGFloat(tpaPoints[baseTPAIndex + 3*i + 2]))
        }
        step?("creating tpa")
        let (bestFit, bestDiff) = self.tpa.findNearestMatch(tpa: refTPA)!
        step?("finding nearest match")
        let targetSize = CGSize(width: refRegion.width, height: refRegion.height)
        let options = PHImageRequestOptions()
        let chosenAsset = PHAsset.fetchAssets(withLocalIdentifiers: [bestFit], options: PHFetchOptions()).firstObject!
        self.imageManager.requestImage(for: chosenAsset, targetSize: targetSize, contentMode: PHImageContentMode.default, options: options,
                                       resultHandler: {(result, info) -> Void in
                                        let choiceRegion = CGRect(x: 0, y: 0, width: Int(refRegion.width), height: Int(refRegion.height))
                                        let choice = ImageChoice(position: (row:row,col:col), image: result!, region: choiceRegion, fit: bestDiff)
                                        step?("fetching scaled image data")
                                        onSelect(choice)
                                        step?("drawing on canvas")
        })

    }
    
    /** 
     * Asynchronously preprocesses the photo library. Required before select.
     */
    func preprocess(then complete: @escaping () -> Void) throws -> Void {
        guard (self.state == .NotStarted || self.state == .PreprocessingComplete) else {
            print("self.state", self.state)
            throw MetalSelectionError.InvalidProcessingState
        }
        print("Pre-processing library...")
        self.state = .Preprocessing
        try self.tpa.preprocess(complete: {() -> Void in
            print("Done pre-processing.")
            self.state = .PreprocessingComplete
            complete()
        })
    }
    
    func updateRef(new: UIImage) {
        self.referenceImage = new
        self.refCGImage = new.cgImageWithOrientation()
    }
    
    func select(gridSizePoints: Int, numGridSpaces: Int, numRows: Int, numCols: Int, quality: Int, onSelect: @escaping ([String]) -> Void) throws -> Void {
        //Pre-process library
        guard (self.state == .PreprocessingComplete) else {
            print("self.state", self.state)
            throw MetalSelectionError.InvalidProcessingState
        }
        
        let texture = try TenPointAveraging.metal!.getImageTexture(image: self.refCGImage)
        TenPointAveraging.metal!.processEntirePhotoTexture(texture: texture, gridSize: gridSizePoints, numGridSpaces: numGridSpaces, rows: numRows,
                                                           cols: numCols,  threadWidth: 32, complete: {(results) -> Void in
            print("finding nearest matches...")
//            print(results)
            self.tpa.findNearestMatches(results: results, rows: numRows, cols: numCols, complete: onSelect)
//            let numRows : Int = Int(self.referenceImage.size.height) / gridSizePoints
//            let numCols : Int = Int(self.referenceImage.size.width) / gridSizePoints
//            for threadId in 0 ..< self.numThreads {
//                DispatchQueue.global(qos: .background).async {
//                    for i in stride(from: threadId, to: numRows * numCols, by: self.numThreads) {
//                        let row = i / numCols
//                        let col = i % numCols
//                        let x = col * gridSizePoints
//                        let y = row * gridSizePoints
//                        //Make sure that we cover the whole image and don't go over!
//                        let rectWidth = min(Int(self.referenceImage.size.width) - x, gridSizePoints)
//                        let rectHeight = min(Int(self.referenceImage.size.height) - y, gridSizePoints)
//                        if (rectWidth > 0 && rectHeight > 0) {
//                            self.findBestMatch(row: row, col: col, squareIndex: i, refRegion: CGRect(x: x, y: y, width: rectWidth, height: rectHeight), tpaPoints: results,
//                                               onSelect: {(choice: ImageChoice) -> Void in
//                                                    DispatchQueue.main.async {
//                                                        onSelect(choice)
//                                                    }
//                                                
//                            })
//                        }
//                    }
//                }
//            }
        })
    }
}
