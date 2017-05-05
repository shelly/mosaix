//
//  MosaicCreator.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/14/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit

enum MosaicCreationError: Error {
    case MosaicCreationInProgress
    case QualityOutOfBounds
    case GridSizeOutOfBounds
}

struct MosaicCreationConstants {
    static let gridSizeMin = 10
    static let gridSizeMax = 500
    
    static let qualityMin = 0
    static let qualityMax = 100
}

class MosaicCreator {
    
    private let imageSelector : ImageSelection
    private let reference : UIImage
    private var inProgress : Bool
    private var _gridSizePoints : Int = (MosaicCreationConstants.gridSizeMax + MosaicCreationConstants.gridSizeMin)/2
    private var _quality : Int = (MosaicCreationConstants.qualityMax + MosaicCreationConstants.qualityMin)/2
    private let compositeContext: CGContext
    
    private var totalGridSpaces : Int
    private var gridSpacesFilled : Int
    
    var compositeImage : UIImage {
        get {
            let cgImage = self.compositeContext.makeImage()!
            return UIImage.init(cgImage: cgImage)
        }
    }
    
    init(reference: UIImage) {
        self.inProgress = false
        self.reference = reference
        self.imageSelector = MetalImageSelection(refImage: reference)
            //NaiveImageSelection(refImage: reference)
        
        self.totalGridSpaces = 0
        self.gridSpacesFilled = 0
        
        UIGraphicsBeginImageContextWithOptions(self.reference.size, false, 0)
        self.compositeContext = UIGraphicsGetCurrentContext()!
//        self.compositeContext.translateBy(x: 0, y: self.reference.size.height)
//        self.compositeContext.scaleBy(x: 1, y: -1.0)
        UIGraphicsPopContext()
        
        
    }
    
    func getGridSizePoints() -> Int {
        return self._gridSizePoints
    }
    func setGridSizePoints(gridSizePoints : Int) throws {
        guard (gridSizePoints >= MosaicCreationConstants.gridSizeMin &&
                gridSizePoints <= MosaicCreationConstants.gridSizeMax) else {
                    throw MosaicCreationError.GridSizeOutOfBounds
            }
            self._gridSizePoints = gridSizePoints
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
    
    func begin(tick : @escaping () -> Void, complete : @escaping () -> Void) throws -> Void {
        print("Beginning Mosaic generation")
        if (self.inProgress) {
            throw MosaicCreationError.MosaicCreationInProgress
        } else {
            self.inProgress = true
            self.totalGridSpaces = (Int(self.reference.size.width) / self._gridSizePoints) * (Int(self.reference.size.height) / self._gridSizePoints)
            self.gridSpacesFilled = 0
//            DispatchQueue.global(qos: .background).async {
                do {
                    try self.imageSelector.select(gridSizePoints: self._gridSizePoints, quality: self._quality, onSelect: {(choice: ImageChoice) in
                        self.gridSpacesFilled += 1
                        UIGraphicsPushContext(self.compositeContext)
                            
                        let drawRect = CGRect(x: choice.position.col * Int(self._gridSizePoints) + Int(choice.region.minX),
                                                  y: choice.position.row * Int(self._gridSizePoints) + Int(choice.region.minY),
                                                  width: Int(choice.region.width), height: Int(choice.region.height))
//                        print("drawing to \(drawRect)")
                        choice.image.draw(in: drawRect)
//
//                        self.compositeContext.draw(choice.image.cgImage!, in:drawRect)
                        UIGraphicsPopContext()
                        if (self.gridSpacesFilled == self.totalGridSpaces) {
//                            DispatchQueue.main.async {
                                self.inProgress = false
                                complete()
//                            }
                        } else {
                            tick()
                        }
                    })
                } catch {
                    print("Error selecting image: \(error)")
                }
//            }

        }
    }
    
    func progress() -> Int {
        if (!self.inProgress) {return 0}
        return Int(100.0 * (Float(self.gridSpacesFilled) / Float(self.totalGridSpaces)))
    }
}
