//
//  ImageSelection.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit

struct ImageChoice {
    var position    : (row: Int, col: Int)
    var image       : UIImage
    var region      : CGRect
    var fit         : Float // Represents how good the fit is. Zero is best.
}

enum ImageSelectionError: Error {
    case PreprocessingIncomplete
    case LibraryAccessDenied
    case LibraryAccessNotDetermined
}

protocol ImageSelection {
    init(refImage : UIImage, timer: MosaicCreationTimer)
    var tpa: TenPointAveraging { get }
    var numThreads : Int { get set }
    func updateRef(new: UIImage) -> Void 
    func preprocess(then complete: @escaping () -> Void) throws -> Void
    func select(gridSizePoints : Int, numGridSpaces: Int, numRows: Int, numCols: Int, quality: Int, onSelect : @escaping ([String]) -> Void) throws -> Void
}
