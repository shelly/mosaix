//
//  MosaicCreator.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/14/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit


// Represents a region of a UIImage
class Region {
    var topLeft : CGPoint
    var bottomRight : CGPoint
    
    init(topLeft : CGPoint, bottomRight : CGPoint) {
        self.topLeft = topLeft
        self.bottomRight = bottomRight
    }
    
    var height : Int {
        get {
            return Int(self.bottomRight.y - self.topLeft.y)
        }
    }
    
    var width : Int {
        get {
            return Int(self.bottomRight.x - self.topLeft.x)
        }
    }
}

typealias region = (topLeft: CGPoint, bottomRight: CGPoint)

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
    
    private var imageSelector : ImageSelection
    private var reference : UIImage
    private var inProgress : Bool
    private var _gridSizePoints : Int = (MosaicCreationConstants.gridSizeMax + MosaicCreationConstants.gridSizeMin)/2
    private var _quality : Int = (MosaicCreationConstants.qualityMax + MosaicCreationConstants.qualityMin)/2
    
    init(reference: UIImage) {
        self.inProgress = false
        self.reference = reference
        self.imageSelector = NaiveImageSelection(refImage: reference)
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
    
    func begin() throws -> Void {
        if (self.inProgress) {
            throw MosaicCreationError.MosaicCreationInProgress
        } else {
            self.inProgress = true
            try self.imageSelector.select(gridSizePoints: self._gridSizePoints, onSelect: {(choice: ImageChoice) in
                return
            })
        }
    }
}
