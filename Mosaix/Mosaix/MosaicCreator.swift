//
//  MosaicCreator.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/14/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit
import Photos

enum MosaicCreationState {
    case NotStarted
    case PreprocessingInProgress
    case PreprocessingComplete
    case InProgress
    case Complete
}

enum MosaicCreationError: Error {
    case InvalidState
    case QualityOutOfBounds
    case GridSizeOutOfBounds
}

struct MosaicCreationConstants {
    static let gridSizeMin = 3 // must be at least 3 for TPA to work
    static let gridSizeMax = 75
    
    static let qualityMin = 1
    static let qualityMax = 100
}

class MosaicCreator {
    
    var imageSelector : ImageSelection
    var reference : UIImage
    private var state : MosaicCreationState
    private var _gridSizePoints : Int
    private var _quality : Int = (MosaicCreationConstants.qualityMax + MosaicCreationConstants.qualityMin)/2
    private let compositeContext: CGContext
    var timer : MosaicCreationTimer
    
    private var totalGridSpaces : Int
    private var gridSpacesFilled : Int
    
    var compositeImage : UIImage {
        get {
            let cgImage = self.compositeContext.makeImage()!
            return UIImage.init(cgImage: cgImage)
        }
    }
    
    init(reference: UIImage) {
        self.state = .NotStarted
        self.reference = reference
        self.timer = MosaicCreationTimer(enabled: true)
        self.imageSelector = MetalImageSelection(refImage: reference, timer: self.timer)
        
        self.totalGridSpaces = 0
        self.gridSpacesFilled = 0
        
        UIGraphicsBeginImageContextWithOptions(self.reference.size, false, 0)
        self.compositeContext = UIGraphicsGetCurrentContext()!
        UIGraphicsPopContext()
        
        
        do {
            self._gridSizePoints = 0
            try self.setGridSizePoints((MosaicCreationConstants.gridSizeMax + MosaicCreationConstants.gridSizeMin)/2)
        } catch {
            print("error initializing grid size")
        }
    }
    
    func getGridSizePoints() -> Int {
        return self._gridSizePoints
    }
    func setGridSizePoints(_ gridSizePoints : Int) throws {
        guard (gridSizePoints >= MosaicCreationConstants.gridSizeMin &&
                gridSizePoints <= MosaicCreationConstants.gridSizeMax) else {
                    throw MosaicCreationError.GridSizeOutOfBounds
            }
            let spacesInRow = (MosaicCreationConstants.gridSizeMax - gridSizePoints) + 10
            self._gridSizePoints = max(Int(min(self.reference.size.width, self.reference.size.height)) / spacesInRow, MosaicCreationConstants.gridSizeMin)
    }
    
    func getQuality() -> Int {
        return self._quality
    }
    func setQuality(quality: Int) throws {
        guard (quality >= MosaicCreationConstants.qualityMin &&
               quality <= MosaicCreationConstants.qualityMax) else {
            throw MosaicCreationError.QualityOutOfBounds
        }
        self._quality = quality
    }
    
    func preprocess(complete: @escaping () -> Void) throws -> Void {
        if (self.state == .InProgress || self.state == .PreprocessingInProgress) {
            throw MosaicCreationError.InvalidState
        } else if (self.state == .PreprocessingComplete || self.state == .Complete) {
            self.state = .PreprocessingComplete
            complete()
        } else {
            //Needs to preprocess
            self.state = .PreprocessingInProgress
            try self.imageSelector.preprocess(then: {() -> Void in
                self.state = .PreprocessingComplete
                print("done preprocessing. array:")
                complete()
            })
        }
    }
    
    func begin(tick : @escaping () -> Void, complete : @escaping () -> Void) throws -> Void {
        guard (self.state == .PreprocessingComplete || self.state == .Complete) else {
            throw MosaicCreationError.InvalidState
        }
        let step = self.timer.task("Photo Mosaic Generation")
//        print("Beginning Mosaic generation")
        self.state = .InProgress
        let numRows = Int(self.reference.size.height) / self._gridSizePoints
        let numCols = Int(self.reference.size.width) / self._gridSizePoints
        self.totalGridSpaces = numRows * numCols
        print("Total grid spaces: \(self.totalGridSpaces)")
        self.gridSpacesFilled = 0
        try self.imageSelector.select(gridSizePoints: self._gridSizePoints, numGridSpaces: self.totalGridSpaces, numRows: numRows, numCols: numCols, quality: self._quality, onSelect:
            {(assetIds) -> Void in
                //                print("Found \(assetIds.count) asset IDs.")
                step("Selecting nearest matches")
                print("Chosen asset: \(assetIds[29])")
                var assetData : [String : PHAsset] = [:]
                let choiceAssets = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
                choiceAssets.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    assetData[asset.localIdentifier] = asset
                })
                
                let imageManager = PHImageManager()
                step("Retrieving Local Identifiers")
                print("gridSize: \(self._gridSizePoints)")
                print("image width: \(self.reference.size.width), height: \(self.reference.size.height)")
                print("rows: \(numRows), cols: \(numCols)")
                print("Have \(assetIds.count)")
                for row in 0 ..< numRows {
                    for col in 0 ..< numCols {
                        let x = col * self._gridSizePoints
                        let y = row * self._gridSizePoints
                        //Make sure that we cover the whole image and don't go over!
                        let rectWidth = min(Int(self.reference.size.width) - x, self._gridSizePoints)
                        let rectHeight = min(Int(self.reference.size.height) - y, self._gridSizePoints)
                        if (rectWidth < 0 || rectHeight < 0) {
                            print("Warning: (\(row),\(col)) mapping to (\(x),\(y)) <-> (\(rectWidth), \(rectHeight))")
                        }
//                        print("width \(rectWidth), height \(rectHeight)")
                        let targetSize = CGSize(width: rectWidth, height: rectHeight)
//                        print("requesting image of size \(targetSize)")
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true

//                        print("requesting asset \(row*numCols + col)/\(assetIds.count)")
//                        print("with assetId \(assetIds[row*numCols + col] )")
//                        if (col == 0) {
//                            print("start of row. Asset ID \(assetIds[row*numCols + col])")
                        //                        }
                        imageManager.requestImage(for: assetData[assetIds[row*numCols + col]]!, targetSize: targetSize, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: {(result, info) -> Void in
                            UIGraphicsPushContext(self.compositeContext)
                            let drawRect = CGRect(x: x, y: y, width: Int(rectWidth), height: Int(rectHeight))
//                            print("drawing to \(drawRect)")
                            result!.draw(in: drawRect)
                            UIGraphicsPopContext()
//                            print("drawn!")
                        })
                    }
                }
                step("Drawing onto Canvas")
                self.state = .Complete
                complete()
                step("Complete callback")
                self.timer.complete(report: true)
                
        })
    }
    
    func progress() -> Int {
        if (!(self.state == .InProgress)) {return 0}
        return Int(100.0 * (Float(self.gridSpacesFilled) / Float(self.totalGridSpaces)))
    }
}
