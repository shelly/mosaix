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
    static let gridSizeMax = 100
    
    static let qualityMin = 0
    static let qualityMax = 100
}

class MosaicCreator {
    
    private var imageSelector : ImageSelection
    private var reference : UIImage
    private var inProgress : Bool
    private var gridSizePoints : Int = (MosaicCreationConstants.gridSizeMax + MosaicCreationConstants.gridSizeMin)/2
    private var quality : Int = (MosaicCreationConstants.qualityMax + MosaicCreationConstants.qualityMin)/2
    
    init(reference: UIImage) {
        self.inProgress = false
        self.reference = reference
        self.imageSelector = NaiveImageSelection(refImage: reference)
    }
    
    func setGridSize(gridSizePoints: Int) throws {
        guard (gridSizePoints >= MosaicCreationConstants.gridSizeMin &&
               gridSizePoints <= MosaicCreationConstants.gridSizeMax) else {
            throw MosaicCreationError.GridSizeOutOfBounds
        }
        self.gridSizePoints = gridSizePoints
    }
    
    func setQuality(quality: Int) throws {
        guard (quality >= MosaicCreationConstants.qualityMin &&
               quality <= MosaicCreationConstants.qualityMax) else {
            throw MosaicCreationError.QualityOutOfBounds
        }
        self.quality = quality
    }
    
    func begin() throws -> Void {
        if (self.inProgress) {
            throw MosaicCreationError.MosaicCreationInProgress
        } else {
            self.inProgress = true
            try self.imageSelector.select(gridSizePoints: gridSizePoints, onSelect: {(choice: ImageChoice) in
                return
            })
        }
    }
}
