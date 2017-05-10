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
    static let gridSizeMin = 2
    static let gridSizeMax = 75
    
    static let qualityMin = 1
    static let qualityMax = 100
}

class MosaicCreator {
    
    var imageSelector : ImageSelection
    private let reference : UIImage
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
            self._gridSizePoints = Int(min(self.reference.size.width, self.reference.size.height)) / spacesInRow
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
        let numRows = Int(self.reference.size.width) / self._gridSizePoints
        let numCols = Int(self.reference.size.height) / self._gridSizePoints
        self.totalGridSpaces = numRows * numCols
        print("Total grid spaces: \(self.totalGridSpaces)")
        self.gridSpacesFilled = 0
        try self.imageSelector.select(gridSizePoints: self._gridSizePoints, numGridSpaces: self.totalGridSpaces, numRows: numRows, numCols: numCols, quality: self._quality, onSelect:
            {(assetIds) -> Void in
                //                print("Found \(assetIds.count) asset IDs.")
                var assetData : [String : PHAsset] = [:]
                let choiceAssets = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
                choiceAssets.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    assetData[asset.localIdentifier] = asset
                })
                
                let imageManager = PHImageManager()
                UIGraphicsPushContext(self.compositeContext)
                for row in 0 ..< numRows {
                    for col in 0 ..< numCols {
                        let x = col * self._gridSizePoints
                        let y = row * self._gridSizePoints
                        //Make sure that we cover the whole image and don't go over!
                        let rectWidth = min(Int(self.reference.size.width) - x, self._gridSizePoints)
                        let rectHeight = min(Int(self.reference.size.height) - y, self._gridSizePoints)
                        let choiceRegion = CGRect(x:0, y:0, width: rectWidth, height: rectHeight)
                        let targetSize = CGSize(width: rectWidth, height: rectHeight)
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        imageManager.requestImage(for: assetData[assetIds[row*numRows + col]]!, targetSize: targetSize, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: {(result, info) -> Void in
                            let drawRect = CGRect(x: col * Int(self._gridSizePoints) + Int(choiceRegion.minX),
                                                  y: row * Int(self._gridSizePoints) + Int(choiceRegion.minY),
                                                  width: Int(rectWidth), height: Int(rectHeight))
                            print("drawing to \(drawRect)")
                            result!.draw(in: drawRect)
                        })
                    }
                }
                UIGraphicsPopContext()
                self.state = .Complete
                step("Complete")
                self.timer.complete(report: true)
                complete()
                
        })
    }
    
    func progress() -> Int {
        if (!(self.state == .InProgress)) {return 0}
        return Int(100.0 * (Float(self.gridSpacesFilled) / Float(self.totalGridSpaces)))
    }
}
